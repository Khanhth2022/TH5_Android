import 'package:flutter/foundation.dart';
import 'package:habit_tracker/models/badge_model.dart';
import 'package:habit_tracker/models/habit_model.dart';

class GamificationProvider extends ChangeNotifier {
  final List<BadgeModel> _badges = List<BadgeModel>.of(
    BadgeModel.defaultBadges(),
  );

  BadgeModel? _latestUnlockedBadge;
  String? _latestUnlockedHabitName;

  List<BadgeModel> get badges => List<BadgeModel>.unmodifiable(_badges);
  BadgeModel? get latestUnlockedBadge => _latestUnlockedBadge;
  String? get latestUnlockedHabitName => _latestUnlockedHabitName;

  void evaluateFromHabits(List<Habit> habits, {DateTime? now}) {
    if (habits.isEmpty) {
      return;
    }

    final referenceDate = now ?? DateTime.now();
    var hasChanges = false;

    for (var i = 0; i < _badges.length; i++) {
      final badge = _badges[i];
      if (badge.isUnlocked) {
        continue;
      }

      Habit? unlockedBy;
      var bestLongestStreak = 0;

      for (final habit in habits) {
        final longestStreak = habit.longestStreak();
        if (longestStreak >= badge.milestoneDays &&
            longestStreak >= bestLongestStreak) {
          bestLongestStreak = longestStreak;
          unlockedBy = habit;
        }
      }

      if (unlockedBy == null) {
        continue;
      }

      final unlockedBadge = badge.copyWith(
        unlockedAt: referenceDate,
        unlockedByHabitId: unlockedBy.id,
        unlockedByHabitName: unlockedBy.name,
      );

      _badges[i] = unlockedBadge;
      _latestUnlockedBadge = unlockedBadge;
      _latestUnlockedHabitName = unlockedBy.name;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  void consumeLatestAchievement() {
    _latestUnlockedBadge = null;
    _latestUnlockedHabitName = null;
    notifyListeners();
  }
}
