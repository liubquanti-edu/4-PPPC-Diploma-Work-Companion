//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wifi.dart';

class WiFiFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _wifiCollection = 
      FirebaseFirestore.instance.collection('wifi');
  Stream<List<WiFiNetwork>> getWiFiNetworks() {
    return _wifiCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return WiFiNetwork.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
  Future<void> addWiFiNetwork(WiFiNetwork network) {
    return _wifiCollection.add(network.toMap());
  }

  Future<void> updateWiFiNetwork(WiFiNetwork network) {
    return _wifiCollection.doc(network.id).update(network.toMap());
  }

  Future<void> deleteWiFiNetwork(String id) {
    return _wifiCollection.doc(id).delete();
  }
}