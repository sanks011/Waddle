import 'package:latlong2/latlong.dart';

class Territory {
  final String id;
  final String userId;
  final String username;
  final List<LatLng> polygon;
  final double area; // in square meters
  final DateTime createdAt;
  final DateTime lastUpdated;
  final bool isActive;

  Territory({
    required this.id,
    required this.userId,
    required this.username,
    required this.polygon,
    required this.area,
    required this.createdAt,
    required this.lastUpdated,
    required this.isActive,
  });

  factory Territory.fromJson(Map<String, dynamic> json) {
    List<LatLng> polygonPoints = [];
    if (json['polygon'] != null) {
      polygonPoints = (json['polygon'] as List)
          .map(
            (point) => LatLng(
              point['lat'] ?? point['latitude'] ?? 0.0,
              point['lng'] ?? point['longitude'] ?? 0.0,
            ),
          )
          .toList();
    }

    return Territory(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      polygon: polygonPoints,
      area: (json['area'] ?? 0).toDouble(),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'polygon': polygon
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'area': area,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'isActive': isActive,
    };
  }
}
