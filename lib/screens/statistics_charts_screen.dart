import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit_model.dart';
import 'package:habit_tracker/providers/habit_provider.dart';
import 'package:habit_tracker/widgets/animated_pie_chart.dart';
import 'package:provider/provider.dart';

class StatisticsChartsScreen extends StatelessWidget {
  const StatisticsChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thống kê tiến độ'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Tuần', icon: Icon(Icons.date_range_outlined)),
              Tab(text: 'Tháng', icon: Icon(Icons.calendar_today_outlined)),
              Tab(text: 'Năm', icon: Icon(Icons.event_note_outlined)),
              Tab(text: 'Báo cáo', icon: Icon(Icons.summarize_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PeriodChartTab(period: _Period.week),
            _PeriodChartTab(period: _Period.month),
            _PeriodChartTab(period: _Period.year),
            _ReportTab(),
          ],
        ),
      ),
    );
  }
}

enum _Period { week, month, year }

class _PeriodChartTab extends StatefulWidget {
  const _PeriodChartTab({required this.period});

  final _Period period;

  @override
  State<_PeriodChartTab> createState() => _PeriodChartTabState();
}

class _PeriodChartTabState extends State<_PeriodChartTab> {
  String? _selectedHabitId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;

    if (habits.isEmpty) {
      return const Center(
        child: Text('Chưa có thói quen để thống kê. Hãy tạo thói quen trước.'),
      );
    }

    final selectedDate = provider.selectedDate;
    final range = _DateRange.fromPeriod(widget.period, selectedDate);

    final selectedHabit = _selectedHabitId == null
        ? null
        : habits.where((h) => h.id == _selectedHabitId).firstOrNull;

    final overview = _calculateProgress(range: range, habits: habits);
    final detailed = selectedHabit == null
        ? null
        : _calculateProgress(range: range, habits: [selectedHabit]);

