import 'package:flutter/material.dart';

enum DateBucket { week, month, year }

class DateTimeHelpers {
  const DateTimeHelpers._();

  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<DateTime> daysInWeek({
    DateTime? anchor,
    int firstWeekday = DateTime.monday,
  }) {
    final focus = normalizeDate(anchor ?? DateTime.now());
    final offset = (focus.weekday - firstWeekday + 7) % 7;
    final start = focus.subtract(Duration(days: offset));

    return List<DateTime>.generate(
      7,
      (index) => normalizeDate(start.add(Duration(days: index))),
    );
  }

  static List<DateTime> daysInMonth({DateTime? anchor}) {
    final focus = normalizeDate(anchor ?? DateTime.now());
    final firstDay = DateTime(focus.year, focus.month, 1);
    final totalDays = DateTime(focus.year, focus.month + 1, 0).day;

    return List<DateTime>.generate(
      totalDays,
      (index) => DateTime(firstDay.year, firstDay.month, index + 1),
    );
  }

  static List<DateTime> daysInYear({DateTime? anchor}) {
    final focus = normalizeDate(anchor ?? DateTime.now());
    final firstDay = DateTime(focus.year, 1, 1);
    final lastDay = DateTime(focus.year, 12, 31);
    return datesInRange(start: firstDay, end: lastDay);
  }

  static List<DateTime> datesInRange({
    required DateTime start,
    required DateTime end,
  }) {
    final normalizedStart = normalizeDate(start);
    final normalizedEnd = normalizeDate(end);

    if (normalizedEnd.isBefore(normalizedStart)) {
      return <DateTime>[];
    }

    final total = normalizedEnd.difference(normalizedStart).inDays + 1;
    return List<DateTime>.generate(
      total,
      (index) => normalizedStart.add(Duration(days: index)),
    );
  }

  static List<DateTime> monthBucketsInYear({DateTime? anchor}) {
    final focus = normalizeDate(anchor ?? DateTime.now());
    return List<DateTime>.generate(
      12,
      (index) => DateTime(focus.year, index + 1, 1),
    );
  }

  static String weekdayShortLabel(DateTime date) {
    const names = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }

  static String monthShortLabel(int month) {
    const names = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  static String toDateKey(DateTime date) {
    final normalized = normalizeDate(date);
    final mm = normalized.month.toString().padLeft(2, '0');
    final dd = normalized.day.toString().padLeft(2, '0');
    return '${normalized.year}-$mm-$dd';
  }

  static DateTimeRange rangeForBucket(DateBucket bucket, {DateTime? anchor}) {
    final focus = normalizeDate(anchor ?? DateTime.now());

    switch (bucket) {
      case DateBucket.week:
        final days = daysInWeek(anchor: focus);
        return DateTimeRange(start: days.first, end: days.last);
      case DateBucket.month:
        final days = daysInMonth(anchor: focus);
        return DateTimeRange(start: days.first, end: days.last);
      case DateBucket.year:
        final start = DateTime(focus.year, 1, 1);
        final end = DateTime(focus.year, 12, 31);
        return DateTimeRange(start: start, end: end);
    }
  }

  static int weekIndexInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    return ((date.day + firstDay.weekday - 2) ~/ 7) + 1;
  }

  static double safePercent({required int part, required int total}) {
    if (total <= 0) {
      return 0;
    }
    return (part / total).clamp(0, 1);
  }
}
