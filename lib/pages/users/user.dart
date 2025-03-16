import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:pppc_companion/pages/wall/post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pppc_companion/pages/wall/edit_post.dart';
import '/models/avatars.dart';
import '../settings/edit_profile.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pppc_companion/services/badges_service.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;
  final bool isCurrentUser;

  UserProfilePage({
    super.key,
    required this.userId,
    this.isCurrentUser = false,
  });

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
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        
        return Scaffold(
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      UserAvatar(
                        userId: userId,
                        radius: 80,
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        '${userData['surname']} ${userData['name']}',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isCurrentUser)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.onSecondary,
                                foregroundColor: Theme.of(context).colorScheme.primary,
                              ),
                              icon: const Icon(Icons.edit),
                              label: const Text('Редагувати профіль'),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(
                                      currentNickname: userData['nickname'] ?? '',
                                      currentAvatar: userData['avatar'] ?? '',
                                      userData: userData,
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (!isCurrentUser) ...[
                            if (userData['contactnumber']?.isNotEmpty ?? false)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.onSecondary,
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                ),
                                icon: const Icon(Icons.phone),
                                label: const Text('Телефон'),
                                onPressed: () async {
                                  final Uri url = Uri.parse('tel:${userData['contactnumber']}');
                                  if (!await launchUrl(url)) {
                                    throw Exception('Could not launch $url');
                                  }
                                },
                              ),
                            if (userData['contactemail']?.isNotEmpty ?? false) ...[
                              if (userData['contactnumber']?.isNotEmpty ?? false)
                                const SizedBox(width: 10),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.onSecondary,
                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                ),
                                icon: const Icon(Icons.email),
                                label: const Text('Пошта'),
                                onPressed: () async {
                                  final Uri url = Uri.parse('mailto:${userData['contactemail']}');
                                  if (!await launchUrl(url)) {
                                    throw Exception('Could not launch $url');
                                  }
                                },
                              ),
                            ],
                          ],
                        ],
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('students')
                            .doc(userId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const SizedBox.shrink();
                          }

                          final userData = snapshot.data!.data() as Map<String, dynamic>;
                          final badges = (userData['badges'] as List?)?.cast<String>() ?? [];

                          if (badges.isEmpty) {
                            return Divider(
                              color: Theme.of(context).colorScheme.primary,
                              thickness: 2,
                            );
                          }

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSecondary,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2.0,
                              ),
                            ),
                            child: Center(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: badges.map((badgeId) {
                                  return FutureBuilder<Map<String, dynamic>?>(
                                    future: BadgeService().getBadge(badgeId),
                                    builder: (context, badgeSnapshot) {
                                      if (!badgeSnapshot.hasData) return const SizedBox.shrink();
                                      
                                      final badge = badgeSnapshot.data!;
                                      return InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              icon: SvgPicture.asset(
                                                'assets/badges/${badge['logo']}.svg',
                                                colorFilter: ColorFilter.mode(
                                                  Theme.of(context).colorScheme.primary,
                                                  BlendMode.srcIn
                                                ),
                                                height: 48,
                                                width: 48,
                                              ),
                                              title: Text(
                                                badge['name'],
                                                textAlign: TextAlign.center,
                                              ),
                                              content: Text(
                                                badge['description'],
                                                textAlign: TextAlign.center,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Закрити'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: Tooltip(
                                          message: '${badge['name']}\n${badge['description']}',
                                          textAlign: TextAlign.center,
                                          child: SvgPicture.asset(
                                            'assets/badges/${badge['logo']}.svg',
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context).colorScheme.primary,
                                              BlendMode.srcIn
                                            ),
                                            height: 24,
                                            width: 24,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Дописи користувача',
                        style: Theme.of(context).textTheme.titleMedium ,
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
                                            UserAvatar(
                                              userId: post['authorId'],
                                              radius: 20,
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
                                            ),
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
                                                        await database.child('posts/${post['id']}').remove();
                                                      }
                                                    },
                                                  ),
                                                ],
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
                                                      ? Color(0xff9ed58b)
                                                      : rating < 0 
                                                        ? Color(0xFFFE9F9F)
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
      },
    );
  }
}