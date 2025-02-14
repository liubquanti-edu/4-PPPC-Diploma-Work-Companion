import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transport.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class TransportProvider with ChangeNotifier {
  List<TransportSchedule>? _schedules;
  bool _isLoading = false;
  Timer? _timer;
  final SharedPreferences _prefs;
  
  List<TransportSchedule>? get schedules => _schedules;
  bool get isLoading => _isLoading;

  TransportProvider(this._prefs) {
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

      final stopId = _prefs.getString('stopId');
      if (stopId == null) {
        _schedules = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('https://gps.easyway.info/api/city/poltava/lang/ua/stop/$stopId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok') {
          final routes = (data['data']['routes'] as List)
              .map((route) => TransportSchedule.fromJson(route))
              .toList();
          
          routes.sort(TransportSchedule.compareByArrivalTime);
          
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