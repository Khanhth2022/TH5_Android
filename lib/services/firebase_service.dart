import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habit_tracker/models/habit_model.dart';

class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _habitCollection =>
      _firestore.collection('habits');

  Future<List<Habit>> fetchHabits() async {
    final snapshot = await _habitCollection.orderBy('name').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data.putIfAbsent('id', () => doc.id);
      return Habit.fromJson(data);
    }).toList();
  }

  Future<void> upsertHabit(Habit habit) async {
    await _habitCollection.doc(habit.id).set(habit.toJson());
  }

  Future<void> deleteHabit(String habitId) async {
    await _habitCollection.doc(habitId).delete();
  }

  Future<void> batchUpsertHabits(List<Habit> habits) async {
    final batch = _firestore.batch();
    for (final habit in habits) {
      final ref = _habitCollection.doc(habit.id);
      batch.set(ref, habit.toJson());
    }
    await batch.commit();
  }

  Future<void> syncAllHabits(List<Habit> habits) async {
    final existing = await _habitCollection.get();
    final batch = _firestore.batch();

    final incomingIds = habits.map((habit) => habit.id).toSet();
    for (final doc in existing.docs) {
      if (!incomingIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

    for (final habit in habits) {
      final ref = _habitCollection.doc(habit.id);
      batch.set(ref, habit.toJson());
    }

    await batch.commit();
  }
}
