import 'package:flutter/foundation.dart';
import 'package:habit_tracker/models/badge_model.dart';
import 'package:habit_tracker/models/habit_model.dart';
import 'package:habit_tracker/models/streak_model.dart';
import 'package:habit_tracker/services/firebase_service.dart';

enum HabitFilter { all, completed, pending }

class HabitProvider extends ChangeNotifier {
  HabitProvider({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  final FirebaseService _firebaseService;

  final List<Habit> _habits = <Habit>[];
  final List<BadgeModel> _badges = List<BadgeModel>.of(
    BadgeModel.defaultBadges(),
  );

  DateTime _selectedDate = DateTime.now();
  HabitFilter _filter = HabitFilter.all;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // These fields help screens show a one-time achievement popup.
  BadgeModel? _latestUnlockedBadge;
  String? _latestUnlockedHabitName;

  List<Habit> get habits => List<Habit>.unmodifiable(_habits);
  List<BadgeModel> get badges => List<BadgeModel>.unmodifiable(_badges);
  DateTime get selectedDate => _selectedDate;
  HabitFilter get filter => _filter;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BadgeModel? get latestUnlockedBadge => _latestUnlockedBadge;
  String? get latestUnlockedHabitName => _latestUnlockedHabitName;

  List<Habit> get habitsForSelectedDate {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    return _habits.where((habit) {
        if (!habit.isScheduledOn(_selectedDate)) {
          return false;
        }

        if (normalizedQuery.isNotEmpty &&
            !habit.name.toLowerCase().contains(normalizedQuery)) {
          return false;
        }

        switch (_filter) {
          case HabitFilter.all:
            return true;
          case HabitFilter.completed:
            return habit.isCompletedOn(_selectedDate);
          case HabitFilter.pending:
            return !habit.isCompletedOn(_selectedDate);
        }
      }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  List<StreakModel> get streakLeaderboard {
    final result =
        _habits.map((habit) {
          final completedDates =
              habit.progressByDate.entries
                  .where(
                    (entry) =>
                        entry.value.toSet().length >= habit.targetCountPerDay,
                  )
                  .map((entry) => Habit.parseDateKey(entry.key))
                  .toList()
                ..sort();

          final lastCompletedDate = completedDates.isEmpty
              ? null
              : completedDates.last;

          return StreakModel(
            habitId: habit.id,
            habitName: habit.name,
            currentStreak: habit.currentStreak(),
            longestStreak: habit.longestStreak(),
            totalPoints: habit.totalCompletedDays(),
            lastCompletedDate: lastCompletedDate,
          );
        }).toList()..sort((a, b) {
          final byCurrent = b.currentStreak.compareTo(a.currentStreak);
          if (byCurrent != 0) {
            return byCurrent;
          }
          return b.totalPoints.compareTo(a.totalPoints);
        });

    return result;
  }

  Future<void> loadHabits() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final remoteHabits = await _firebaseService.fetchHabits();
      _habits
        ..clear()
        ..addAll(remoteHabits);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setFilter(HabitFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    _errorMessage = null;
    final snapshot = List<Habit>.from(_habits);

    final existingIndex = _habits.indexWhere((item) => item.id == habit.id);
    if (existingIndex >= 0) {
      _habits[existingIndex] = habit;
    } else {
      _habits.add(habit);
    }
    notifyListeners();

    try {
      await _firebaseService.upsertHabit(habit);

      // Guard against races (e.g. loadHabits finishing while add is in flight)
      // so the just-added habit is always present in memory and UI.
      final indexAfterSync = _habits.indexWhere((item) => item.id == habit.id);
      if (indexAfterSync >= 0) {
        _habits[indexAfterSync] = habit;
      } else {
        _habits.add(habit);
      }
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _habits
        ..clear()
        ..addAll(snapshot);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final index = _habits.indexWhere((item) => item.id == updatedHabit.id);
    if (index < 0) {
      return;
    }

    final snapshot = List<Habit>.from(_habits);
    _habits[index] = updatedHabit;
    notifyListeners();

    try {
      await _firebaseService.upsertHabit(updatedHabit);
    } catch (e) {
      _habits
        ..clear()
        ..addAll(snapshot);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String habitId) async {
    final snapshot = List<Habit>.from(_habits);
    _habits.removeWhere((habit) => habit.id == habitId);
    notifyListeners();

    try {
      await _firebaseService.deleteHabit(habitId);
    } catch (e) {
      _habits
        ..clear()
        ..addAll(snapshot);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<int> deleteAutoGeneratedHabits() async {
    final candidates = _habits
        .where((habit) => habit.isAutoGeneratedPlaceholder)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return 0;
    }

    final snapshot = List<Habit>.from(_habits);
    _habits.removeWhere((habit) => habit.isAutoGeneratedPlaceholder);
    notifyListeners();

    try {
      await _firebaseService.deleteHabitsByIds(
        candidates.map((habit) => habit.id).toList(growable: false),
      );
      return candidates.length;
    } catch (e) {
      _habits
        ..clear()
        ..addAll(snapshot);
      _errorMessage = e.toString();
      notifyListeners();
      return 0;
    }
  }

  // For habit target = 1/day this toggles completion directly.
  // For target > 1/day this only clears when already completed;
  // detail checkboxes should use toggleSubTaskProgress.
  Future<void> toggleMainCompletion(String habitId, {DateTime? date}) async {
    final selected = date ?? _selectedDate;
    final index = _habits.indexWhere((habit) => habit.id == habitId);
    if (index < 0) {
      return;
    }

    final snapshot = List<Habit>.from(_habits);
    final updated = _habits[index].toggleMainCompletion(selected);
    _habits[index] = updated;
    notifyListeners();

    await _syncSingleHabitWithRollback(updated, snapshot);
    _checkAndUnlockBadges(habit: updated, date: selected);
  }

  Future<void> toggleSubTaskProgress(
    String habitId,
    int stepIndex, {
    DateTime? date,
  }) async {
    final selected = date ?? _selectedDate;
    final index = _habits.indexWhere((habit) => habit.id == habitId);
    if (index < 0) {
      return;
    }

    final snapshot = List<Habit>.from(_habits);
    final updated = _habits[index].toggleSubStep(selected, stepIndex);
    _habits[index] = updated;
    notifyListeners();

    await _syncSingleHabitWithRollback(updated, snapshot);
    _checkAndUnlockBadges(habit: updated, date: selected);
  }

  void consumeLatestAchievement() {
    _latestUnlockedBadge = null;
    _latestUnlockedHabitName = null;
    notifyListeners();
  }

  Future<void> _syncSingleHabitWithRollback(
    Habit updated,
    List<Habit> snapshot,
  ) async {
    try {
      await _firebaseService.upsertHabit(updated);
    } catch (e) {
      _habits
        ..clear()
        ..addAll(snapshot);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _checkAndUnlockBadges({required Habit habit, required DateTime date}) {
    if (!habit.isCompletedOn(date)) {
      return;
    }

    final streak = habit.currentStreak(now: date);

    for (var i = 0; i < _badges.length; i++) {
      final badge = _badges[i];
      if (badge.isUnlocked) {
        continue;
      }

      if (streak >= badge.milestoneDays) {
        final unlocked = badge.copyWith(
          unlockedAt: DateTime.now(),
          unlockedByHabitId: habit.id,
          unlockedByHabitName: habit.name,
        );
        _badges[i] = unlocked;
        _latestUnlockedBadge = unlocked;
        _latestUnlockedHabitName = habit.name;
      }
    }

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
