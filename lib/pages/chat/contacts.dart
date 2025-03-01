import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pppc_companion/pages/chat/chat.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '/models/avatars.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({Key? key}) : super(key: key);

  @override
  _ChatsPageState createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
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

  Stream<List<String>> getAllChatRoomIds() {
    return _database
        .child('chats')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];
      
      final chats = Map<String, dynamic>.from(event.snapshot.value as Map);
      return chats.keys
          .where((roomId) => roomId.split('_').contains(_auth.currentUser!.uid))
          .toList();
    });
  }

  String getOtherUserId(String chatRoomId) {
    final users = chatRoomId.split('_');
    return users[0] == _auth.currentUser!.uid ? users[1] : users[0];
  }

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
        'timestamp': lastMessage['timestamp'] as int?,
        'type': lastMessage['type'] as String?,
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

  Future<bool> hasMessages(String recipientId) async {
    final chatRoomId = getChatRoomId(_auth.currentUser!.uid, recipientId);
    final snapshot = await _database
        .child('chats/$chatRoomId/messages')
        .get();
    return snapshot.exists && snapshot.value != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чати'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
                showSearch(
                context: context,
                delegate: UserSearchDelegate(_firestore, context),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<String>>(
        stream: getAllChatRoomIds(),
        builder: (context, chatRoomsSnapshot) {
          if (!chatRoomsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<String>(
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
                builder: (context, groupMembersSnapshot) {
                  if (!groupMembersSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final chatRoomIds = chatRoomsSnapshot.data ?? [];
                  final groupMembers = groupMembersSnapshot.data!.docs
                      .where((doc) => doc.id != _auth.currentUser!.uid)
                      .toList();

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: Future.wait([
                      ...chatRoomIds.map((roomId) async {
                        final otherUserId = getOtherUserId(roomId);
                        final userDoc = await _firestore.collection('students').doc(otherUserId).get();
                        final lastMessage = await getLastMessage(otherUserId).first;
                        
                        return {
                          'doc': userDoc,
                          'hasChat': true,
                          'lastMessageTime': lastMessage?['timestamp'] ?? 0,
                        };
                      }),
                      ...groupMembers
                          .where((member) => !chatRoomIds.any((roomId) => 
                              roomId.split('_').contains(member.id)))
                          .map((member) async => {
                            'doc': member,
                            'hasChat': false,
                            'lastMessageTime': 0,
                          }),
                    ]),
                    builder: (context, usersSnapshot) {
                      if (!usersSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allUsers = usersSnapshot.data!;
                      
                      final activeChats = allUsers
                          .where((item) => item['hasChat'])
                          .toList()
                        ..sort((a, b) => (b['lastMessageTime'] as int)
                            .compareTo(a['lastMessageTime'] as int));

                      final availableContacts = allUsers
                          .where((item) => !item['hasChat'])
                          .toList()
                        ..sort((a, b) {
                          final userDataA = (a['doc'] as DocumentSnapshot).data() as Map<String, dynamic>;
                          final userDataB = (b['doc'] as DocumentSnapshot).data() as Map<String, dynamic>;
                          return userDataA['surname'].toString()
                              .compareTo(userDataB['surname'].toString());
                        });

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (activeChats.isNotEmpty) ...[
                            Text(
                              'Активні чати',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ...activeChats.map((item) => _buildUserTile(item['doc'] as DocumentSnapshot)),
                            if (availableContacts.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              const Divider(thickness: 1),
                              const SizedBox(height: 10),
                              Text(
                                'Доступні контакти',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
                          ],
                          ...availableContacts.map((item) => _buildUserTile(item['doc'] as DocumentSnapshot)),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserTile(DocumentSnapshot user) {
    final userData = user.data() as Map<String, dynamic>;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 300));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                recipientId: user.id,
                recipientName: '${userData['surname']} ${userData['name']}',
                recipientAvatar: userData['avatar'] ?? '',
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              CachedAvatar(
                imageUrl: userData['avatar'],
                radius: 25,
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
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: getLastMessage(user.id),
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
                        final isImage = message['type'] == 'image';

                        return Text(
                          '$prefix${isImage ? '📷 Фото' : message['text'] ?? ''}',
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
  }
}

class UserSearchDelegate extends SearchDelegate<String> {
  final FirebaseFirestore _firestore;
  final BuildContext context;

  UserSearchDelegate(this._firestore, this.context);

  @override
  String get searchFieldLabel => 'Пошук...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(child: Text('Почніть вводити дані користувача.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('students')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Помилка: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final searchQuery = query.toLowerCase();
        
        final users = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nickname = (data['nickname'] ?? '').toString().toLowerCase();
          final name = (data['name'] ?? '').toString().toLowerCase();
          final surname = (data['surname'] ?? '').toString().toLowerCase();
          final isPrivate = data['isPrivate'] ?? false;

          return !isPrivate && (
            nickname.contains(searchQuery) ||
            name.contains(searchQuery) ||
            surname.contains(searchQuery)
          );
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text('Користувачів не знайдено'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: UserAvatar(userId: users[index].id),
              title: Text('${userData['surname']} ${userData['name']}'),
              subtitle: Text('@${userData['nickname']}'),
                onTap: () async {
                await Future.delayed(const Duration(milliseconds: 300));
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
            );
          },
        );
      },
    );
  }
}