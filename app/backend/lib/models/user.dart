class User {
  final String id;
  final String email;
  final String username;
  final double totalDistance;
  final double territorySize;
  final int activityStreak;
  final DateTime lastActivity;
  final DateTime createdAt;

  // Onboarding fields
  final DateTime? dateOfBirth;
  final double? weight; // in kg
  final double? height; // in cm
  final double? dailyProtein; // in grams
  final double? dailyCalories; // in kcal
  final String? avatarPath; // asset path e.g. assets/avatars/vibrant/1.png
  final bool onboardingCompleted;
  final int topazCoins;
  final int bombInventory;
  final int scannerDockInventory;
  final int defuseGunInventory;
  final int nukeInventory;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.totalDistance,
    required this.territorySize,
    required this.activityStreak,
    required this.lastActivity,
    required this.createdAt,
    this.dateOfBirth,
    this.weight,
    this.height,
    this.dailyProtein,
    this.dailyCalories,
    this.avatarPath,
    this.onboardingCompleted = false,
    this.topazCoins = 0,
    this.bombInventory = 0,
    this.scannerDockInventory = 0,
    this.defuseGunInventory = 0,
    this.nukeInventory = 0,
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
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : null,
      weight: json['weight'] != null ? (json['weight']).toDouble() : null,
      height: json['height'] != null ? (json['height']).toDouble() : null,
      dailyProtein: json['dailyProtein'] != null
          ? (json['dailyProtein']).toDouble()
          : null,
      dailyCalories: json['dailyCalories'] != null
          ? (json['dailyCalories']).toDouble()
          : null,
      avatarPath: json['avatarPath'] as String?,
      onboardingCompleted: json['onboardingCompleted'] ?? false,
      topazCoins: (json['topazCoins'] as num?)?.toInt() ?? 0,
      bombInventory: (json['inventory']?['bombs'] as num?)?.toInt() ?? 0,
      scannerDockInventory: (json['inventory']?['scannerDocks'] as num?)?.toInt() ?? 0,
      defuseGunInventory: (json['inventory']?['defuseGuns'] as num?)?.toInt() ?? 0,
      nukeInventory: (json['inventory']?['nukes'] as num?)?.toInt() ?? 0,
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
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (dailyProtein != null) 'dailyProtein': dailyProtein,
      if (dailyCalories != null) 'dailyCalories': dailyCalories,
      if (avatarPath != null) 'avatarPath': avatarPath,
      'onboardingCompleted': onboardingCompleted,
      'topazCoins': topazCoins,
    };
  }
}
