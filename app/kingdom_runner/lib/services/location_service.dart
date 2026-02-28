import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'sensor_service.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _currentPath = [];
  final SensorService _sensorService = SensorService();
  bool _useSensorFusion = false;

  // Position validation
  LatLng? _lastValidPosition;
  DateTime? _lastPositionTime;
  static const double _maxSpeedMps =
      15.0; // 54 km/h - max humanly possible running
  static const double _maxJumpMeters = 100.0; // Reject jumps > 100m
  bool _isCalibrated = false;

  // GPS calibration (allow jumps for first few updates)
  int _gpsPositionCount = 0;
  static const int _gpsCalibrationUpdates =
      10; // Allow 10 GPS updates to stabilize
  bool _journeyStarted = false; // Track if user has actually started moving

  List<LatLng> get currentPath => List.unmodifiable(_currentPath);
  SensorService get sensorService => _sensorService;

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Check sensor permissions
    final sensorPermission = await _sensorService.checkAndRequestPermissions();
    if (sensorPermission) {
      _useSensorFusion = true;
      print('✅ Sensor fusion enabled - movement detection active');
    } else {
      print('⚠️ Sensor fusion disabled - GPS only mode');
    }

    return true;
  }

  Future<LatLng?> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  void startTracking(Function(LatLng) onLocationUpdate) {
    // Start sensors for movement detection only
    if (_useSensorFusion) {
      _sensorService.startSensors();
      print('⏳ Calibrating sensors - please stand still...');
    }

    _gpsPositionCount = 0;
    _journeyStarted = false;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // Update every 3 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          final location = LatLng(position.latitude, position.longitude);

          // Wait for sensor calibration before accepting positions
          if (_useSensorFusion && !_sensorService.isCalibrated) {
            print('⏳ Still calibrating sensors...');
            return;
          }

          // Set calibration complete and initial position
          if (!_isCalibrated) {
            _isCalibrated = true;
            _lastValidPosition = location;
            _lastPositionTime = DateTime.now();
            _currentPath.add(location);
            onLocationUpdate(location);
            print('✅ Sensor calibration complete - GPS calibrating...');
            return;
          }

          _gpsPositionCount++;
          final isGpsCalibrating = _gpsPositionCount <= _gpsCalibrationUpdates;

          // During GPS calibration, allow jumps for precise positioning
          if (isGpsCalibrating) {
            // Only reject extremely bad GPS (accuracy > 100m)
            if (position.accuracy > 100) {
              print(
                '⚠️ Very poor GPS accuracy: ${position.accuracy.toStringAsFixed(1)}m',
              );
              return;
            }

            _lastValidPosition = location;
            _lastPositionTime = DateTime.now();
            _currentPath.add(location);
            onLocationUpdate(location);
            print(
              '🎯 GPS calibrating... (${_gpsPositionCount}/$_gpsCalibrationUpdates)',
            );

            if (_gpsPositionCount == _gpsCalibrationUpdates) {
              print('✅ GPS calibration complete - ready to track');
            }
            return;
          }

          // Detect if journey has started (user is moving)
          if (!_journeyStarted && _useSensorFusion && _sensorService.isMoving) {
            _journeyStarted = true;
            print('🚀 Journey started - strict validation enabled');
          }

          // Validate GPS position against glitches (only after GPS calibration)
          if (!_isValidPosition(
            position,
            location,
            strictMode: _journeyStarted,
          )) {
            print('❌ Invalid GPS position rejected');
            return;
          }

          // Only accept position updates if sensors detect movement OR GPS shows significant distance
          final distance = _calculateDistance(_lastValidPosition!, location);
          final isMovingBySensor = _useSensorFusion
              ? _sensorService.isMoving
              : true;

          if (isMovingBySensor || distance > 10) {
            _lastValidPosition = location;
            _lastPositionTime = DateTime.now();
            _currentPath.add(location);
            onLocationUpdate(location);
          } else {
            print('🛑 Position ignored - no movement detected');
          }
        });
  }

  bool _isValidPosition(
    Position position,
    LatLng location, {
    bool strictMode = false,
  }) {
    if (_lastValidPosition == null || _lastPositionTime == null) return true;

    // Calculate distance from last position
    final distance = _calculateDistance(_lastValidPosition!, location);

    // In strict mode (after journey started), apply all validations
    if (strictMode) {
      // Reject impossible jumps
      if (distance > _maxJumpMeters) {
        print('⚠️ Rejected ${distance.toStringAsFixed(1)}m jump');
        return false;
      }

      // Calculate time elapsed
      final timeDiff =
          DateTime.now().difference(_lastPositionTime!).inMilliseconds / 1000.0;
      if (timeDiff <= 0) return false;

      // Calculate speed
      final speed = distance / timeDiff; // m/s

      // Reject if speed is humanly impossible
      if (speed > _maxSpeedMps) {
        print(
          '⚠️ Rejected impossible speed: ${speed.toStringAsFixed(1)} m/s (${(speed * 3.6).toStringAsFixed(1)} km/h)',
        );
        return false;
      }

      // Check GPS accuracy
      if (position.accuracy > 50) {
        print('⚠️ Poor GPS accuracy: ${position.accuracy.toStringAsFixed(1)}m');
        return false;
      }
    } else {
      // Before journey starts, only reject extreme cases
      if (distance > 500) {
        print('⚠️ Rejected extreme ${distance.toStringAsFixed(1)}m jump');
        return false;
      }

      if (position.accuracy > 100) {
        print(
          '⚠️ Very poor GPS accuracy: ${position.accuracy.toStringAsFixed(1)}m',
        );
        return false;
      }
    }

    return true;
  }

  double _calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _sensorService.stopSensors();
    _isCalibrated = false;
    _lastValidPosition = null;
    _lastPositionTime = null;
    _gpsPositionCount = 0;
    _journeyStarted = false;
  }

  void clearPath() {
    _currentPath.clear();
  }

  void dispose() {
    stopTracking();
    _sensorService.dispose();
  }

  double calculateDistance(List<LatLng> path) {
    if (path.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < path.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        path[i].latitude,
        path[i].longitude,
        path[i + 1].latitude,
        path[i + 1].longitude,
      );
    }
    return totalDistance; // in meters
  }

  bool isClosedLoop(List<LatLng> path, {double thresholdMeters = 50}) {
    if (path.length < 3) return false;

    final start = path.first;
    final end = path.last;

    final distance = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    return distance <= thresholdMeters;
  }

  // Calculate area of polygon using Shoelace formula
  double calculatePolygonArea(List<LatLng> polygon) {
    if (polygon.length < 3) return 0.0;

    double area = 0.0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;
      area += polygon[i].longitude * polygon[j].latitude;
      area -= polygon[j].longitude * polygon[i].latitude;
    }

    area = (area.abs() / 2.0);

    // Convert to square meters (approximate)
    // 1 degree latitude ≈ 111,320 meters
    // 1 degree longitude varies by latitude
    double avgLat =
        polygon.map((p) => p.latitude).reduce((a, b) => a + b) / polygon.length;
    double metersPerDegreeLat = 111320;
    double metersPerDegreeLon = 111320 * (3.14159 / 180) * avgLat.abs();

    return area * metersPerDegreeLat * metersPerDegreeLon;
  }

  // Check if a point is inside a polygon
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length; i++) {
      int j = (i + 1) % polygon.length;

      if ((polygon[i].latitude <= point.latitude &&
              point.latitude < polygon[j].latitude) ||
          (polygon[j].latitude <= point.latitude &&
              point.latitude < polygon[i].latitude)) {
        double xIntersection =
            (point.latitude - polygon[i].latitude) *
                (polygon[j].longitude - polygon[i].longitude) /
                (polygon[j].latitude - polygon[i].latitude) +
            polygon[i].longitude;

        if (point.longitude < xIntersection) {
          intersectCount++;
        }
      }
    }
    return (intersectCount % 2) == 1;
  }
}
