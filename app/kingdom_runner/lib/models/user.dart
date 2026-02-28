class User {
  final String id;
  final String email;
  final String username;
  final double totalDistance;
  final double territorySize;
  final int activityStreak;
  final DateTime lastActivity;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.totalDistance,
    required this.territorySize,
    required this.activityStreak,
    required this.lastActivity,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      totalDistance: (json['totalDistance'] ?? 0).toDouble(),
      territorySize: (json['territorySize'] ?? 0).toDouble(),
      activityStreak: json['activityStreak'] ?? 0,
      lastActivity: DateTime.parse(
        json['lastActivity'] ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'totalDistance': totalDistance,
      'territorySize': territorySize,
      'activityStreak': activityStreak,
      'lastActivity': lastActivity.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
