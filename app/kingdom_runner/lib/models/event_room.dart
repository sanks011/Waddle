import 'package:latlong2/latlong.dart';

class EventParticipant {
  final String userId;
  final String username;
  final String avatarPath;
  final DateTime joinedAt;

  const EventParticipant({
    required this.userId,
    required this.username,
    required this.avatarPath,
    required this.joinedAt,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown',
      avatarPath: json['avatarPath'] as String? ?? '',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
    );
  }
}

class EventRoom {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorUsername;
  final String creatorAvatarPath;
  final LatLng location;
  final bool isPublic;
  final List<EventParticipant> participants;
  final DateTime createdAt;
  final DateTime expiresAt;
  final double distanceMetres;

  const EventRoom({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorUsername,
    required this.creatorAvatarPath,
    required this.location,
    required this.isPublic,
    required this.participants,
    required this.createdAt,
    required this.expiresAt,
    this.distanceMetres = 0,
  });

  factory EventRoom.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    final participantsRaw = json['participants'] as List<dynamic>? ?? [];

    return EventRoom(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      creatorId: json['creatorId'] as String? ?? '',
      creatorUsername: json['creatorUsername'] as String? ?? 'Unknown',
      creatorAvatarPath: json['creatorAvatarPath'] as String? ?? '',
      location: LatLng(
        (loc['lat'] as num?)?.toDouble() ?? 0,
        (loc['lng'] as num?)?.toDouble() ?? 0,
      ),
      isPublic: json['isPublic'] as bool? ?? true,
      participants: participantsRaw
          .map((p) => EventParticipant.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
      distanceMetres: (json['distanceMetres'] as num?)?.toDouble() ?? 0,
    );
  }

  bool isParticipant(String userId) =>
      participants.any((p) => p.userId == userId);

  String get formattedDistance {
    if (distanceMetres < 1000) {
      return '${distanceMetres.round()}m away';
    }
    final km = (distanceMetres / 1000).toStringAsFixed(1);
    return '${km}km away';
  }

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  String get formattedExpiry {
    final rem = timeRemaining;
    if (rem.inHours > 0) return '${rem.inHours}h ${rem.inMinutes % 60}m left';
    if (rem.inMinutes > 0) return '${rem.inMinutes}m left';
    return 'Expiring soon';
  }
}
