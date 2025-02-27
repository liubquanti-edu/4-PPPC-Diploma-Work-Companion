import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

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
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore
            .collection('students')
            .doc(user.uid)
            .get();
        
        final currentAvatar = userDoc.data()?['avatar'] as String?;
        
        if (currentAvatar != null && currentAvatar.isNotEmpty) {
          await StorageService.deleteOldAvatar(currentAvatar);
        }
        
        await _firestore
            .collection('students')
            .doc(user.uid)
            .update({'avatar': FieldValue.delete()});
              
      } catch (e) {
        debugPrint('Error removing avatar: $e');
        throw Exception('Помилка видалення аватара: $e');
      }
    }
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

  Future<void> updateUserContacts(String? phone, String? email) async {
    final user = _auth.currentUser;
    if (user != null) {
      final updates = <String, dynamic>{};
      
      if (phone?.isEmpty ?? true) {
        updates['contactnumber'] = FieldValue.delete();
      } else {
        updates['contactnumber'] = phone;
      }
      
      if (email?.isEmpty ?? true) {
        updates['contactemail'] = FieldValue.delete();
      } else {
        updates['contactemail'] = email;
      }
      
      if (updates.isNotEmpty) {
        await _firestore
            .collection('students')
            .doc(user.uid)
            .update(updates);
      }
    }
  }
}