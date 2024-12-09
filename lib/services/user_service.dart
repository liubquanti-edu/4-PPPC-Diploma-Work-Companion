import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<String?> getUserName() {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;
      
      final doc = await _firestore
          .collection('students')
          .doc(user.uid)
          .get();
          
      return doc.data()?['name'] as String?;
    });
  }

  Stream<DocumentSnapshot> getUserData() {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) throw Exception('User not authenticated');
      return await _firestore.collection('students').doc(user.uid).get();
    });
  }

  Future<void> updateUserNickname(String newNickname) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('students')
          .doc(user.uid)
          .update({'nickname': newNickname});
    }
  }
}