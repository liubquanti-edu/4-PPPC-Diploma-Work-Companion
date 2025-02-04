import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:pppc_companion/pages/config/api.dart';

class AlertProvider with ChangeNotifier {
  bool isLoading = true;
  AlertInfo alertInfo = AlertInfo(status: 'N');
  Timer? _timer;

  AlertProvider() {
    fetchAlertStatus();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchAlertStatus());
  }

  Future<void> fetchAlertStatus() async {
    try {
      isLoading = true;
      notifyListeners();
      
      final response = await http.get(
        Uri.parse('https://api.alerts.in.ua/v1/alerts/active.json'),
        headers: {'Authorization': 'Bearer ${ApiConfig.alertsApiKey}'}
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alerts = data['alerts'] as List;
        
        final poltavaAlert = alerts.firstWhere(
          (alert) => alert['location_uid'] == '19' && alert['alert_type'] == 'air_raid',
          orElse: () => null
        );

        if (poltavaAlert != null) {
          alertInfo = AlertInfo(
            status: 'A',
            startTime: DateTime.parse(poltavaAlert['started_at'])
          );
        } else {
          alertInfo = AlertInfo(status: 'N');
        }
      }
    } catch (e) {
      debugPrint('Error fetching alert status: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class AlertInfo {
  final String status;
  final DateTime? startTime;

  AlertInfo({required this.status, this.startTime});
}