    final chartData = detailed ?? overview;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấp độ 1: Tổng quan tất cả thói quen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Khoảng thời gian: ${_formatDate(range.start)} - ${_formatDate(range.end)}',
                ),
                const SizedBox(height: 12),
                AnimatedPieChart(
                  key: ValueKey(
                    'overview-${widget.period.name}-${overview.completed}-${overview.pending}',
                  ),
                  completed: overview.completed.toDouble(),
                  pending: overview.pending.toDouble(),
                  centerValue: habits.length,
                  centerLabel: 'Tổng số thói quen',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấp độ 2: Chi tiết theo từng thói quen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedHabitId,
                  decoration: const InputDecoration(
                    labelText: 'Chọn thói quen',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Tất cả thói quen'),
                    ),
                    ...habits.map(
                      (habit) => DropdownMenuItem<String?>(
                        value: habit.id,
                        child: Text(habit.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedHabitId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                AnimatedPieChart(
                  key: ValueKey(
                    'detail-${widget.period.name}-${_selectedHabitId ?? 'all'}-${chartData.completed}-${chartData.pending}',
                  ),
                  completed: chartData.completed.toDouble(),
                  pending: chartData.pending.toDouble(),
                  centerValue: selectedHabit == null ? habits.length : 1,
                  centerLabel: selectedHabit == null
                      ? 'Tổng số thói quen'
                      : 'Thói quen đang chọn',
                ),
                const SizedBox(height: 8),
                Text(
                  selectedHabit == null
                      ? 'Đang hiển thị dữ liệu tổng hợp cho tất cả thói quen.'
                      : 'Đang hiển thị dữ liệu cho: ${selectedHabit.name}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _ProgressSlice _calculateProgress({
    required _DateRange range,
    required List<Habit> habits,
  }) {
    var completed = 0;
    var pending = 0;

    for (final habit in habits) {
      for (
        var date = range.start;
        !date.isAfter(range.end);
        date = date.add(const Duration(days: 1))
      ) {
        if (!habit.isScheduledOn(date)) {
          continue;
        }

        if (habit.isCompletedOn(date)) {
          completed += 1;
        } else {
          pending += 1;
        }
      }
    }

    if (completed == 0 && pending == 0) {
      // Fall back to avoid empty chart when habits have no scheduled dates.
      return const _ProgressSlice(completed: 0, pending: 1);
    }

    return _ProgressSlice(completed: completed, pending: pending);
  }
}

class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (habits.isEmpty) {
      return const Center(child: Text('Không có dữ liệu báo cáo.'));
    }

    final selectedDate = provider.selectedDate;
    final week = _DateRange.fromPeriod(_Period.week, selectedDate);
    final month = _DateRange.fromPeriod(_Period.month, selectedDate);
    final year = _DateRange.fromPeriod(_Period.year, selectedDate);

    final weekRate = _completionRate(week, habits);
    final monthRate = _completionRate(month, habits);
    final yearRate = _completionRate(year, habits);

    final rankedHabits = habits.toList()
      ..sort((a, b) {
        final aRate = _completionRate(year, [a]);
        final bRate = _completionRate(year, [b]);
        return bRate.compareTo(aRate);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tổng hợp nhanh',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Tỉ lệ hoàn thành trong tuần',
          value: '${weekRate.toStringAsFixed(1)}%',
          color: isDarkMode ? const Color(0xFF1D2A3A) : const Color(0xFFEEF7FF),
          textColor: isDarkMode ? Colors.white : null,
        ),
        _MetricCard(
          title: 'Tỉ lệ hoàn thành trong tháng',
          value: '${monthRate.toStringAsFixed(1)}%',
          color: isDarkMode ? const Color(0xFF1B3428) : const Color(0xFFEFFFF0),
          textColor: isDarkMode ? Colors.white : null,
        ),
        _MetricCard(
          title: 'Tỉ lệ hoàn thành trong năm',
          value: '${yearRate.toStringAsFixed(1)}%',
          color: isDarkMode ? const Color(0xFF3A2F1D) : const Color(0xFFFFF7EA),
          textColor: isDarkMode ? Colors.white : null,
        ),
        const SizedBox(height: 12),
        Text(
          'Xếp hạng thói quen theo năm',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...rankedHabits.take(5).toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final habit = entry.value;
          final rate = _completionRate(year, [habit]);
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('${idx + 1}')),
            title: Text(habit.name),
            subtitle: Text('Hoàn thành ${rate.toStringAsFixed(1)}% trong năm'),
          );
        }),
      ],
    );
  }

  double _completionRate(_DateRange range, List<Habit> habits) {
    var completed = 0;
    var total = 0;
    for (final habit in habits) {
      for (
        var date = range.start;
        !date.isAfter(range.end);
        date = date.add(const Duration(days: 1))
      ) {
        if (!habit.isScheduledOn(date)) {
          continue;
        }
        total += 1;
        if (habit.isCompletedOn(date)) {
          completed += 1;
        }
      }
    }

    if (total == 0) {
      return 0;
    }
    return (completed / total) * 100;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    this.textColor,
  });

  final String title;
  final String value;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: textColor),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRange {
  const _DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory _DateRange.fromPeriod(_Period period, DateTime selectedDate) {
    final normalized = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    switch (period) {
      case _Period.week:
        final start = normalized.subtract(
          Duration(days: normalized.weekday - 1),
        );
        final end = start.add(const Duration(days: 6));
        return _DateRange(start: start, end: end);
      case _Period.month:
        final start = DateTime(normalized.year, normalized.month, 1);
        final end = DateTime(normalized.year, normalized.month + 1, 0);
        return _DateRange(start: start, end: end);
      case _Period.year:
        final start = DateTime(normalized.year, 1, 1);
        final end = DateTime(normalized.year, 12, 31);
        return _DateRange(start: start, end: end);
    }
  }
}

class _ProgressSlice {
  const _ProgressSlice({required this.completed, required this.pending});

  final int completed;
  final int pending;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
