import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String currentText;

  const EditPostScreen({
    Key? key,
    required this.postId,
    required this.currentText,
  }) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _postController = TextEditingController();
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _postController.text = widget.currentText;
  }

  Future<void> _updatePost() async {
    if (_postController.text.trim().isEmpty) return;

    setState(() => _isEditing = true);

    try {
      await _database.child('posts/${widget.postId}').update({
        'text': _postController.text.trim(),
        'edited': true,
        'editedAt': ServerValue.timestamp,
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
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редагувати допис'),
        centerTitle: true,
        actions: [
          if (_isEditing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updatePost,
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