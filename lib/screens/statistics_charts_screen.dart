import 'package:flutter/material.dart';
import 'package:habit_tracker/models/habit_model.dart';
import 'package:habit_tracker/providers/habit_provider.dart';
import 'package:habit_tracker/utils/date_time_helpers.dart';
import 'package:habit_tracker/widgets/animated_pie_chart.dart';
import 'package:habit_tracker/widgets/chart_legend.dart';
import 'package:provider/provider.dart';

class StatisticsChartsScreen extends StatefulWidget {
  const StatisticsChartsScreen({super.key});

  @override
  State<StatisticsChartsScreen> createState() => _StatisticsChartsScreenState();
}

class _StatisticsChartsScreenState extends State<StatisticsChartsScreen> {
  Habit? _selectedHabit;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thong Ke'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tuan'),
              Tab(text: 'Thang'),
              Tab(text: 'Nam'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _StatisticsTab(
              bucket: DateBucket.week,
              selectedHabit: _selectedHabit,
              onHabitSelected: (habit) {
                setState(() => _selectedHabit = habit);
              },
            ),
            _StatisticsTab(
              bucket: DateBucket.month,
              selectedHabit: _selectedHabit,
              onHabitSelected: (habit) {
                setState(() => _selectedHabit = habit);
              },
            ),
            _StatisticsTab(
              bucket: DateBucket.year,
              selectedHabit: _selectedHabit,
              onHabitSelected: (habit) {
                setState(() => _selectedHabit = habit);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsTab extends StatelessWidget {
  const _StatisticsTab({
    required this.bucket,
    this.selectedHabit,
    required this.onHabitSelected,
  });

  final DateBucket bucket;
  final Habit? selectedHabit;
  final ValueChanged<Habit?> onHabitSelected;

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        final allHabits = provider.habits;
        final habits = selectedHabit != null ? [selectedHabit!] : allHabits;

        final summary = _CompletionCalculator.fromHabits(
          habits: habits,
          bucket: bucket,
        );

        final completedRatio = DateTimeHelpers.safePercent(
          part: summary.completed,
          total: summary.total,
        );

        final title = '${(completedRatio * 100).round()}%';
        final subtitle = selectedHabit != null
            ? selectedHabit!.name
            : '${allHabits.length} habts';

        final chartSegments = <PieChartSegment>[
          PieChartSegment(
            label: 'Completed',
            value: summary.completed.toDouble(),
            color: Colors.teal,
          ),
          PieChartSegment(
            label: 'Pending',
            value: summary.pending.toDouble(),
            color: Colors.orange,
          ),
        ];

        if (summary.total == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Chua co du lieu thoi quen trong khoang thoi gian nay.',
                  ),
                  if (selectedHabit != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () => onHabitSelected(null),
                        child: const Text('Tro ve tong the'),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (allHabits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButton<Habit?>(
                  isExpanded: true,
                  value: selectedHabit,
                  hint: const Text('Chon thoi quen'),
                  items: [
                    const DropdownMenuItem<Habit?>(
                      value: null,
                      child: Text('Tat ca thoi quen'),
                    ),
                    ...allHabits.map(
                      (habit) => DropdownMenuItem<Habit?>(
                        value: habit,
                        child: Text(habit.name),
                      ),
                    ),
                  ],
                  onChanged: onHabitSelected,
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    AnimatedPieChart(
                      segments: chartSegments,
                      centerTitle: title,
                      centerSubtitle: subtitle,
                    ),
                    const SizedBox(height: 20),
                    ChartLegend(
                      items: [
                        ChartLegendItem(
                          label: 'Hoan thanh',
                          value: summary.completed,
                          color: Colors.teal,
                        ),
                        ChartLegendItem(
                          label: 'Chua hoan thanh',
                          value: summary.pending,
                          color: Colors.orange,
                        ),
                      ],
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
                      _labelForBucket(bucket),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _MetricRow(
                      label: 'Tong luot theo doi',
                      value: summary.total,
                    ),
                    _MetricRow(
                      label: 'Da hoan thanh',
                      value: summary.completed,
                    ),
                    _MetricRow(label: 'Con lai', value: summary.pending),
                    _MetricRow(
                      label: 'Ty le hoan thanh',
                      valueText:
                          '${(completedRatio * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _labelForBucket(DateBucket bucket) {
    switch (bucket) {
      case DateBucket.week:
        return 'Tong ket theo tuan';
      case DateBucket.month:
        return 'Tong ket theo thang';
      case DateBucket.year:
        return 'Tong ket theo nam';
    }
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({this.label = '', this.value, this.valueText});

  final String label;
  final int? value;
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            valueText ?? (value?.toString() ?? '0'),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CompletionSummary {
  const _CompletionSummary({required this.completed, required this.pending});

  final int completed;
  final int pending;

  int get total => completed + pending;
}

class _CompletionCalculator {
  const _CompletionCalculator._();

  static _CompletionSummary fromHabits({
    required List<Habit> habits,
    required DateBucket bucket,
    DateTime? anchor,
  }) {
    final range = DateTimeHelpers.rangeForBucket(bucket, anchor: anchor);
    final days = DateTimeHelpers.datesInRange(
      start: range.start,
      end: range.end,
    );

    var completed = 0;
    var pending = 0;

    for (final habit in habits) {
      for (final day in days) {
        if (!habit.isScheduledOn(day)) {
          continue;
        }

        if (habit.isCompletedOn(day)) {
          completed += 1;
        } else {
          pending += 1;
        }
      }
    }

    return _CompletionSummary(completed: completed, pending: pending);
  }
}
