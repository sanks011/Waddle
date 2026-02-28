class DietEntry {
  final DateTime date;
  final double protein; // in grams
  final double calories; // in kcal

  DietEntry({
    required this.date,
    required this.protein,
    required this.calories,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'protein': protein,
      'calories': calories,
    };
  }

  // Create from JSON
  factory DietEntry.fromJson(Map<String, dynamic> json) {
    return DietEntry(
      date: DateTime.parse(json['date']),
      protein: (json['protein'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
    );
  }

  String get dateFormatted {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
