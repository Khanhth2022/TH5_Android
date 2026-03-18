import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:habit_tracker/firebase_options.dart';
import 'package:habit_tracker/models/habit_model.dart';
import 'package:habit_tracker/providers/gamification_provider.dart';
import 'package:habit_tracker/providers/habit_provider.dart';
import 'package:habit_tracker/screens/streak_badges_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HabitProvider>(
          create: (_) => HabitProvider()..loadHabits(),
        ),
        ChangeNotifierProxyProvider<HabitProvider, GamificationProvider>(
          create: (_) => GamificationProvider(),
          update: (_, habitProvider, gamificationProvider) {
            final provider = gamificationProvider ?? GamificationProvider();
            provider.evaluateFromHabits(habitProvider.habits);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Habit Tracker',
        themeMode: ThemeMode.system,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
          ),
        ),
        home: const DashboardBootstrapScreen(),
      ),
    );
  }
}

class DashboardBootstrapScreen extends StatelessWidget {
  const DashboardBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habitsForSelectedDate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker - Nhóm 1'),
        actions: [
          IconButton(
            tooltip: 'Streak & Badges',
            icon: const Icon(Icons.workspace_premium),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StreakBadgesScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _DateStrip(
                  selectedDate: provider.selectedDate,
                  onDateTap: provider.setSelectedDate,
                ),
                Expanded(
                  child: habits.isEmpty
                      ? const Center(
                          child: Text(
                            'Chua co thoi quen nao cho ngay duoc chon.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: habits.length,
                          itemBuilder: (context, index) {
                            final habit = habits[index];
                            final completed = habit.isCompletedOn(
                              provider.selectedDate,
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: Icon(
                                  completed
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: completed ? Colors.green : null,
                                ),
                                title: Text(habit.name),
                                subtitle: Text(
                                  'Tien do: ${habit.completedCountOn(provider.selectedDate)}/${habit.targetCountPerDay}',
                                ),
                                trailing: Checkbox(
                                  value: completed,
                                  onChanged: (_) {
                                    if (habit.targetCountPerDay == 1) {
                                      provider.toggleMainCompletion(habit.id);
                                      return;
                                    }

                                    final nextIndex = habit.completedCountOn(
                                      provider.selectedDate,
                                    );
                                    if (nextIndex < habit.targetCountPerDay) {
                                      provider.toggleSubTaskProgress(
                                        habit.id,
                                        nextIndex,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final now = DateTime.now().millisecondsSinceEpoch;
          provider.addHabit(
            Habit(
              id: 'habit_$now',
              name: 'Habit $now',
              targetCountPerDay: 1,
              activeWeekdays: <int>{1, 2, 3, 4, 5, 6, 7},
              createdAt: DateTime.now(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selectedDate, required this.onDateTap});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final week = List<DateTime>.generate(7, (index) {
      final start = now.subtract(Duration(days: now.weekday - 1));
      return DateTime(start.year, start.month, start.day + index);
    });

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: week.length,
        itemBuilder: (context, index) {
          final date = week[index];
          final selected =
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: ChoiceChip(
              label: Text('${date.day}/${date.month}'),
              selected: selected,
              onSelected: (_) => onDateTap(date),
            ),
          );
        },
      ),
    );
  }
}
