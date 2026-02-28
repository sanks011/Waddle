import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/activity_session.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import 'package:uuid/uuid.dart';

class ActivityProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  ActivitySession? _currentSession;
  bool _isTracking = false;
  List<LatLng> _currentPath = [];
  double _currentDistance = 0.0;
  List<ActivitySession> _userSessions = [];

  ActivitySession? get currentSession => _currentSession;
  bool get isTracking => _isTracking;
  List<LatLng> get currentPath => List.unmodifiable(_currentPath);
  double get currentDistance => _currentDistance;
  List<ActivitySession> get userSessions => List.unmodifiable(_userSessions);

  Future<bool> startSession(String userId) async {
    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      return false;
    }

    _currentPath.clear();
    _currentDistance = 0.0;

    _currentSession = ActivitySession(
      id: const Uuid().v4(),
      userId: userId,
      path: [],
      distance: 0.0,
      startTime: DateTime.now(),
      isCompleted: false,
      formsClosedLoop: false,
    );

    // Create session in backend database
    try {
      print('📝 Creating session in backend: ${_currentSession!.id}');
      await _apiService.createSession(_currentSession!);
      print('✅ Session created in backend');
    } catch (e) {
      print('⚠️ Failed to create session in backend: $e');
      // Continue anyway - session will be created when completed
    }

    _isTracking = true;

    _locationService.startTracking((location) {
      _currentPath.add(location);
      _currentDistance = _locationService.calculateDistance(_currentPath);
      notifyListeners();
    });

    notifyListeners();
    return true;
  }

  Future<ActivitySession?> stopSession() async {
    if (_currentSession == null) return null;

    _locationService.stopTracking();
    _isTracking = false;

    // IMPORTANT: Create a copy of the path to prevent it from being cleared
    final pathCopy = List<LatLng>.from(_currentPath);
    print('📍 PATH DEBUG: Stopping session with ${pathCopy.length} points');
    if (pathCopy.isNotEmpty) {
      print(
        '📍 First point: (${pathCopy.first.latitude}, ${pathCopy.first.longitude})',
      );
      print(
        '📍 Last point: (${pathCopy.last.latitude}, ${pathCopy.last.longitude})',
      );
    }

    final isLoop = _locationService.isClosedLoop(pathCopy);

    _currentSession = ActivitySession(
      id: _currentSession!.id,
      userId: _currentSession!.userId,
      path: pathCopy, // Use the copy
      distance: _currentDistance,
      startTime: _currentSession!.startTime,
      endTime: DateTime.now(),
      isCompleted: true,
      formsClosedLoop: isLoop,
    );

    print(
      '📦 Session path length after creation: ${_currentSession!.path.length}',
    );

    try {
      // Complete the session first
      var completedSession = await _apiService.completeSession(
        _currentSession!.id,
        _currentSession!,
      );

      // If path has at least 1 point, try to create territory
      String? territoryId;
      print(
        '🔍 Checking if should create territory: pathCopy.isNotEmpty = ${pathCopy.isNotEmpty}, length = ${pathCopy.length}',
      );

      if (pathCopy.isNotEmpty) {
        print('✅ Starting territory creation process...');
        try {
          // Test connection first
          final isConnected = await _apiService.testConnection();
          print(
            '🔌 Backend connectivity: ${isConnected ? "Connected" : "Not connected"}',
          );

          if (!isConnected) {
            print(
              '⚠️ Cannot reach backend server. Territory creation will fail.',
            );
          }

          print(
            'Attempting to create territory with ${pathCopy.length} points',
          );
          final territory = await _apiService.createTerritory(_currentSession!);
          print('✅ Territory created successfully: ${territory.id}');
          print('📊 Territory area: ${territory.area} m²');
          territoryId = territory.id;
        } catch (e, stackTrace) {
          print('⚠️ Territory creation failed: $e');
          print('📚 Stack trace: $stackTrace');
          // Don't fail the session if territory creation fails
        }
      } else {
        print('❌ Skipping territory creation: path is empty');
      }

      // Create final session instance with territoryId (if created)
      completedSession = ActivitySession(
        id: completedSession.id,
        userId: completedSession.userId,
        path: completedSession.path,
        distance: completedSession.distance,
        startTime: completedSession.startTime,
        endTime: completedSession.endTime,
        isCompleted: completedSession.isCompleted,
        formsClosedLoop: completedSession.formsClosedLoop,
        territoryId: territoryId,
      );

      notifyListeners();
      return completedSession;
    } catch (e) {
      print('❌ Error completing session: $e');
      notifyListeners();
      return _currentSession;
    }
  }

  void clearSession() {
    _currentSession = null;
    _currentPath.clear();
    _currentDistance = 0.0;
    _locationService.clearPath();
    notifyListeners();
  }

  // Fetch user's activity sessions
  Future<void> loadUserSessions() async {
    try {
      _userSessions = await _apiService.getUserSessions();
      notifyListeners();
      print('📊 Loaded ${_userSessions.length} user sessions');
    } catch (e) {
      print('❌ Failed to load user sessions: $e');
    }
  }

  // Get estimated calories burned per day this week (Mon–Sun)
  // Formula: estimate steps from distance (avg stride 0.762 m), then 0.04 kcal/step
  List<double> getWeeklyCaloriesBurned() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final weeklyCalories = List<double>.filled(7, 0.0);

    for (final session in _userSessions) {
      if (session.endTime == null || !session.isCompleted) continue;

      final sessionDate = DateTime(
        session.endTime!.year,
        session.endTime!.month,
        session.endTime!.day,
      );

      if (sessionDate.isAfter(monday.subtract(const Duration(days: 1))) &&
          sessionDate.isBefore(monday.add(const Duration(days: 7)))) {
        final dayIndex = sessionDate.difference(monday).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          // Estimate steps from distance (avg stride ~0.762 m), then 0.04 kcal per step
          final estimatedSteps = session.distance / 0.762;
          final kcal = estimatedSteps * 0.04;
          weeklyCalories[dayIndex] += kcal;
        }
      }
    }

    return weeklyCalories;
  }

  // Get average exercise minutes per weekday across all historical sessions
  // Returns a 7-element list [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  List<double> getAverageExerciseMinutesPerWeekday() {
    final totals = List<double>.filled(7, 0.0);
    final counts = List<int>.filled(7, 0);

    for (final session in _userSessions) {
      if (session.endTime == null || !session.isCompleted) continue;
      final dayIndex = session.startTime.weekday - 1; // 0=Mon, 6=Sun
      final minutes = session.endTime!.difference(session.startTime).inMinutes.toDouble();
      totals[dayIndex] += minutes;
      counts[dayIndex]++;
    }

    return List.generate(7, (i) => counts[i] > 0 ? totals[i] / counts[i] : 0.0);
  }

  // Get weekly exercise minutes (last 7 days, Mon-Sun)
  List<double> getWeeklyExerciseMinutes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Find the Monday of this week
    final currentWeekday = today.weekday; // 1 = Monday, 7 = Sunday
    final monday = today.subtract(Duration(days: currentWeekday - 1));
    
    // Initialize 7 days with 0 minutes
    final weeklyMinutes = List<double>.filled(7, 0.0);
    
    // Calculate minutes for each completed session in the current week
    for (final session in _userSessions) {
      if (session.endTime == null || !session.isCompleted) continue;
      
      final sessionDate = DateTime(
        session.endTime!.year,
        session.endTime!.month,
        session.endTime!.day,
      );
      
      // Check if session is in current week
      if (sessionDate.isAfter(monday.subtract(const Duration(days: 1))) &&
          sessionDate.isBefore(monday.add(const Duration(days: 7)))) {
        final dayIndex = sessionDate.difference(monday).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          final durationMinutes = session.endTime!.difference(session.startTime).inMinutes.toDouble();
          weeklyMinutes[dayIndex] += durationMinutes;
        }
      }
    }
    
    return weeklyMinutes;
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
