import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pppc_companion/pages/chat/contacts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:pppc_companion/pages/wall/post.dart';
import 'package:pppc_companion/pages/wall/create_post.dart';
import 'package:pppc_companion/pages/users/user.dart';
import 'package:pppc_companion/pages/wall/edit_post.dart';


class ContactPage extends StatefulWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();

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
      // Add FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
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
    );
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
    final text = post['text'] as String;
    final isLongText = text.length > 250;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                post: post,
                postId: postId,
              ),
            ),
          );
        },
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
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(
                          userId: post['authorId'],
                          userName: post['authorName'], 
                          userAvatar: post['authorAvatar'],
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: post['authorAvatar'].isNotEmpty
                              ? NetworkImage(post['authorAvatar'])
                              : const AssetImage('assets/img/noavatar.png') as ImageProvider,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['authorName'],
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Row(
                              children: [
                                Text(
                                  DateFormat('dd.MM.yyyy HH:mm').format(time),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (post['edited'] == true) ...[
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
                  const Spacer(),
                  if (post['authorId'] == _auth.currentUser!.uid)
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Редагувати'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPostScreen(
                                  postId: post['id'],
                                  currentText: post['text'],
                                ),
                              ),
                            );
                          },
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete),
                              SizedBox(width: 8),
                              Text('Видалити'),
                            ],
                          ),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Видалити допис'),
                                content: const Text('Ви впевнені, що хочете видалити цей допис?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Скасувати'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Видалити'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _database.child('posts/${post['id']}').remove();
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isLongText 
                    ? '${text.substring(0, 250)}...'
                    : text,
              ),
              if (isLongText)
                Text(
                  'Читати далі...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
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
                    width: 30,
                    child: Text(
                      rating.toString(),
                      textAlign: TextAlign.center,
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
                  const Spacer(),
                  StreamBuilder(
                    stream: _database
                        .child('posts/$postId/comments')
                        .onValue,
                    builder: (context, snapshot) {
                      final commentCount = snapshot.data?.snapshot.children.length ?? 0;
                      return Row(
                        children: [
                          const Icon(Icons.comment_outlined),
                          const SizedBox(width: 4),
                            SizedBox(
                            width: 30,
                            child: Text(
                              commentCount.toString(),
                              textAlign: TextAlign.center,
                            ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}