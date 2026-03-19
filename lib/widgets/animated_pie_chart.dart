import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnimatedPieChart extends StatelessWidget {
  const AnimatedPieChart({
    super.key,
    required this.completed,
    required this.pending,
    required this.centerValue,
    this.centerLabel = 'Tổng số thói quen',
    this.completedColor = const Color(0xFF1F9D55),
    this.pendingColor = const Color(0xFFE85D75),
  });

  final double completed;
  final double pending;
  final int centerValue;
  final String centerLabel;
  final Color completedColor;
  final Color pendingColor;

  @override
  Widget build(BuildContext context) {
    final total = completed + pending;
    final safeCompleted = completed < 0 ? 0.0 : completed;
    final safePending = pending < 0 ? 0.0 : pending;
    final completedPercent = total <= 0 ? 0.0 : (safeCompleted / total) * 100;
    final pendingPercent = total <= 0 ? 0.0 : (safePending / total) * 100;

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, t, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 58,
                      sectionsSpace: 3,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: safeCompleted * t,
                          color: completedColor,
                          radius: 54,
                          title: '${completedPercent.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        PieChartSectionData(
                          value: safePending * t,
                          color: pendingColor,
                          radius: 54,
                          title: '${pendingPercent.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$centerValue',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        centerLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _LegendDot(
              color: completedColor,
              label: 'Hoàn thành',
              percentText: '${completedPercent.toStringAsFixed(1)}%',
            ),
            _LegendDot(
              color: pendingColor,
              label: 'Chưa hoàn thành',
              percentText: '${pendingPercent.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.percentText,
  });

  final Color color;
  final String label;
  final String percentText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label: $percentText'),
      ],
    );
  }
}
