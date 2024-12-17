import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pppc_companion/pages/chat/chat.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({Key? key}) : super(key: key);

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

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

          debugPrint('Current user group: ${groupSnapshot.data}'); // Debug log

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('students')
                .where('group', isEqualTo: int.tryParse(groupSnapshot.data ?? ''))
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Firestore error: ${snapshot.error}'); // Debug log
                return Center(child: Text('Помилка: ${snapshot.error}'));
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!.docs
                  .where((doc) => doc.id != _auth.currentUser!.uid)
                  .toList();

              debugPrint('Found ${users.length} users in group'); // Debug log

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
                  debugPrint('User data: $userData'); // Debug log
                  
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
                          color: Theme.of(context).colorScheme.surface,
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
                                  Text(
                                    '@${userData['nickname']}',
                                    style: Theme.of(context).textTheme.bodySmall,
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