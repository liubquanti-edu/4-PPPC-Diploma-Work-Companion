import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wifi.dart';

class WiFiFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _wifiCollection = 
      FirebaseFirestore.instance.collection('wifi');

  // Get all WiFi networks
  Stream<List<WiFiNetwork>> getWiFiNetworks() {
    return _wifiCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return WiFiNetwork.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Add a new WiFi network
  Future<void> addWiFiNetwork(WiFiNetwork network) {
    return _wifiCollection.add(network.toMap());
  }

  // Update a WiFi network
  Future<void> updateWiFiNetwork(WiFiNetwork network) {
    return _wifiCollection.doc(network.id).update(network.toMap());
  }

  // Delete a WiFi network
  Future<void> deleteWiFiNetwork(String id) {
    return _wifiCollection.doc(id).delete();
  }
}