class WeekType {
  static String getCurrentType({DateTime? date}) {
    final now = date ?? DateTime.now();
    final currentYear = now.year;
    final september1 = DateTime(currentYear, 9, 1);
    final september1Weekday = september1.weekday;

    DateTime firstEdWeek;
    if (september1Weekday > 5) {
      firstEdWeek = september1.add(Duration(days: 8 - september1Weekday));
    } else {
      firstEdWeek = september1;
    }

    final weekDiff = _isoWeekNumber(now) - _isoWeekNumber(firstEdWeek);

    return weekDiff % 2 == 0 ? 'numerator' : 'denominator';
  }

  static int _isoWeekNumber(DateTime date) {
    final yearStart = DateTime(date.year, 1, 1);
    final yearStartWeekday = yearStart.weekday;
    final isoStart = yearStart.add(Duration(days: (4 - yearStartWeekday) % 7));

    final diff = date.difference(isoStart).inDays;

    return (diff / 7).ceil() + 1;
  }
}
