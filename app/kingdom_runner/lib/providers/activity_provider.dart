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

  ActivitySession? get currentSession => _currentSession;
  bool get isTracking => _isTracking;
  List<LatLng> get currentPath => List.unmodifiable(_currentPath);
  double get currentDistance => _currentDistance;

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

    final isLoop = _locationService.isClosedLoop(_currentPath);

    _currentSession = ActivitySession(
      id: _currentSession!.id,
      userId: _currentSession!.userId,
      path: _currentPath,
      distance: _currentDistance,
      startTime: _currentSession!.startTime,
      endTime: DateTime.now(),
      isCompleted: true,
      formsClosedLoop: isLoop,
    );

    try {
      // Complete the session first
      var completedSession = await _apiService.completeSession(
        _currentSession!.id,
        _currentSession!,
      );

      // If path has enough points, try to create territory
      if (_currentPath.length >= 3) {
        try {
          print(
            'Attempting to create territory with ${_currentPath.length} points',
          );
          final territory = await _apiService.createTerritory(_currentSession!);
          print('✅ Territory created successfully: ${territory.id}');

          // Create new session instance with territoryId
          completedSession = ActivitySession(
            id: completedSession.id,
            userId: completedSession.userId,
            path: completedSession.path,
            distance: completedSession.distance,
            startTime: completedSession.startTime,
            endTime: completedSession.endTime,
            isCompleted: completedSession.isCompleted,
            formsClosedLoop: completedSession.formsClosedLoop,
            territoryId: territory.id,
          );
        } catch (e) {
          print('⚠️ Territory creation failed: $e');
          // Don't fail the session if territory creation fails
        }
      }

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

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
