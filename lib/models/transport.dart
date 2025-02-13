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
    final now = DateTime.now();
    
    if (times.isNotEmpty) {
      // Парсимо час прибуття з рядка у форматі "HH:mm"
      final timeStr = times.first.arrivalTimeFormatted;
      final parts = timeStr.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);

      // Створюємо час в українській часовій зоні
      var arrivalTime = DateTime(
        now.year,
        now.month,
        now.day,
        hours,
        minutes,
      );

      // Якщо час вже пройшов, додаємо 24 години
      if (arrivalTime.isBefore(now)) {
        arrivalTime = arrivalTime.add(const Duration(days: 1));
      }

      return arrivalTime;
    } else {
      // Якщо немає точного часу, використовуємо інтервал
      final intervalMinutes = int.tryParse(
        interval.replaceAll(RegExp(r'[^0-9]'), '')
      ) ?? 0;
      
      // Отримуємо поточний час в українській часовій зоні
      final ukraineOffset = () {
        final month = now.month;
        final isDST = month >= 3 && month <= 10;
        return Duration(hours: isDST ? 3 : 2);
      }();
      
      final ukraineNow = now.toUtc().add(ukraineOffset);
      return ukraineNow.add(Duration(minutes: intervalMinutes));
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