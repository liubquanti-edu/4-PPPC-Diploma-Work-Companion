import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeService {
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getBadge(String badgeId) async {
    final doc = await _firestore.collection('badges').doc(badgeId).get();
    return doc.data();
  }

  Future<void> awardBadgeToUser(String userId, String badgeId) async {
    await _firestore.collection('students').doc(userId).update({
      'badges': FieldValue.arrayUnion([badgeId])
    });
  }
}