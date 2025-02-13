class TransportSchedule {
  final int routeId;
  final String routeName;
  final String transportName;
  final String directionName;
  final String interval;
  final List<ScheduleTime> times;

  TransportSchedule({
    required this.routeId,
    required this.routeName,
    required this.transportName,
    required this.directionName,
    required this.interval,
    required this.times,
  });

  factory TransportSchedule.fromJson(Map<String, dynamic> json) {
    return TransportSchedule(
      routeId: json['route_id'],
      routeName: json['route_name'],
      transportName: json['transport_name'],
      directionName: json['direction_name'],
      interval: json['interval_str'],
      times: (json['times'] as List)
          .map((time) => ScheduleTime.fromJson(time))
          .toList(),
    );
  }

  DateTime get nextArrivalTime {
    if (times.isNotEmpty) {
      // Парсимо час прибуття з рядка у форматі "HH:mm"
      final timeStr = times.first.arrivalTimeFormatted;
      final now = DateTime.now();
      final parts = timeStr.split(':');
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } else {
      // Якщо немає точного часу, використовуємо інтервал
      final intervalMinutes = int.tryParse(interval.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return DateTime.now().add(Duration(minutes: intervalMinutes));
    }
  }

  static int compareByArrivalTime(TransportSchedule a, TransportSchedule b) {
    return a.nextArrivalTime.compareTo(b.nextArrivalTime);
  }
}

class ScheduleTime {
  final String arrivalTimeFormatted;
  final String? bortNumber;

  ScheduleTime({
    required this.arrivalTimeFormatted,
    this.bortNumber,
  });

  factory ScheduleTime.fromJson(Map<String, dynamic> json) {
    return ScheduleTime(
      arrivalTimeFormatted: json['arrival_time_formatted'],
      bortNumber: json['bort_number'],
    );
  }
}