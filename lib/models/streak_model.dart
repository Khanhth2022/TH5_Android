class StreakModel {
  const StreakModel({
    required this.habitId,
    required this.habitName,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalPoints,
    this.lastCompletedDate,
  });

  final String habitId;
  final String habitName;
  final int currentStreak;
  final int longestStreak;
  final int totalPoints;
  final DateTime? lastCompletedDate;

  bool get isHighPerformer =>
      currentStreak > 0 && currentStreak == longestStreak;

  StreakModel copyWith({
    String? habitId,
    String? habitName,
    int? currentStreak,
    int? longestStreak,
    int? totalPoints,
    DateTime? lastCompletedDate,
    bool clearLastCompletedDate = false,
  }) {
    return StreakModel(
      habitId: habitId ?? this.habitId,
      habitName: habitName ?? this.habitName,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalPoints: totalPoints ?? this.totalPoints,
      lastCompletedDate: clearLastCompletedDate
          ? null
          : (lastCompletedDate ?? this.lastCompletedDate),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'habitId': habitId,
      'habitName': habitName,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalPoints': totalPoints,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    };
  }

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      habitId: json['habitId'] as String,
      habitName: json['habitName'] as String,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      totalPoints: json['totalPoints'] as int,
      lastCompletedDate: json['lastCompletedDate'] == null
          ? null
          : DateTime.parse(json['lastCompletedDate'] as String),
    );
  }
}
