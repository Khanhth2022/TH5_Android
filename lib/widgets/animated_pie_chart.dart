import 'dart:math' as math;

import 'package:flutter/material.dart';

class PieChartSegment {
  const PieChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class AnimatedPieChart extends StatelessWidget {
  const AnimatedPieChart({
    super.key,
    required this.segments,
    this.size = 220,
    this.strokeWidth = 26,
    this.animationDuration = const Duration(milliseconds: 950),
    this.centerTitle,
    this.centerSubtitle,
    this.emptyColor,
  });

  final List<PieChartSegment> segments;
  final double size;
  final double strokeWidth;
  final Duration animationDuration;
  final String? centerTitle;
  final String? centerSubtitle;
  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: animationDuration,
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _AnimatedPieChartPainter(
                  segments: segments,
                  progress: progress,
                  strokeWidth: strokeWidth,
                  emptyColor:
                      emptyColor ??
                      theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.8,
                      ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTitle ?? '${(total * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((centerSubtitle ?? '').isNotEmpty)
                    Text(
                      centerSubtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedPieChartPainter extends CustomPainter {
  _AnimatedPieChartPainter({
    required this.segments,
    required this.progress,
    required this.strokeWidth,
    required this.emptyColor,
  });

  final List<PieChartSegment> segments;
  final double progress;
  final double strokeWidth;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = emptyColor;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    if (total <= 0) {
      return;
    }

    var startAngle = -math.pi / 2;
    const gapRadians = 0.04;

    for (final segment in segments) {
      if (segment.value <= 0) {
        continue;
      }

      final sweep = ((segment.value / total) * math.pi * 2) * progress;
      final adjustedSweep = math.max(0.0, sweep - gapRadians);

      final segmentPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = segment.color;

      canvas.drawArc(rect, startAngle, adjustedSweep, false, segmentPaint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedPieChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.emptyColor != emptyColor;
  }
}
