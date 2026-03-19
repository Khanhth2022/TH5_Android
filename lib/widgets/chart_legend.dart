import 'package:flutter/material.dart';

class ChartLegendItem {
  const ChartLegendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.items,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  final List<ChartLegendItem> items;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 10,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Text('${item.label}: ${item.value}', style: textTheme.bodyMedium),
          ],
        );
      }).toList(),
    );
  }
}
