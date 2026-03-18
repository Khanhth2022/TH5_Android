class Habit {
  Habit({
    required this.id,
    required this.name,
    this.description,
    this.iconCodePoint,
    this.iconFontFamily,
    this.targetCountPerDay = 1,
    required this.activeWeekdays,
    this.reminderMinutesFromMidnight,
    this.createdAt,
    Map<String, List<int>>? progressByDate,
  }) : progressByDate = progressByDate ?? <String, List<int>>{};

  final String id;
  final String name;
  final String? description;
  final int? iconCodePoint;
  final String? iconFontFamily;
  final int targetCountPerDay;

  // Monday = 1 ... Sunday = 7
  final Set<int> activeWeekdays;

  // Number of minutes from 00:00 local time.
  final int? reminderMinutesFromMidnight;
  final DateTime? createdAt;

  // dateKey -> completed sub-task indexes in a day.
  final Map<String, List<int>> progressByDate;

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    int? iconCodePoint,
    String? iconFontFamily,
    int? targetCountPerDay,
    Set<int>? activeWeekdays,
    int? reminderMinutesFromMidnight,
    DateTime? createdAt,
    Map<String, List<int>>? progressByDate,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      targetCountPerDay: targetCountPerDay ?? this.targetCountPerDay,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      reminderMinutesFromMidnight:
          reminderMinutesFromMidnight ?? this.reminderMinutesFromMidnight,
      createdAt: createdAt ?? this.createdAt,
      progressByDate:
          progressByDate ?? Map<String, List<int>>.from(this.progressByDate),
    );
  }

  bool isScheduledOn(DateTime date) {
    if (activeWeekdays.isEmpty) {
      return true;
    }
    return activeWeekdays.contains(date.weekday);
  }

  bool isCompletedOn(DateTime date) {
    final key = dateKey(date);
    final completedSteps = progressByDate[key]?.toSet() ?? <int>{};
    return completedSteps.length >= targetCountPerDay;
  }

  int completedCountOn(DateTime date) {
    final key = dateKey(date);
    return (progressByDate[key]?.toSet() ?? <int>{}).length;
  }

  Habit toggleMainCompletion(DateTime date) {
    final key = dateKey(date);
    final cloned = Map<String, List<int>>.from(progressByDate);

    if (targetCountPerDay == 1) {
      if (isCompletedOn(date)) {
        cloned.remove(key);
      } else {
        cloned[key] = <int>[0];
      }
      return copyWith(progressByDate: cloned);
    }

    // With multiple repetitions, tapping the main checkbox expands details in UI;
    // if already fully completed we allow unchecking all in one action.
    if (isCompletedOn(date)) {
      cloned.remove(key);
      return copyWith(progressByDate: cloned);
    }
    return this;
  }

  Habit toggleSubStep(DateTime date, int stepIndex) {
    final key = dateKey(date);
    final current = (progressByDate[key]?.toSet() ?? <int>{});

    if (current.contains(stepIndex)) {
      current.remove(stepIndex);
    } else {
      current.add(stepIndex);
    }

    final normalized =
        current
            .where((index) => index >= 0 && index < targetCountPerDay)
            .toList()
          ..sort();

    final cloned = Map<String, List<int>>.from(progressByDate);
    if (normalized.isEmpty) {
      cloned.remove(key);
    } else {
      cloned[key] = normalized;
    }

    return copyWith(progressByDate: cloned);
  }

  int currentStreak({DateTime? now}) {
    final today = (now ?? DateTime.now());
    final normalizedToday = DateTime(today.year, today.month, today.day);

    var cursor = normalizedToday;
    while (!isScheduledOn(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    if (!isCompletedOn(cursor)) {
      return 0;
    }

    var streak = 1;
    cursor = cursor.subtract(const Duration(days: 1));

    while (true) {
      if (!isScheduledOn(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }

      if (isCompletedOn(cursor)) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int longestStreak() {
    if (progressByDate.isEmpty) {
      return 0;
    }

    final completedDates = <DateTime>[];
    for (final entry in progressByDate.entries) {
      if (entry.value.toSet().length >= targetCountPerDay) {
        completedDates.add(parseDateKey(entry.key));
      }
    }

    if (completedDates.isEmpty) {
      return 0;
    }

    completedDates.sort();
    var best = 1;
    var running = 1;
    for (var i = 1; i < completedDates.length; i++) {
      final diff = completedDates[i].difference(completedDates[i - 1]).inDays;
      if (diff == 1) {
        running += 1;
      } else if (diff > 1) {
        running = 1;
      }
      if (running > best) {
        best = running;
      }
    }
    return best;
  }

  int totalCompletedDays() {
    return progressByDate.values
        .where((steps) => steps.toSet().length >= targetCountPerDay)
        .length;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'targetCountPerDay': targetCountPerDay,
      'activeWeekdays': activeWeekdays.toList()..sort(),
      'reminderMinutesFromMidnight': reminderMinutesFromMidnight,
      'createdAt': createdAt?.toIso8601String(),
      'progressByDate': progressByDate,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawProgress =
        (json['progressByDate'] as Map<String, dynamic>? ??
        <String, dynamic>{});
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconCodePoint: json['iconCodePoint'] as int?,
      iconFontFamily: json['iconFontFamily'] as String?,
      targetCountPerDay: (json['targetCountPerDay'] as int?) ?? 1,
      activeWeekdays:
          ((json['activeWeekdays'] as List<dynamic>? ?? <dynamic>[])
                  .cast<int>())
              .toSet(),
      reminderMinutesFromMidnight: json['reminderMinutesFromMidnight'] as int?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      progressByDate: rawProgress.map(
        (key, value) => MapEntry(key, (value as List<dynamic>).cast<int>()),
      ),
    );
  }

  static String dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DateTime parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  bool get isAutoGeneratedPlaceholder {
    final idMatch = RegExp(r'^habit_\d{10,}$').hasMatch(id);
    final nameMatch = RegExp(r'^Habit\s+\d{10,}$').hasMatch(name);
    return idMatch && nameMatch;
  }
}
