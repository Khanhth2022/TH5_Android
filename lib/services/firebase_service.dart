import 'dart:math';

import 'package:habit_tracker/models/habit_model.dart';

class FirebaseService {
  FirebaseService({
    Duration networkDelay = const Duration(milliseconds: 250),
    double failureRate = 0,
  }) : _networkDelay = networkDelay,
       _failureRate = failureRate;

  final Duration _networkDelay;
  final double _failureRate;

  final Map<String, Habit> _habitStore = <String, Habit>{};
  final Random _random = Random();

  Future<List<Habit>> fetchHabits() async {
    await _simulateNetwork();
    return _habitStore.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> upsertHabit(Habit habit) async {
    await _simulateNetwork();
    _habitStore[habit.id] = habit;
  }

  Future<void> deleteHabit(String habitId) async {
    await _simulateNetwork();
    _habitStore.remove(habitId);
  }

  Future<void> batchUpsertHabits(List<Habit> habits) async {
    await _simulateNetwork();
    for (final habit in habits) {
      _habitStore[habit.id] = habit;
    }
  }

  Future<void> syncAllHabits(List<Habit> habits) async {
    await _simulateNetwork();
    _habitStore
      ..clear()
      ..addEntries(habits.map((habit) => MapEntry(habit.id, habit)));
  }

  Future<void> _simulateNetwork() async {
    await Future<void>.delayed(_networkDelay);
    if (_failureRate <= 0) {
      return;
    }
    final shouldFail = _random.nextDouble() < _failureRate;
    if (shouldFail) {
      throw Exception('Network error while syncing with Firebase.');
    }
  }
}
