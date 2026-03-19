import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';

import '../providers/gamification_provider.dart';
import '../providers/habit_provider.dart';
import '../models/habit_model.dart';
import '../screens/streak_badges_screen.dart';
import '../widgets/add_habit_bottom_sheet.dart';
import '../widgets/achievement_popup.dart';
import '../widgets/common_alert_dialog.dart';
import '../widgets/expandable_checkbox.dart';
import '../widgets/habit_card.dart';
import '../widgets/search_bar_sliver.dart';

class DashboardCalendarScreen extends StatefulWidget {
  const DashboardCalendarScreen({Key? key}) : super(key: key);

  @override
  State<DashboardCalendarScreen> createState() =>
      _DashboardCalendarScreenState();
}

class _DashboardCalendarScreenState extends State<DashboardCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isShowingAchievement = false;
  bool _didSyncSelectedDate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSyncSelectedDate) {
      final provider = context.read<HabitProvider>();
      _selectedDate = provider.selectedDate;
      _didSyncSelectedDate = true;
    }
    _scheduleAchievementPopup();
  }

  void _scheduleAchievementPopup() {
    if (_isShowingAchievement) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isShowingAchievement) return;

      final gamification = context.read<GamificationProvider>();
      final newBadge = gamification.latestUnlockedBadge;
      if (newBadge == null) return;

      _isShowingAchievement = true;
      showAchievementPopup(
        context,
        habitName:
            gamification.latestUnlockedHabitName ??
            newBadge.unlockedByHabitName ??
            'Habit',
        streakDays: newBadge.milestoneDays,
        badgeTitle: newBadge.title,
      ).whenComplete(() {
        if (!mounted) return;
        gamification.consumeLatestAchievement();
        _isShowingAchievement = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: false,
            expandedHeight: 100,
            title: const Text('Habit Tracker - Nhom [So nhom]'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () {
                  // TODO: Show filter options
                },
              ),
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(),
            ),
          ),
          const SearchBarSliver(),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 96,
              child: _WeekCalendar(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                  context.read<HabitProvider>().setSelectedDate(date);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _HabitList(
                key: ValueKey(_selectedDate),
                selectedDate: _selectedDate,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const FractionallySizedBox(
              heightFactor: 0.8,
              child: AddHabitBottomSheet(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _WeekCalendar({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: days.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final day = days[index];
        final isSelected =
            day.year == selectedDate.year &&
            day.month == selectedDate.month &&
            day.day == selectedDate.day;
        final isToday =
            day.year == now.year &&
            day.month == now.month &&
            day.day == now.day;

        return GestureDetector(
          onTap: () => onDateSelected(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.transparent,
                width: isToday ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekdayLabel(day.weekday),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day.day.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return labels[weekday - 1];
  }
}

class _HabitList extends StatefulWidget {
  final DateTime selectedDate;

  const _HabitList({super.key, required this.selectedDate});

  @override
  State<_HabitList> createState() => _HabitListState();
}

class _HabitListState extends State<_HabitList> {
  Future<void> _openEditHabitSheet(Habit habit) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: AddHabitBottomSheet(initialHabit: habit),
      ),
    );
  }

  Future<bool> _confirmDeleteHabit(Habit habit) async {
    final confirm = await showCommonAlertDialog(
      context,
      title: 'Xac nhan xoa',
      content:
          'Ban co chac chan muon xoa "${habit.name}"? Moi chuoi (Streak) se bi mat!',
      confirmText: 'Xoa',
      cancelText: 'Huy',
    );
    return confirm == true;
  }

  Future<void> _removeHabit(Habit habit) async {
    await context.read<HabitProvider>().deleteHabit(habit.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Da xoa thoi quen ${habit.name}')));
  }

  List<bool> _checkedListForHabit(Habit habit) {
    final key = Habit.dateKey(widget.selectedDate);
    final completedSteps = (habit.progressByDate[key] ?? <int>[]).toSet();
    return List<bool>.generate(
      habit.targetCountPerDay,
      (index) => completedSteps.contains(index),
    );
  }

  Future<void> _applyCheckedList(Habit habit, List<bool> next) async {
    final previous = _checkedListForHabit(habit);
    for (var i = 0; i < next.length; i++) {
      if (i >= previous.length) {
        break;
      }
      if (next[i] != previous[i]) {
        await context.read<HabitProvider>().toggleSubTaskProgress(
          habit.id,
          i,
          date: widget.selectedDate,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habitsForSelectedDate;

    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.errorMessage != null && habits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(child: Text('Loi tai du lieu: ${provider.errorMessage}')),
      );
    }

    if (habits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Khong co thoi quen nao cho ngay nay.')),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: habits.length,
        itemBuilder: (context, index) {
          final habit = habits[index];
          final isMulti = habit.targetCountPerDay > 1;
          final checkedList = _checkedListForHabit(habit);
          final completed = habit.isCompletedOn(widget.selectedDate);
          final timeLabel = habit.reminderMinutesFromMidnight == null
              ? '--:--'
              : _formatMinutes(habit.reminderMinutesFromMidnight!);
          final icon = habit.iconCodePoint == null
              ? Icons.check_circle_outline
              : IconData(
                  habit.iconCodePoint!,
                  fontFamily: habit.iconFontFamily,
                );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Slidable(
              key: ValueKey(habit.id),
              closeOnScroll: false,
              endActionPane: ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.28,
                dismissible: DismissiblePane(
                  closeOnCancel: true,
                  onDismissed: () => _removeHabit(habit),
                  confirmDismiss: () => _confirmDeleteHabit(habit),
                ),
                children: [
                  SlidableAction(
                    onPressed: (_) async {
                      final shouldDelete = await _confirmDeleteHabit(habit);
                      if (!shouldDelete || !mounted) return;
                      await _removeHabit(habit);
                    },
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    icon: Icons.delete,
                    label: 'Xoa',
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openEditHabitSheet(habit),
                    onLongPress: () => _openEditHabitSheet(habit),
                    child: HabitCard(
                      icon: icon,
                      name: habit.name,
                      time: timeLabel,
                      completed: completed,
                      onTap: null,
                      onEdit: () => _openEditHabitSheet(habit),
                      onDelete: () async {
                        final shouldDelete = await _confirmDeleteHabit(habit);
                        if (!shouldDelete || !mounted) return;
                        await _removeHabit(habit);
                      },
                    ),
                  ),
                  if (isMulti)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 4,
                        left: 16,
                        right: 16,
                      ),
                      child: ExpandableCheckbox(
                        repeatCount: habit.targetCountPerDay,
                        checkedList: checkedList,
                        onChanged: (list) async {
                          await _applyCheckedList(habit, list);
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
