class WeekType {
  static String getCurrentType() {
    final now = DateTime.now();
    final currentYear = now.year;
    final september1 = DateTime(currentYear, 9, 1);
    final september1Weekday = september1.weekday;
    
    DateTime firstEdWeek;
    if (september1Weekday > 5) {
      firstEdWeek = september1.add(Duration(days: 8 - september1Weekday));
    } else {
      firstEdWeek = september1;
    }

    final currentWeek = now;
    final weekDiff = _getWeekNumber(currentWeek) - _getWeekNumber(firstEdWeek);

    return weekDiff % 2 == 0 ? 'numerator' : 'denominator';
  }

  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear + firstDayOfYear.weekday - 1) / 7).ceil();
  }
}