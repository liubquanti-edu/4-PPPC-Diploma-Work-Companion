import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:pppc_companion/pages/wall/post.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  UserProfilePage({
    Key? key,
    required this.userId,
    required this.userName, 
    required this.userAvatar,
  }) : super(key: key);

  final _auth = FirebaseAuth.instance;
  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();

  Future<void> _handleLike(String postId, bool currentLiked) async {
    final likesRef = database.child('posts/$postId/likes/${_auth.currentUser!.uid}');
    final ratingRef = database.child('posts/$postId/rating');
    
    if (currentLiked) {
      await likesRef.remove();
      await ratingRef.set(ServerValue.increment(-1));
    } else {
      await likesRef.set(true);
      await ratingRef.set(ServerValue.increment(1));
    }
  }

  Future<void> _handleDislike(String postId, bool currentDisliked) async {
    final dislikesRef = database.child('posts/$postId/dislikes/${_auth.currentUser!.uid}');
    final ratingRef = database.child('posts/$postId/rating');

    if (currentDisliked) {
      await dislikesRef.remove();
      await ratingRef.set(ServerValue.increment(1));
    } else {
      await dislikesRef.set(true);
      await ratingRef.set(ServerValue.increment(-1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
    ).ref();

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: userAvatar.isNotEmpty
                        ? NetworkImage(userAvatar)
                        : const AssetImage('assets/img/noavatar.png') as ImageProvider,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 22),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .doc(userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      return Column(
                        children: [
                          Text(
                            '@${userData?['nickname'] ?? ''}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Студент • ${userData?['group'] ?? ''}-та група',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Text(
                            'Інженерія програмного забезпечення',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.numbers_rounded, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10.0),
                        Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 10.0),
                        Icon(Icons.local_police_rounded, color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // User Posts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Дописи користувача',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder(
                    stream: database
                        .child('posts')
                        .orderByChild('authorId')
                        .equalTo(userId)
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
                          post['id'] = key;
                          posts.add(post);
                        });
                        
                        posts.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
                      }

                      if (posts.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Користувач ще не опублікував жодного допису'),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final time = DateTime.fromMillisecondsSinceEpoch(post['timestamp'] as int);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(
                                    post: post,
                                    postId: post['id'],
                                  ),
                                ),
                              ),
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
                                    Text(
                                      post['text'],
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (post['text'].length > 250) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Читати далі...',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        StreamBuilder<DatabaseEvent>(
                                          stream: database.child('posts/${post['id']}/likes/${_auth.currentUser!.uid}').onValue,
                                          builder: (context, snapshot) {
                                            final isLiked = snapshot.data?.snapshot.value == true;
                                            return IconButton(
                                              icon: Icon(
                                                isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                                color: isLiked ? Theme.of(context).colorScheme.primary : null,
                                              ),
                                              onPressed: () => _handleLike(post['id'], isLiked),
                                            );
                                          },
                                        ),
                                        StreamBuilder<DatabaseEvent>(
                                          stream: database.child('posts/${post['id']}/rating').onValue,
                                          builder: (context, snapshot) {
                                            final rating = (snapshot.data?.snapshot.value as int?) ?? 0;
                                            return SizedBox(
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
                                            );
                                          },
                                        ),
                                        StreamBuilder<DatabaseEvent>(
                                          stream: database.child('posts/${post['id']}/dislikes/${_auth.currentUser!.uid}').onValue,
                                          builder: (context, snapshot) {
                                            final isDisliked = snapshot.data?.snapshot.value == true;
                                            return IconButton(
                                              icon: Icon(
                                                isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                                color: isDisliked ? Theme.of(context).colorScheme.primary : null,
                                              ),
                                              onPressed: () => _handleDislike(post['id'], isDisliked),
                                            );
                                          },
                                        ),
                                        const Spacer(),
                                        StreamBuilder<DatabaseEvent>(
                                          stream: database.child('posts/${post['id']}/comments').onValue,
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
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}