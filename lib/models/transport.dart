import 'package:intl/intl.dart';

class TransportSchedule {
  final int routeId;
  final String routeName;
  final String transportName;
  final String directionName;
  final String interval;
  final List<ScheduleTime> times;
  final bool worksNow; // Add new field

  TransportSchedule({
    required this.routeId,
    required this.routeName,
    required this.transportName,
    required this.directionName,
    required this.interval,
    required this.times,
    required this.worksNow, // Add to constructor
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
      worksNow: json['works_now'] == 1, // Convert to bool
    );
  }

  DateTime get nextArrivalTime {
    if (times.isNotEmpty) {
      // Use Unix timestamp directly
      return DateTime.fromMillisecondsSinceEpoch(times.first.arrivalTime * 1000);
    } else {
      // If no exact time, use interval logic
      final now = DateTime.now();
      final intervalMinutes = int.tryParse(
        interval.replaceAll(RegExp(r'[^0-9]'), '')
      ) ?? 0;
      
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
    // First compare by works_now status
    if (a.worksNow != b.worksNow) {
      return a.worksNow ? -1 : 1; // Working transport goes first
    }
    // If both have same works_now status, compare by arrival time
    return a.nextArrivalTime.compareTo(b.nextArrivalTime);
  }
}

class ScheduleTime {
  final String arrivalTimeFormatted;
  final String? bortNumber;
  final int arrivalTime;

  ScheduleTime({
    required this.arrivalTimeFormatted,
    required this.arrivalTime,
    this.bortNumber,
  });

  // Add method to get localized time
  String get localTimeFormatted {
    final ukraineTime = DateTime.fromMillisecondsSinceEpoch(arrivalTime * 1000);
    return DateFormat('HH:mm').format(ukraineTime.toLocal());
  }

  factory ScheduleTime.fromJson(Map<String, dynamic> json) {
    return ScheduleTime(
      arrivalTimeFormatted: json['arrival_time_formatted'],
      arrivalTime: json['arrival_time'],
      bortNumber: json['bort_number'],
    );
  }
}