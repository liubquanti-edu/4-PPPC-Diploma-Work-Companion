import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pppc_companion/pages/chat/contacts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();
  
  final _postController = TextEditingController();
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
        'rating': 0, // Initialize rating counter
      });

      _postController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e'))
      );
    } finally {
      setState(() => _isPosting = false);
    }
  }

  Future<void> _handleLike(String postId, bool currentLiked, bool currentDisliked) async {
    final userId = _auth.currentUser!.uid;
    final likesRef = _database.child('posts/$postId/likes/$userId');
    final dislikesRef = _database.child('posts/$postId/dislikes/$userId');
    final ratingRef = _database.child('posts/$postId/rating');

    if (currentLiked) {
      // Remove like
      await likesRef.remove();
      await ratingRef.set(ServerValue.increment(-1));
    } else {
      // Add like and remove dislike if exists
      await likesRef.set(true);
      await ratingRef.set(ServerValue.increment(1));
      if (currentDisliked) {
        await dislikesRef.remove();
        await ratingRef.set(ServerValue.increment(1)); // +1 for removing dislike
      }
    }
  }

  Future<void> _handleDislike(String postId, bool currentLiked, bool currentDisliked) async {
    final userId = _auth.currentUser!.uid;
    final likesRef = _database.child('posts/$postId/likes/$userId');
    final dislikesRef = _database.child('posts/$postId/dislikes/$userId');
    final ratingRef = _database.child('posts/$postId/rating');

    if (currentDisliked) {
      // Remove dislike
      await dislikesRef.remove();
      await ratingRef.set(ServerValue.increment(1));
    } else {
      // Add dislike and remove like if exists
      await dislikesRef.set(true);
      await ratingRef.set(ServerValue.increment(-1));
      if (currentLiked) {
        await likesRef.remove();
        await ratingRef.set(ServerValue.increment(-1)); // -1 for removing like
      }
    }
  }

  Widget _buildPost(Map<String, dynamic> post, String postId, DateTime time) {
    final userId = _auth.currentUser!.uid;
    final rating = post['rating'] as int? ?? 0;
    final isLiked = (post['likes'] as Map?)?.containsKey(userId) ?? false;
    final isDisliked = (post['dislikes'] as Map?)?.containsKey(userId) ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post['authorAvatar'].isNotEmpty
                      ? NetworkImage(post['authorAvatar'])
                      : const AssetImage('assets/img/noavatar.png') 
                          as ImageProvider,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['authorName'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(time),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post['text']),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked ? Theme.of(context).colorScheme.primary : null,
                  ),
                  onPressed: () => _handleLike(postId, isLiked, isDisliked),
                ),
                SizedBox(
                  width: 20,
                    child: Text(
                    textAlign: TextAlign.center,
                    rating.toString(),
                    style: TextStyle(
                      color: rating > 0 
                          ? Colors.green 
                          : rating < 0 
                              ? Colors.red 
                              : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                    color: isDisliked ? Theme.of(context).colorScheme.primary : null,
                  ),
                  onPressed: () => _handleDislike(postId, isLiked, isDisliked),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Стіна'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                    maxLength: 5000,
                    controller: _postController,
                    decoration: const InputDecoration(
                      hintText: 'Написати допис...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                if (_isPosting)
                  const CircularProgressIndicator()
                else
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _createPost,
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _database
                  .child('posts')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = <Map<String, dynamic>>[];
                if (snapshot.data?.snapshot.value != null) {
                  final postsData = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map
                  );
                  
                  postsData.forEach((key, value) {
                    final post = Map<String, dynamic>.from(value);
                    post['id'] = key; // Store post ID
                    posts.add(post);
                  });
                  
                  posts.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
                }

                if (posts.isEmpty) {
                  return const Center(child: Text('Поки немає дописів'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final time = DateTime.fromMillisecondsSinceEpoch(post['timestamp'] as int);
                    return _buildPost(post, post['id'], time);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}