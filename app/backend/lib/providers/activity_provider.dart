import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/activity_session.dart';
import '../models/territory.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import 'package:uuid/uuid.dart';

/// State of vehicle-speed detection during an active session.
enum VehicleWarningState {
  none, // No issue detected
  warning, // High speed detected — countdown running before auto-terminate
  terminated, // Session was force-stopped because user ignored the warning
}

class ActivityProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  ActivitySession? _currentSession;
  bool _isTracking = false;
  List<LatLng> _currentPath = [];
  double _currentDistance = 0.0;
  List<ActivitySession> _userSessions = [];

  // ── Vehicle detection ────────────────────────────────────────────────
  VehicleWarningState _vehicleWarningState = VehicleWarningState.none;
  int _warningSecondsRemaining = 15;
  Timer? _warningCountdownTimer;
  double _detectedVehicleSpeedMps = 0.0;
  static const int _warningDurationSeconds = 15;
  // ────────────────────────────────────────────────────────────────

  // ── Topaz coins earned in last territory creation ────────────────────────
  int _lastTopazEarned = 0;
  int _lastTotalTopaz = 0;
  // ────────────────────────────────────────────────────────────────

  ActivitySession? get currentSession => _currentSession;
  bool get isTracking => _isTracking;
  List<LatLng> get currentPath => List.unmodifiable(_currentPath);
  double get currentDistance => _currentDistance;
  List<ActivitySession> get userSessions => List.unmodifiable(_userSessions);

  // Vehicle-detection getters
  VehicleWarningState get vehicleWarningState => _vehicleWarningState;
  int get warningSecondsRemaining => _warningSecondsRemaining;
  double get detectedVehicleSpeedMps => _detectedVehicleSpeedMps;
  double get detectedVehicleSpeedKmh => _detectedVehicleSpeedMps * 3.6;

  // Topaz getters
  int get lastTopazEarned => _lastTopazEarned;
  int get lastTotalTopaz => _lastTotalTopaz;

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

    // ── Wire up vehicle-detection callbacks ───────────────────────────────────
    _locationService.onVehicleSpeedDetected = (speedMps) {
      if (_vehicleWarningState == VehicleWarningState.none) {
        _detectedVehicleSpeedMps = speedMps;
        _vehicleWarningState = VehicleWarningState.warning;
        _warningSecondsRemaining = _warningDurationSeconds;
        _startWarningCountdown();
        notifyListeners();
        print(
          '🚗 Vehicle speed detected: ${(speedMps * 3.6).toStringAsFixed(1)} km/h — warning shown',
        );
      }
    };
    _locationService.onVehicleSpeedNormal = () {
      if (_vehicleWarningState == VehicleWarningState.warning) {
        _cancelWarning();
        notifyListeners();
        print('✅ Speed back to normal — warning dismissed automatically');
      }
    };
    // ────────────────────────────────────────────────────────────────

    notifyListeners();
    return true;
  }

  Future<ActivitySession?> stopSession() async {
    if (_currentSession == null) return null;

    _cancelWarning();
    _vehicleWarningState = VehicleWarningState.none;
    _locationService.onVehicleSpeedDetected = null;
    _locationService.onVehicleSpeedNormal = null;

    _locationService.stopTracking();
    _isTracking = false;

    // IMPORTANT: Create a copy of the path to prevent it from being cleared
    final pathCopy = List<LatLng>.from(_currentPath);

    // ── Sanitize path: remove GPS outliers (calibration spikes, glitches) ──
    final sanitizedPath = _sanitizePath(pathCopy);
    final walkDistance = _calculateWalkDistance(sanitizedPath);

    print(
      '📍 PATH: Raw ${pathCopy.length} → Clean ${sanitizedPath.length} points',
    );
    print('📏 Walk distance (clean): ${walkDistance.toStringAsFixed(1)}m');
    if (sanitizedPath.isNotEmpty) {
      print(
        '📍 Start: (${sanitizedPath.first.latitude}, ${sanitizedPath.first.longitude})',
      );
      print(
        '📍 End:   (${sanitizedPath.last.latitude}, ${sanitizedPath.last.longitude})',
      );
    }

    final isLoop = _locationService.isClosedLoop(sanitizedPath);

    _currentSession = ActivitySession(
      id: _currentSession!.id,
      userId: _currentSession!.userId,
      path: sanitizedPath,
      distance: walkDistance,
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

      // Territory requires ≥3 clean GPS points AND ≥20m walked
      String? territoryId;
      print(
        '🔍 Territory check: ${sanitizedPath.length} clean pts, ${walkDistance.toStringAsFixed(0)}m walked',
      );

      if (sanitizedPath.length >= 3 && walkDistance >= 20.0) {
        print(
          '✅ Starting territory creation (${sanitizedPath.length} pts, ${walkDistance.toStringAsFixed(0)}m)...',
        );
        try {
          final isConnected = await _apiService.testConnection();
          print(
            '🔌 Backend connectivity: ${isConnected ? "Connected" : "Not connected"}',
          );

          if (!isConnected) {
            print(
              '⚠️ Cannot reach backend server. Territory creation will fail.',
            );
          }

          print('Creating territory with ${sanitizedPath.length} clean points');
          final result = await _apiService.createTerritory(_currentSession!);
          final territory = result['territory'] as Territory;
          _lastTopazEarned = result['topazEarned'] as int;
          _lastTotalTopaz = result['totalTopaz'] as int;
          print('✅ Territory created successfully: ${territory.id}');
          print('📊 Territory area: ${territory.area} m²');
          print('💎 Topaz earned: $_lastTopazEarned (total: $_lastTotalTopaz)');
          territoryId = territory.id;
        } catch (e, stackTrace) {
          print('⚠️ Territory creation failed: $e');
          print('📚 Stack trace: $stackTrace');
          // Don't fail the session if territory creation fails
        }
      } else {
        print(
          '❌ Skipping territory: need ≥3 pts & ≥20m (got ${sanitizedPath.length} pts, ${walkDistance.toStringAsFixed(0)}m)',
        );
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
    _cancelWarning();
    _vehicleWarningState = VehicleWarningState.none;
    _locationService.onVehicleSpeedDetected = null;
    _locationService.onVehicleSpeedNormal = null;
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

  // ── Vehicle warning helpers ──────────────────────────────────────────────

  /// User tapped “I’m walking” — reset the warning and resume normally.
  void dismissVehicleWarning() {
    _locationService.resetVehicleDetection();
    _cancelWarning();
    notifyListeners();
  }

  void _startWarningCountdown() {
    _warningCountdownTimer?.cancel();
    _warningCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_warningSecondsRemaining <= 1) {
        t.cancel();
        _vehicleWarningState = VehicleWarningState.terminated;
        notifyListeners();
        // Force-stop the session asynchronously
        stopSession();
        print('🛑 Session auto-terminated: user in vehicle');
      } else {
        _warningSecondsRemaining--;
        notifyListeners();
      }
    });
  }

  void _cancelWarning() {
    _warningCountdownTimer?.cancel();
    _warningCountdownTimer = null;
    _vehicleWarningState = VehicleWarningState.none;
    _warningSecondsRemaining = _warningDurationSeconds;
    _detectedVehicleSpeedMps = 0.0;
  }

  // ────────────────────────────────────────────────────────────────

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
      final minutes = session.endTime!
          .difference(session.startTime)
          .inMinutes
          .toDouble();
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
          final durationMinutes = session.endTime!
              .difference(session.startTime)
              .inMinutes
              .toDouble();
          weeklyMinutes[dayIndex] += durationMinutes;
        }
      }
    }

    return weeklyMinutes;
  }

  // ── GPS Path Sanitization ────────────────────────────────────────────────────

  static const _haversine = Distance();

  /// Removes GPS outlier points that imply impossible jumps.
  /// A point is rejected if it's >50m from the previous accepted point
  /// (walking GPS updates every ~3m, so 50m is extremely generous).
  static List<LatLng> _sanitizePath(List<LatLng> path) {
    if (path.length < 2) return List.from(path);

    final clean = <LatLng>[path.first];
    for (int i = 1; i < path.length; i++) {
      final d = _haversine.as(LengthUnit.Meter, clean.last, path[i]);
      if (d <= 50.0) {
        clean.add(path[i]);
      } else {
        print('🧹 Stripped outlier #$i: ${d.toStringAsFixed(0)}m jump');
      }
    }
    return clean;
  }

  /// Total walked distance along a path (sum of consecutive segments).
  static double _calculateWalkDistance(List<LatLng> path) {
    if (path.length < 2) return 0.0;
    double total = 0;
    for (int i = 0; i < path.length - 1; i++) {
      total += _haversine.as(LengthUnit.Meter, path[i], path[i + 1]);
    }
    return total;
  }

  @override
  void dispose() {
    _cancelWarning();
    _locationService.onVehicleSpeedDetected = null;
    _locationService.onVehicleSpeedNormal = null;
    _locationService.dispose();
    super.dispose();
  }
}
