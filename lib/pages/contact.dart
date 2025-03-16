import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pppc_companion/pages/chat/contacts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:pppc_companion/pages/wall/post.dart';
import 'package:pppc_companion/pages/wall/create_post.dart';
import 'package:pppc_companion/pages/users/user.dart';
import 'package:pppc_companion/pages/wall/edit_post.dart';
import '/models/avatars.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pppc_companion/providers/theme_provider.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    final defaultTab = Provider.of<ThemeProvider>(context, listen: false).defaultContactTab;
    _tabController = TabController(initialIndex: defaultTab, length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Стіна'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 300));
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatsPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Потік'),
            Tab(text: 'Стежу'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Future.delayed(const Duration(milliseconds: 300));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllPostsTab(),
          _FollowingPostsTab(),
        ],
      ),
    );
  }
}

class _AllPostsTab extends StatefulWidget {
  @override
  __AllPostsTabState createState() => __AllPostsTabState();
}

class __AllPostsTabState extends State<_AllPostsTab> with AutomaticKeepAliveClientMixin {
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder(
      key: const ValueKey('allPosts'),
      stream: _database.child('posts').orderByChild('timestamp').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data?.snapshot.value == null) {
          return const Center(child: Text('Поки немає дописів'));
        }

        final posts = <Map<String, dynamic>>[];
        final postsData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        
        postsData.forEach((key, value) {
          final post = Map<String, dynamic>.from(value);
          post['id'] = key;
          posts.add(post);
        });
        
        posts.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

