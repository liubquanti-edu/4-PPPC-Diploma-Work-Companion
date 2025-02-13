import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transport.dart';
import 'dart:async';

class TransportProvider with ChangeNotifier {
  List<TransportSchedule>? _schedules;
  bool _isLoading = false;
  Timer? _timer;

  List<TransportSchedule>? get schedules => _schedules;
  bool get isLoading => _isLoading;

  TransportProvider() {
    _initScheduleUpdates();
  }

  void _initScheduleUpdates() {
    fetchSchedule(); // Initial fetch
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => fetchSchedule());
  }

  Future<void> fetchSchedule() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse('https://gps.easyway.info/api/city/poltava/lang/ua/stop/80'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          final routes = (data['data']['routes'] as List)
              .map((route) => TransportSchedule.fromJson(route))
              .toList();
          
          routes.sort((a, b) => a.nextArrivalTime.compareTo(b.nextArrivalTime));
          
          _schedules = routes;
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}