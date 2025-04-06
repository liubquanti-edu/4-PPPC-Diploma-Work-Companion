import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class AlertProvider with ChangeNotifier {
  bool isLoading = true;
  AlertInfo alertInfo = AlertInfo(status: 'N');
  StreamSubscription? _alertSubscription;

  AlertProvider() {
    subscribeToAlerts();
  }

  void subscribeToAlerts() {
    isLoading = true;
    notifyListeners();

    final alertRef = FirebaseFirestore.instance.collection('info').doc('alert');
    _alertSubscription = alertRef.snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          
          if (data['status'] == 'A') {
            alertInfo = AlertInfo(
              status: 'A',
              startTime: data['startTime'] != null 
                ? (data['startTime'] is Timestamp 
                  ? (data['startTime'] as Timestamp).toDate() 
                  : DateTime.parse(data['startTime']))
                : null
            );
          } else {
            alertInfo = AlertInfo(status: 'N');
          }
          
          isLoading = false;
          notifyListeners();
        }
      },
      onError: (e) {
        debugPrint('Error getting alert data: $e');
        isLoading = false;
        notifyListeners();
      }
    );
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }
}

class AlertInfo {
  final String status;
  final DateTime? startTime;

  AlertInfo({required this.status, this.startTime});
}