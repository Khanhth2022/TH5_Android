import 'package:flutter/material.dart';
import 'package:habit_tracker/models/badge_model.dart';
import 'package:habit_tracker/models/habit_model.dart';
import 'package:habit_tracker/models/streak_model.dart';
import 'package:habit_tracker/providers/gamification_provider.dart';
import 'package:habit_tracker/providers/habit_provider.dart';
import 'package:habit_tracker/widgets/achievement_popup.dart';
import 'package:provider/provider.dart';

class StreakBadgesScreen extends StatefulWidget {
  const StreakBadgesScreen({super.key});

  @override
  State<StreakBadgesScreen> createState() => _StreakBadgesScreenState();
}

class _StreakBadgesScreenState extends State<StreakBadgesScreen> {
  bool _isShowingAchievement = false;

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>();
    final newBadge = gamification.latestUnlockedBadge;

    if (newBadge != null && !_isShowingAchievement) {
      _isShowingAchievement = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final gamificationProvider = context.read<GamificationProvider>();

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
          gamificationProvider.consumeLatestAchievement();
          _isShowingAchievement = false;
        });
      });
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Habit Tracker - Nhóm 6'),
          bottom: const TabBar(
            tabs: <Tab>[
              Tab(
                icon: Icon(Icons.local_fire_department),
                text: 'Bảng thống kê',
              ),
              Tab(icon: Icon(Icons.workspace_premium), text: 'Bảng huy hiệu'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[_LeaderboardTab(), _BadgesTab()],
        ),
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    final leaderboard = context.watch<HabitProvider>().streakLeaderboard;

    if (leaderboard.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có dữ liệu chuỗi. Hãy hoàn thành ít nhất 1 thói quen.',
        ),
      );
    }

    final highestCurrentStreak = leaderboard.fold<int>(
      0,
      (best, row) => row.currentStreak > best ? row.currentStreak : best,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 1080
            ? 1080.0
            : constraints.maxWidth;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.primaryContainer,
                      ),
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Tên thói quen')),
                        DataColumn(label: Text('Chuỗi hiện tại')),
                        DataColumn(label: Text('Chuỗi dài nhất')),
                        DataColumn(label: Text('Huy hiệu đạt được')),
                      ],
                      rows: leaderboard.map((row) {
                        final highlight =
                            highestCurrentStreak > 0 &&
                            row.currentStreak == highestCurrentStreak;
                        return _buildDataRow(context, row, highlight);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(BuildContext context, StreakModel row, bool highlight) {
    final highlightColor = Theme.of(context).colorScheme.secondaryContainer;

    return DataRow(
      color: highlight ? WidgetStatePropertyAll(highlightColor) : null,
      cells: <DataCell>[
        DataCell(
          Text(
            row.habitName,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Row(
            children: <Widget>[
              const Icon(Icons.local_fire_department, color: Colors.orange),
              const SizedBox(width: 6),
              Text('${row.currentStreak}'),
            ],
          ),
        ),
        DataCell(Text('${row.longestStreak}')),

        DataCell(_AchievementBadgeIndicator(longestStreak: row.longestStreak)),
      ],
    );
  }
}

class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context) {
    final badges = context.watch<GamificationProvider>().badges;
    final habits = context.watch<HabitProvider>().habits;

    final rows = badges
        .map(
          (badge) => _BadgeStatsRow(
            badge: badge,
            achievements: _buildAchievementList(habits, badge.milestoneDays),
          ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.primaryContainer,
                  ),
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Huy hiệu')),
                    DataColumn(label: Text('Thành tích')),
                    DataColumn(label: Text('Số thói quen đạt được')),
                  ],
                  rows: rows.map((row) {
                    return DataRow.byIndex(
                      index: rows.indexOf(row),
                      onSelectChanged: (_) => _onBadgeStatsTap(context, row),
                      cells: <DataCell>[
                        DataCell(
                          Row(
                            children: <Widget>[
                              Icon(row.icon, color: row.color),
                              const SizedBox(width: 8),
                              Text(row.badgeLabel),
                            ],
                          ),
                        ),
                        DataCell(Text(row.badge.title)),
                        DataCell(Text('${row.achievements.length}')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onBadgeStatsTap(BuildContext context, _BadgeStatsRow row) {
    if (row.achievements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chưa có thói quen nào đạt mốc ${row.badge.milestoneDays} ngày.',
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Danh sách đạt ${row.badge.title}'),
          content: SizedBox(
            width: 460,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: row.achievements.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = row.achievements[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(row.icon, color: row.color),
                  title: Text(item.habitName),
                  subtitle: Text(
                    'Đạt vào: ${_formatDateTime(item.achievedAt)}',
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Không rõ';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }

  List<_HabitAchievement> _buildAchievementList(
    List<Habit> habits,
    int milestone,
  ) {
    final results = <_HabitAchievement>[];
    for (final habit in habits) {
      final achievedAt = _firstReachedMilestoneDate(habit, milestone);
      if (achievedAt != null) {
        results.add(
          _HabitAchievement(habitName: habit.name, achievedAt: achievedAt),
        );
      }
    }
    results.sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    return results;
  }

  DateTime? _firstReachedMilestoneDate(Habit habit, int milestone) {
    final completedDates =
        habit.progressByDate.entries
            .where(
              (entry) => entry.value.toSet().length >= habit.targetCountPerDay,
            )
            .map((entry) => Habit.parseDateKey(entry.key))
            .toList()
          ..sort();

    if (completedDates.isEmpty) {
      return null;
    }

    var run = 1;
    if (run >= milestone) {
      return completedDates.first;
    }

    for (var i = 1; i < completedDates.length; i++) {
      final diff = completedDates[i].difference(completedDates[i - 1]).inDays;
      if (diff == 1) {
        run += 1;
      } else {
        run = 1;
      }

      if (run >= milestone) {
        return completedDates[i];
      }
    }

    return null;
  }
}

class _AchievementBadgeIndicator extends StatelessWidget {
  const _AchievementBadgeIndicator({required this.longestStreak});

  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    if (longestStreak < 7) {
      return const Text('Chưa đạt');
    }

    final descriptor = _descriptorForStreak(longestStreak);
    return Row(
      children: <Widget>[
        Icon(descriptor.icon, color: descriptor.color, size: 20),
        const SizedBox(width: 6),
        Text(descriptor.label),
      ],
    );
  }

  _BadgeDescriptor _descriptorForStreak(int streak) {
    if (streak >= 100) {
      return const _BadgeDescriptor(
        label: 'Kim cương',
        icon: Icons.diamond,
        color: Color(0xFF2AA9FF),
      );
    }
    if (streak >= 50) {
      return const _BadgeDescriptor(
        label: 'Vàng',
        icon: Icons.emoji_events,
        color: Color(0xFFE0A800),
      );
    }
    if (streak >= 21) {
      return const _BadgeDescriptor(
        label: 'Bạc',
        icon: Icons.shield,
        color: Color(0xFF8F9AA6),
      );
    }
    return const _BadgeDescriptor(
      label: 'Đồng',
      icon: Icons.workspace_premium,
      color: Color(0xFFA45A2A),
    );
  }
}

class _BadgeStatsRow {
  const _BadgeStatsRow({required this.badge, required this.achievements});

  final BadgeModel badge;
  final List<_HabitAchievement> achievements;

  String get badgeLabel {
    switch (badge.tier) {
      case BadgeTier.bronze:
        return 'Đồng';
      case BadgeTier.silver:
        return 'Bạc';
      case BadgeTier.gold:
        return 'Vàng';
      case BadgeTier.diamond:
        return 'Kim cương';
    }
  }

  IconData get icon {
    switch (badge.tier) {
      case BadgeTier.bronze:
        return Icons.workspace_premium;
      case BadgeTier.silver:
        return Icons.shield;
      case BadgeTier.gold:
        return Icons.emoji_events;
      case BadgeTier.diamond:
        return Icons.diamond;
    }
  }

  Color get color {
    switch (badge.tier) {
      case BadgeTier.bronze:
        return const Color(0xFFA45A2A);
      case BadgeTier.silver:
        return const Color(0xFF8F9AA6);
      case BadgeTier.gold:
        return const Color(0xFFE0A800);
      case BadgeTier.diamond:
        return const Color(0xFF2AA9FF);
    }
  }
}

class _HabitAchievement {
  const _HabitAchievement({required this.habitName, required this.achievedAt});

  final String habitName;
  final DateTime achievedAt;
}

class _BadgeDescriptor {
  const _BadgeDescriptor({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
