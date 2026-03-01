import 'package:latlong2/latlong.dart';

class ActivitySession {
  final String id;
  final String userId;
  final List<LatLng> path;
  final double distance;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final bool formsClosedLoop;
  final String? territoryId;

  ActivitySession({
    required this.id,
    required this.userId,
    required this.path,
    required this.distance,
    required this.startTime,
    this.endTime,
    required this.isCompleted,
    required this.formsClosedLoop,
    this.territoryId,
  });

  factory ActivitySession.fromJson(Map<String, dynamic> json) {
    List<LatLng> pathPoints = [];
    if (json['path'] != null) {
      pathPoints = (json['path'] as List)
          .map(
            (point) => LatLng(
              point['lat'] ?? point['latitude'] ?? 0.0,
              point['lng'] ?? point['longitude'] ?? 0.0,
            ),
          )
          .toList();
    }

    return ActivitySession(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      path: pathPoints,
      distance: (json['distance'] ?? 0).toDouble(),
      startTime: DateTime.parse(
        json['startTime'] ?? DateTime.now().toIso8601String(),
      ),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isCompleted: json['isCompleted'] ?? false,
      formsClosedLoop: json['formsClosedLoop'] ?? false,
      territoryId: json['territoryId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'path': path
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'distance': distance,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'formsClosedLoop': formsClosedLoop,
      'territoryId': territoryId,
    };
  }
}
