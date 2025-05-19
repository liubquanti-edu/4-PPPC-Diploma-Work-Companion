//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadAvatar(File imageFile, String userId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      
      final Reference storageRef = _storage
          .ref()
          .child('avatars')
          .child(userId)
          .child(fileName);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'timestamp': timestamp.toString(),
        },
      );

      final uploadTask = await storageRef.putFile(imageFile, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      debugPrint('Avatar uploaded successfully to: $downloadUrl');
      return downloadUrl;

    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage Error: ${e.code} - ${e.message}');
      throw Exception('Помилка завантаження: ${e.message}');
    } catch (e) {
      debugPrint('Upload Error: $e');
      throw Exception('Помилка завантаження аватара');
    }
  }

  static Future<void> deleteOldAvatar(String oldAvatarUrl) async {
    if (oldAvatarUrl.isEmpty) return;
    
    try {
      final ref = FirebaseStorage.instance.refFromURL(oldAvatarUrl);
      await ref.delete();
      debugPrint('Avatar deleted successfully from Storage: $oldAvatarUrl');
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage Error: ${e.code} - ${e.message}');
      if (e.code != 'object-not-found') {
        throw Exception('Помилка видалення аватара зі сховища');
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw Exception('Помилка видалення аватара');
    }
  }
}