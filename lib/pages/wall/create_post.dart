import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _postController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();
  bool _isPosting = false;

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final userDoc = await _firestore
          .collection('students')
          .doc(_auth.currentUser!.uid)
          .get();
      
      final userData = userDoc.data()!;
      
      final newPostRef = _database.child('posts').push();
      await newPostRef.set({
        'text': _postController.text.trim(),
        'authorId': _auth.currentUser!.uid,
        'authorName': '${userData['surname']} ${userData['name']}',
        'authorAvatar': userData['avatar'] ?? '',
        'timestamp': ServerValue.timestamp,
        'rating': 0,
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'))
        );
      }
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новий допис'),
        actions: [
          if (_isPosting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _createPost,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _postController,
          maxLength: 5000,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Що у вас нового?',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.newline,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}