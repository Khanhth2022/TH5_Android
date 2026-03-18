import 'package:flutter/material.dart';
import '../widgets/search_bar_sliver.dart';
import 'week_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';
import '../widgets/achievement_popup.dart';

class DashboardCalendarScreen extends StatefulWidget {
  const DashboardCalendarScreen({Key? key}) : super(key: key);

  @override
  State<DashboardCalendarScreen> createState() => _DashboardCalendarScreenState();
}

class _DashboardCalendarScreenState extends State<DashboardCalendarScreen> {
  // Placeholder for selected date, filter, etc.
  DateTime _selectedDate = DateTime.now();
  String _filter = 'all'; // all, completed, pending
  bool _isShowingAchievement = false;

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
            title: const Text('Habit Tracker - Nhóm [Số nhóm]'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () {
                  // TODO: Show filter options
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(), // Placeholder for sticky search bar
            ),
          ),
          const SearchBarSliver(),
          // Widget lịch cuộn ngang 1 tuần
          _WeekCalendar(
            selectedDate: _selectedDate,
            onDateSelected: (date) {
              setState(() {
                _selectedDate = date;
              });
              // TODO: Load lại danh sách thói quen tương ứng ngày
            },
          ),
          // Danh sách thói quen dạng card, load lại khi chọn ngày
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _HabitList(
                key: ValueKey(_selectedDate),
                selectedDate: _selectedDate,
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
            builder: (context) => FractionallySizedBox(
              heightFactor: 0.8,
              child: AddHabitBottomSheet(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget lịch cuộn ngang 1 tuần
  class _WeekCalendar extends StatelessWidget {
    final DateTime selectedDate;
    final ValueChanged<DateTime> onDateSelected;

    const _WeekCalendar({
      required this.selectedDate,
      required this.onDateSelected,
      Key? key,
    }) : super(key: key);

    @override
    Widget build(BuildContext context) {
      final now = DateTime.now();
      final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
      final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.year == selectedDate.year && day.month == selectedDate.month && day.day == selectedDate.day;
          final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
          return GestureDetector(
            onTap: () => onDateSelected(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLabel(day.weekday),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
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

  // Danh sách thói quen dạng card
  class _HabitList extends StatelessWidget {
    final DateTime selectedDate;
    const _HabitList({Key? key, required this.selectedDate}) : super(key: key);

    @override
    Widget build(BuildContext context) {
      // TODO: Lấy danh sách thói quen từ Provider hoặc dữ liệu mẫu
      final habits = <Map<String, dynamic>>[
        {
          'icon': Icons.local_drink,
          'name': 'Uống nước',
          'time': '07:00',
          'completed': false,
          'repeat': 4,
        },
        {
          'icon': Icons.directions_run,
          'name': 'Chạy bộ',
          'time': '18:00',
          'completed': true,
          'repeat': 1,
        },
      ];
      if (habits.isEmpty) {
        return const Center(child: Text('Không có thói quen nào cho ngày này.'));
      }
      return Column(
        children: habits.map((habit) {
          final isMulti = (habit['repeat'] as int) > 1;
          final List<bool> checkedList = List.generate(habit['repeat'] as int, (i) => false);
          bool completed = habit['completed'] as bool;
          return StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    HabitCard(
                      icon: habit['icon'] as IconData,
                      name: habit['name'] as String,
                      time: habit['time'] as String,
                      completed: completed,
                      onTap: isMulti ? null : () {
                        setState(() {
                          completed = !completed;
                        });
                      },
                      onEdit: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => FractionallySizedBox(
                            heightFactor: 0.8,
                            child: AddHabitBottomSheet(), // TODO: Truyền dữ liệu thói quen để sửa
                          ),
                        );
                      },
                      onDelete: () async {
                        final confirm = await showCommonAlertDialog(
                          context,
                          title: 'Xác nhận xóa',
                          content: 'Bạn có chắc chắn muốn xóa thói quen này? Mọi chuỗi (Streak) sẽ bị mất!',
                          confirmText: 'Xóa',
                          cancelText: 'Hủy',
                        );
                        if (confirm == true) {
                          // TODO: Xóa thói quen khỏi danh sách/provider
                        }
                      },
                    ),
                    if (isMulti)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
                        child: ExpandableCheckbox(
                          repeatCount: habit['repeat'] as int,
                          checkedList: checkedList,
                          onChanged: (list) {
                            setState(() {
                              for (int i = 0; i < checkedList.length; i++) {
                                checkedList[i] = list[i];
                              }
                              if (checkedList.every((v) => v)) {
                                completed = true;
                              } else {
                                completed = false;
                              }
                            });
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      );
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final gamification = context.read<GamificationProvider>();
    final newBadge = gamification.latestUnlockedBadge;
    if (newBadge != null && !_isShowingAchievement) {
      _isShowingAchievement = true;
      showAchievementPopup(
        context,
        habitName: gamification.latestUnlockedHabitName ?? newBadge.unlockedByHabitName ?? 'Habit',
        streakDays: newBadge.milestoneDays,
        badgeTitle: newBadge.title,
      ).whenComplete(() {
        if (!mounted) return;
        gamification.consumeLatestAchievement();
        _isShowingAchievement = false;
      });
    }
  });
}
