import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pppc_companion/pages/users/user.dart';
import '/models/avatars.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final String postId;

  const PostDetailScreen({
    Key? key, 
    required this.post,
    required this.postId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _commentsKey = GlobalKey();
  bool _showScrollToComments = true;
  bool _showScrollToTop = false;
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();
  final _firestore = FirebaseFirestore.instance;
  bool _isCommenting = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _showScrollToComments = _scrollController.offset < 600;
        _showScrollToTop = _scrollController.offset >= 600;
      });
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isCommenting = true);

    try {
      final userDoc = await _firestore
          .collection('students')
          .doc(_auth.currentUser!.uid)
          .get();
      
      final userData = userDoc.data()!;
      
      final commentRef = _database
          .child('posts/${widget.postId}/comments')
          .push();
          
      await commentRef.set({
        'text': _commentController.text.trim(),
        'authorId': _auth.currentUser!.uid,
        'authorName': '${userData['surname']} ${userData['name']}',
        'authorAvatar': userData['avatar'] ?? '',
        'timestamp': ServerValue.timestamp,
      });

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e'))
      );
    } finally {
      setState(() => _isCommenting = false);
    }
  }

  void _scrollToComments() {
    final RenderBox commentsBox = _commentsKey.currentContext?.findRenderObject() as RenderBox;
    final position = commentsBox.localToGlobal(Offset.zero);
    
    _scrollController.animateTo(
      position.dy - AppBar().preferredSize.height - 16,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Допис'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPost(),
                      Divider(height: 32, key: _commentsKey),
                      Container(
                        child: const Text('Коментарі:'),
                      ),
                      const SizedBox(height: 16),
                      _buildComments(),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(),
            ],
          ),
          Positioned(
            right: 15,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showScrollToComments)
                  FloatingActionButton(
                    heroTag: 'scrollToComments',
                    mini: true, 
                    onPressed: _scrollToComments,
                    child: const Icon(Icons.comment),
                  ),
                if (_showScrollToTop) ...[
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'scrollToTop',
                    mini: true,
                    onPressed: _scrollToTop,
                    child: const Icon(Icons.arrow_upward),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPost() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: widget.post['authorId'],
                  ),
                ),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    userId: widget.post['authorId'],
                    radius: 20,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post['authorName'],
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm')
                              .format(DateTime.fromMillisecondsSinceEpoch(
                                widget.post['timestamp']
                              )),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (widget.post['edited'] == true) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(widget.post['text']),
      ],
    );
  }

  Widget _buildComments() {
    return StreamBuilder(
      stream: _database
          .child('posts/${widget.postId}/comments')
          .orderByChild('timestamp')
          .onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Помилка: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = <Map<String, dynamic>>[];
        if (snapshot.data?.snapshot.value != null) {
          final commentsData = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map
          );
          
          commentsData.forEach((key, value) {
            comments.add(Map<String, dynamic>.from(value));
          });
          
          comments.sort((a, b) => 
            (b['timestamp'] as int).compareTo(a['timestamp'] as int));
        }

        if (comments.isEmpty) {
          return const Center(
            child: Text('Поки немає коментарів')
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(
                              userId: comment['authorId'],
                            ),
                          ),
                          ),
                          child: Row(
                            children: [
                            UserAvatar(
                              userId: comment['authorId'],
                              radius: 16,
                            ),
                            const SizedBox(width: 8),
                              Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                comment['authorName'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                DateFormat('dd.MM.yyyy HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                  comment['timestamp']
                                  )
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Text(comment['text']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Написати коментар...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          if (_isCommenting)
            const CircularProgressIndicator()
          else
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _addComment,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}