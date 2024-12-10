import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot?> findStudentByEmail(String email) async {
    try {
      var snapshot = await _firestore
          .collection('students')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first;
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentSnapshot?> findPersonByEmail(String email) async {
    try {
      var snapshot = await _firestore
          .collection('people')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> registerWithEmailAndPassword(String email, String password, Map<String, dynamic> personData) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );

      await _firestore.collection('students').doc(credential.user!.uid).set({
        ...personData,
        'email': email,
        'createdat': FieldValue.serverTimestamp(),
        'nickname': email.substring(0, email.indexOf('@')),
      });

      return credential;
    } catch (e) {
      try {
        await credential?.user?.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}