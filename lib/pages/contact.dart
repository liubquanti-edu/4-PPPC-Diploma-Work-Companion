import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pppc_companion/pages/chat/chat.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

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

  String getChatRoomId(String userId1, String userId2) {
    final List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  // Update return type to include sender info
  Stream<Map<String, dynamic>?> getLastMessage(String recipientId) {
    final chatRoomId = getChatRoomId(_auth.currentUser!.uid, recipientId);
    return _database
        .child('chats/$chatRoomId/messages')
        .orderByChild('timestamp')
        .limitToLast(1)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return null;
      
      final messages = Map<String, dynamic>.from(event.snapshot.value as Map);
      final lastMessage = messages.values.first;
      return {
        'text': lastMessage['text'] as String?,
        'senderId': lastMessage['senderId'] as String?,
      };
    });
  }

  Future<String> _getCurrentUserGroup() async {
    final userDoc = await _firestore
        .collection('students')
        .doc(_auth.currentUser!.uid)
        .get();
    return userDoc.data()?['group']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<String>(
        future: _getCurrentUserGroup(),
        builder: (context, groupSnapshot) {
          if (!groupSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('students')
                .where('group', isEqualTo: int.tryParse(groupSnapshot.data ?? ''))
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Помилка: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs
                  .where((doc) => doc.id != _auth.currentUser!.uid)
                  .toList();

              if (users.isEmpty) {
                return const Center(
                  child: Text('У вашій групі поки немає інших студентів')
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              recipientId: users[index].id,
                              recipientName: '${userData['surname']} ${userData['name']}',
                              recipientAvatar: userData['avatar'] ?? '',
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
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundImage: userData['avatar'] != null
                                  ? NetworkImage(userData['avatar'])
                                  : const AssetImage('assets/img/noavatar.png') 
                                      as ImageProvider,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${userData['surname']} ${userData['name']}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  // In ListView.builder, update StreamBuilder:
                                  StreamBuilder<Map<String, dynamic>?>(
                                    stream: getLastMessage(users[index].id),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return Text(
                                          'Немає повідомлень',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                          ),
                                        );
                                      }

                                      final message = snapshot.data!;
                                      final isMe = message['senderId'] == _auth.currentUser!.uid;
                                      final prefix = isMe ? 'Ти: ' : '${userData['name']}: ';

                                      return Text(
                                        '$prefix${message['text'] ?? ''}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}