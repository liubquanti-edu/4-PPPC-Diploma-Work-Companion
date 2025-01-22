import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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

  Future<bool> isNicknameAvailable(String nickname) async {
    final snapshot = await _firestore
        .collection('students')
        .where('nickname', isEqualTo: nickname)
        .get();
    
    if (snapshot.docs.length == 1) {
      return snapshot.docs.first.id == _auth.currentUser?.uid;
    }
    
    return snapshot.docs.isEmpty;
  }

  Future<void> updateUserNickname(String newNickname) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (!await isNicknameAvailable(newNickname)) {
        throw Exception('Цей нікнейм вже зайнятий');
      }

      await _firestore
          .collection('students')
          .doc(user.uid)
          .update({'nickname': newNickname});
    }
  }

  Future<void> updateUserAvatar(String? avatarUrl) async {
    final user = _auth.currentUser;
    if (user != null) {
      if (avatarUrl == null) {
        await _firestore
            .collection('students')
            .doc(user.uid)
            .update({'avatar': FieldValue.delete()});
        return;
      }

      try {
        final response = await http.head(Uri.parse(avatarUrl));
        final contentType = response.headers['content-type'];
        if (contentType == null || !contentType.startsWith('image/')) {
          throw Exception('URL має вести на зображення');
        }

        await _firestore
            .collection('students')
            .doc(user.uid)
            .update({'avatar': avatarUrl});
      } catch (e) {
        throw Exception('Невірне посилання на зображення');
      }
    }
  }

  Future<void> removeUserAvatar() async {
    await updateUserAvatar(null);
  }

  Future<void> awardBadge(String userId, String name, String description, String logo) async {
    await FirebaseFirestore.instance
        .collection('students')
        .doc(userId)
        .collection('badges')
        .add({
          'name': name,
          'description': description,
          'logo': logo
        });
  }
}