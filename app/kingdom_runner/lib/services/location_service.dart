import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _currentPath = [];

  List<LatLng> get currentPath => List.unmodifiable(_currentPath);

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
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Update every 5 meters for more precision
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final location = LatLng(position.latitude, position.longitude);
            _currentPath.add(location);
            onLocationUpdate(location);
          },
        );
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  void clearPath() {
    _currentPath.clear();
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

  void dispose() {
    stopTracking();
  }
}
