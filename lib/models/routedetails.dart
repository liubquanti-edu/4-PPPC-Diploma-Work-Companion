//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:intl/intl.dart';

class RouteDetails {
  final List<RouteDirection> directions;

  RouteDetails({required this.directions});

  factory RouteDetails.fromJson(Map<String, dynamic> json) {
    final directionsData = json['data']['directions'] as List;
    return RouteDetails(
      directions: directionsData.map((dir) => RouteDirection.fromJson(dir)).toList(),
    );
  }
}

class RouteDirection {
  final int calendarTripId;
  final int calendarId;
  final int tripId;
  final List<RouteStop> stops;

  RouteDirection({
    required this.calendarTripId,
    required this.calendarId,
    required this.tripId,
    required this.stops,
  });

  factory RouteDirection.fromJson(Map<String, dynamic> json) {
    return RouteDirection(
      calendarTripId: json['calendar_trip_id'],
      calendarId: json['calendar_id'],
      tripId: json['trip_id'],
      stops: (json['stops'] as List).map((stop) => RouteStop.fromJson(stop)).toList(),
    );
  }
}

class RouteStop {
  final int stopId;
  final String stopName;
  final List<StopTime> times;

  RouteStop({
    required this.stopId,
    required this.stopName,
    required this.times,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      stopId: json['stop_id'],
      stopName: json['stop_name'] ?? 'Невідома зупинка',
      times: (json['times'] as List).map((time) => StopTime.fromJson(time)).toList(),
    );
  }
}

class StopTime {
  final String source;
  final String arrivalTimeFormatted;
  final int arrivalTime;
  final String? vehicleNumber;

  StopTime({
    required this.source,
    required this.arrivalTimeFormatted,
    required this.arrivalTime,
    this.vehicleNumber,
  });

  String get localTimeFormatted {
    final ukraineTime = DateTime.fromMillisecondsSinceEpoch(arrivalTime * 1000);
    return DateFormat('HH:mm').format(ukraineTime.toLocal());
  }

  factory StopTime.fromJson(Map<String, dynamic> json) {
    return StopTime(
      source: json['source'],
      arrivalTimeFormatted: json['arrival_time_formatted'],
      arrivalTime: json['arrival_time'],
      vehicleNumber: json['vehicle_number'],
    );
  }
}