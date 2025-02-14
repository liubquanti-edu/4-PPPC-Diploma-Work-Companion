import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transport.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class TransportProvider with ChangeNotifier {
  Map<String, List<TransportSchedule>> _schedulesByStop = {};
  Map<String, bool> _loadingStates = {};
  Timer? _timer;
  final SharedPreferences _prefs;
  
  Map<String, List<TransportSchedule>> get schedulesByStop => _schedulesByStop;
  Map<String, bool> get loadingStates => _loadingStates;

  TransportProvider(this._prefs) {
    _initScheduleUpdates();
  }

  void _initScheduleUpdates() {
    fetchAllSchedules();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => fetchAllSchedules());
  }

  Future<void> fetchAllSchedules() async {
    final stopIds = _prefs.getStringList('stopIds') ?? [];
    for (final stopId in stopIds) {
      await fetchScheduleForStop(stopId);
    }
  }

  Future<void> fetchScheduleForStop(String stopId) async {
    try {
      _loadingStates[stopId] = true;
      notifyListeners();

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
          
          _schedulesByStop[stopId] = routes;
        }
      }
    } catch (e) {
      debugPrint('Error fetching schedule for stop $stopId: $e');
    } finally {
      _loadingStates[stopId] = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}