        return ListView.builder(
          key: const PageStorageKey('allPostsList'),
          padding: const EdgeInsets.all(20),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final time = DateTime.fromMillisecondsSinceEpoch(post['timestamp'] as int);
            return _buildPost(post, post['id'], time);
          },
        );
      },
    );
  }

  Widget _buildPost(Map<String, dynamic> post, String postId, DateTime time) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final rating = (post['rating'] as int?) ?? 0;
    final isLiked = (post['likes'] as Map?)?.containsKey(userId) ?? false;
    final isDisliked = (post['dislikes'] as Map?)?.containsKey(userId) ?? false;
    final text = post['text'].replaceAll(RegExp(r'\n{3,}'), '\n\n') as String;
    final isLongText = text.length > 250;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 300));
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
        child: Ink(
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
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(60),
                    ),
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 300));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            userId: post['authorId'],
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        UserAvatar(
                          userId: post['authorId'],
                          radius: 20,
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
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (post['authorId'] == FirebaseAuth.instance.currentUser!.uid)
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
                isLongText ? '${text.substring(0, 250)}...' : text,
                maxLines: isLongText ? 10 : null,
                overflow: isLongText ? TextOverflow.ellipsis : null,
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
                          ? Color(0xff9ed58b)
                          : rating < 0 
                            ? Color(0xFFFE9F9F)
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

  Future<void> _handleLike(String postId, bool currentLiked, bool currentDisliked) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final likesRef = _database.child('posts/$postId/likes/$userId');
    final dislikesRef = _database.child('posts/$postId/dislikes/$userId');
    final ratingRef = _database.child('posts/$postId/rating');

    if (currentLiked) {
      await likesRef.remove();
      await ratingRef.set(ServerValue.increment(-1));
    } else {
      await likesRef.set(true);
      await ratingRef.set(ServerValue.increment(1));
      if (currentDisliked) {
        await dislikesRef.remove();
        await ratingRef.set(ServerValue.increment(1));
      }
    }
  }

  Future<void> _handleDislike(String postId, bool currentLiked, bool currentDisliked) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final likesRef = _database.child('posts/$postId/likes/$userId');
    final dislikesRef = _database.child('posts/$postId/dislikes/$userId');
    final ratingRef = _database.child('posts/$postId/rating');

    if (currentDisliked) {
      await dislikesRef.remove();
      await ratingRef.set(ServerValue.increment(1));
    } else {
      await dislikesRef.set(true);
      await ratingRef.set(ServerValue.increment(-1));
      if (currentLiked) {
        await likesRef.remove();
        await ratingRef.set(ServerValue.increment(-1));
      }
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class _FollowingPostsTab extends StatefulWidget {
  @override
  __FollowingPostsTabState createState() => __FollowingPostsTabState();
}

class __FollowingPostsTabState extends State<_FollowingPostsTab> with AutomaticKeepAliveClientMixin {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<DocumentSnapshot>(
      key: const ValueKey('followingPosts'),
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(_auth.currentUser!.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final following = (userData['following'] as List?)?.cast<String>() ?? [];
        final followingWithSelf = [...following, _auth.currentUser!.uid];

        if (followingWithSelf.isEmpty) {
          return const Center(child: Text('Ви ще ні за ким не стежите'));
        }

        return StreamBuilder(
          stream: _database.child('posts').orderByChild('timestamp').onValue,
          builder: (context, postsSnapshot) {
            if (!postsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (postsSnapshot.data?.snapshot.value == null) {
              return const Center(child: Text('Поки немає дописів'));
            }

            final posts = <Map<String, dynamic>>[];
            final postsData = Map<String, dynamic>.from(postsSnapshot.data!.snapshot.value as Map);
            
            postsData.forEach((key, value) {
              final post = Map<String, dynamic>.from(value);
              if (followingWithSelf.contains(post['authorId'])) {
                post['id'] = key;
                posts.add(post);
              }
            });

            posts.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

            if (posts.isEmpty) {
              return const Center(
                child: Text('Поки немає дописів від користувачів, за якими ви стежите')
              );
            }

            return ListView.builder(
              key: const PageStorageKey('followingPostsList'),
              padding: const EdgeInsets.all(20),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final time = DateTime.fromMillisecondsSinceEpoch(post['timestamp'] as int);
                return _buildPost(post, post['id'], time);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPost(Map<String, dynamic> post, String postId, DateTime time) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final rating = (post['rating'] as int?) ?? 0;
    final isLiked = (post['likes'] as Map?)?.containsKey(userId) ?? false;
    final isDisliked = (post['dislikes'] as Map?)?.containsKey(userId) ?? false;
    final text = post['text'] as String;
    final isLongText = text.length > 250;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 300));
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
        child: Ink(
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
                    customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(60),
                    ),
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 300));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            userId: post['authorId'],
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        UserAvatar(
                          userId: post['authorId'],
                          radius: 20,
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
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (post['authorId'] == FirebaseAuth.instance.currentUser!.uid)
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
                isLongText ? '${text.substring(0, 250)}...' : text,
                maxLines: isLongText ? 10 : null,
                overflow: isLongText ? TextOverflow.ellipsis : null,
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
                          ? Color(0xff9ed58b)
                          : rating < 0 
                            ? Color(0xFFFE9F9F)
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

  Future<void> _handleLike(String postId, bool currentLiked, bool currentDisliked) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final likesRef = _database.child('posts/$postId/likes/$userId');
    final dislikesRef = _database.child('posts/$postId/dislikes/$userId');
    final ratingRef = _database.child('posts/$postId/rating');

    if (currentLiked) {
      await likesRef.remove();
      await ratingRef.set(ServerValue.increment(-1));
    } else {
      await likesRef.set(true);
      await ratingRef.set(ServerValue.increment(1));
      if (currentDisliked) {
        await dislikesRef.remove();
        await ratingRef.set(ServerValue.increment(1));
      }
    }
  }

  Future<void> _handleDislike(String postId, bool currentLiked, bool currentDisliked) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final likesRef = _database.child('posts/$postId/likes/$userId');
    final dislikesRef = _database.child('posts/$postId/dislikes/$userId');
    final ratingRef = _database.child('posts/$postId/rating');

    if (currentDisliked) {
      await dislikesRef.remove();
      await ratingRef.set(ServerValue.increment(1));
    } else {
      await dislikesRef.set(true);
      await ratingRef.set(ServerValue.increment(-1));
      if (currentLiked) {
        await likesRef.remove();
        await ratingRef.set(ServerValue.increment(-1));
      }
    }
  }

  @override
  bool get wantKeepAlive => true;
}