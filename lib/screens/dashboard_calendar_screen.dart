import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/gamification_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/add_habit_bottom_sheet.dart';
import '../widgets/achievement_popup.dart';
import '../widgets/common_alert_dialog.dart';
import '../widgets/expandable_checkbox.dart';
import '../widgets/habit_card.dart';
import '../widgets/search_bar_sliver.dart';

class DashboardCalendarScreen extends StatefulWidget {
  const DashboardCalendarScreen({super.key});

  @override
  State<DashboardCalendarScreen> createState() =>
      _DashboardCalendarScreenState();
}

class _DashboardCalendarScreenState extends State<DashboardCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isShowingAchievement = false;
  bool _didSyncSelectedDate = false;
  bool _didSyncSearchQuery = false;
  bool _isCalendarExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_didSyncSelectedDate) {
      _selectedDate = context.read<HabitProvider>().selectedDate;
      _didSyncSelectedDate = true;
    }

    if (!_didSyncSearchQuery) {
      _searchController.text = context.read<HabitProvider>().searchQuery;
      _didSyncSearchQuery = true;
    }

    if (_isShowingAchievement) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isShowingAchievement) {
        return;
      }

      final gamification = context.read<GamificationProvider>();
      final newBadge = gamification.latestUnlockedBadge;
      if (newBadge == null) {
        return;
      }

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
        if (!mounted) {
          return;
        }
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
            expandedHeight: 90,
            title: const Text('Habit Tracker - Nhóm 6'),
            actions: [const _ThemeModeMenuButton()],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(60),
              child: SizedBox.shrink(),
            ),
          ),
          SearchBarSliver(
            hintText: 'Tìm theo tên thói quen...',
            controller: _searchController,
            onChanged: (value) {
              context.read<HabitProvider>().setSearchQuery(value);
            },
            onClear: () {
              _searchController.clear();
              context.read<HabitProvider>().setSearchQuery('');
            },
          ),
          SliverToBoxAdapter(
            child: _CalendarDropdown(
              selectedDate: _selectedDate,
              isExpanded: _isCalendarExpanded,
              onToggle: () {
                setState(() {
                  _isCalendarExpanded = !_isCalendarExpanded;
                });
              },
              onDateSelected: (date) {
                final normalizedDate = DateTime(
                  date.year,
                  date.month,
                  date.day,
                );
                setState(() {
                  _selectedDate = normalizedDate;
                  _isCalendarExpanded = false;
                });
                context.read<HabitProvider>().setSelectedDate(normalizedDate);
              },
              onSelectToday: () {
                final today = DateTime.now();
                final normalizedToday = DateTime(
                  today.year,
                  today.month,
                  today.day,
                );
                setState(() {
                  _selectedDate = normalizedToday;
                });
                context.read<HabitProvider>().setSelectedDate(normalizedToday);
              },
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 4)),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _HabitList(
                key: ValueKey(Habit.dateKey(_selectedDate)),
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
            builder: (_) => const FractionallySizedBox(
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

class _CalendarDropdown extends StatelessWidget {
  const _CalendarDropdown({
    required this.selectedDate,
    required this.isExpanded,
    required this.onToggle,
    required this.onDateSelected,
    required this.onSelectToday,
  });

  final DateTime selectedDate;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onSelectToday;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedSelected = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isToday = normalizedSelected == today;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.today, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isToday
                                ? 'Hôm nay (${_formatDate(selectedDate)})'
                                : _formatDate(selectedDate),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSelectToday,
                  child: const Text('Chọn hôm nay'),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _MonthCalendar(
                selectedDate: selectedDate,
                onDateSelected: onDateSelected,
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthCalendar({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: CalendarDatePicker(
        initialDate: selectedDate,
        firstDate: DateTime(2020, 1, 1),
        lastDate: DateTime(2100, 12, 31),
        currentDate: DateTime.now(),
        onDateChanged: onDateSelected,
      ),
    );
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
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.8,
        child: AddHabitBottomSheet(initialHabit: habit),
      ),
    );
  }

  Future<bool> _confirmDeleteHabit(Habit habit) async {
    final confirm = await showCommonAlertDialog(
      context,
      title: 'Xác nhận xóa',
      content:
          'Bạn có chắc chắn muốn xóa "${habit.name}"? Mọi chuỗi (Streak) sẽ bị mất!',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
    );
    return confirm == true;
  }

  Future<void> _removeHabit(Habit habit) async {
    await context.read<HabitProvider>().deleteHabit(habit.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã xóa thói quen ${habit.name}')));
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

  Future<void> _toggleHabitCompletion(Habit habit) async {
    if (habit.targetCountPerDay == 1) {
      await context.read<HabitProvider>().toggleMainCompletion(
        habit.id,
        date: widget.selectedDate,
      );
      return;
    }

    final completed = habit.isCompletedOn(widget.selectedDate);
    final targetState = !completed;
    final next = List<bool>.filled(habit.targetCountPerDay, targetState);
    await _applyCheckedList(habit, next);
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
        child: Center(child: Text('Lỗi tải dữ liệu: ${provider.errorMessage}')),
      );
    }

    if (habits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('Không có thói quen nào cho ngày này.')),
      );
    }

    return Column(
      children: habits.map((habit) {
        final isMulti = habit.targetCountPerDay > 1;
        final checkedList = _checkedListForHabit(habit);
        final completed = habit.isCompletedOn(widget.selectedDate);
        final timeLabel = habit.reminderMinutesFromMidnight == null
            ? '--:--'
            : _formatMinutes(habit.reminderMinutesFromMidnight!);
        final icon = habit.iconCodePoint == null
            ? Icons.check_circle_outline
            : IconData(habit.iconCodePoint!, fontFamily: habit.iconFontFamily);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              HabitCard(
                icon: icon,
                name: habit.name,
                time: timeLabel,
                completed: completed,
                onTap: () => _toggleHabitCompletion(habit),
                onToggleCompletion: () => _toggleHabitCompletion(habit),
                onEdit: () => _openEditHabitSheet(habit),
                onDelete: () async {
                  final shouldDelete = await _confirmDeleteHabit(habit);
                  if (!shouldDelete || !mounted) {
                    return;
                  }
                  await _removeHabit(habit);
                },
              ),
              if (isMulti)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
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
        );
      }).toList(),
    );
  }

  String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ThemeModeMenuButton extends StatelessWidget {
  const _ThemeModeMenuButton();

  @override
  Widget build(BuildContext context) {
    final currentMode = context.watch<ThemeProvider>().themeMode;

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Chọn chế độ giao diện',
      icon: const Icon(Icons.brightness_6_outlined),
      initialValue: currentMode,
      onSelected: (mode) {
        context.read<ThemeProvider>().setThemeMode(mode);
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem<ThemeMode>(
            value: ThemeMode.system,
            child: Text('Theo hệ thống'),
          ),
          PopupMenuItem<ThemeMode>(value: ThemeMode.light, child: Text('Sáng')),
          PopupMenuItem<ThemeMode>(value: ThemeMode.dark, child: Text('Tối')),
        ];
      },
    );
  }
}
