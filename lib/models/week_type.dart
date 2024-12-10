class WeekType {
  static String getCurrentType({DateTime? date}) {
    final now = date ?? DateTime.now(); // Використовуємо переданий день або поточний день
    final currentYear = now.year;
    final september1 = DateTime(currentYear, 9, 1);
    final september1Weekday = september1.weekday;

    // Визначення першого навчального тижня
    DateTime firstEdWeek;
    if (september1Weekday > 5) {
      firstEdWeek = september1.add(Duration(days: 8 - september1Weekday));
    } else {
      firstEdWeek = september1;
    }

    // Різниця тижнів за ISO-календарем
    final weekDiff = _isoWeekNumber(now) - _isoWeekNumber(firstEdWeek);

    // Визначення типу тижня
    return weekDiff % 2 == 0 ? 'numerator' : 'denominator';
  }

  // Обчислення номера тижня за ISO-8601
  static int _isoWeekNumber(DateTime date) {
    // ISO-перший день року (четвер першого тижня)
    final yearStart = DateTime(date.year, 1, 1);
    final yearStartWeekday = yearStart.weekday;
    final isoStart = yearStart.add(Duration(days: (4 - yearStartWeekday) % 7));

    // Кількість днів від початку ISO-року до даної дати
    final diff = date.difference(isoStart).inDays;

    // Номер тижня
    return (diff / 7).ceil() + 1;
  }
}
