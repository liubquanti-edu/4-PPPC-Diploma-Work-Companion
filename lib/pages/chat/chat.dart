import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientAvatar;

  const ChatScreen({
    Key? key,
    required this.recipientId,
    required this.recipientName,
    required this.recipientAvatar,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
    final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();
  final _auth = FirebaseAuth.instance;

  String get chatRoomId {
    final List<String> ids = [_auth.currentUser!.uid, widget.recipientId];
    ids.sort();
    return ids.join('_');
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageRef = _database.child('chats/$chatRoomId/messages').push();
    messageRef.set({
      'senderId': _auth.currentUser!.uid,
      'text': _messageController.text.trim(),
      'timestamp': ServerValue.timestamp,
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Helper method to format date
  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Сьогодні';
    } else if (messageDate == yesterday) {
      return 'Вчора';
    } else {
      return DateFormat('d MMMM y', 'uk').format(date);
    }
  }

  // Helper method to group messages by date
  Map<String, List<Map<String, dynamic>>> _groupMessagesByDate(List<Map<String, dynamic>> messages) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (var message in messages) {
      final date = DateTime.fromMillisecondsSinceEpoch(message['timestamp'] ?? 0);
      final dateStr = _formatMessageDate(date);
      
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(message);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.recipientAvatar.isNotEmpty 
                ? NetworkImage(widget.recipientAvatar)
                : const AssetImage('assets/img/noavatar.png') as ImageProvider,
            ),
            const SizedBox(width: 8),
            Text(widget.recipientName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _database
                  .child('chats/$chatRoomId/messages')
                  .orderByChild('timestamp')
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = <Map<String, dynamic>>[];
                if (snapshot.data?.snapshot.value != null) {
                  final messagesData = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map
                  );
                  messagesData.forEach((key, value) {
                    messages.add(Map<String, dynamic>.from(value));
                  });
                }
                
                messages.sort((a, b) => 
                  (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

                final groupedMessages = _groupMessagesByDate(messages);
                final dates = groupedMessages.keys.toList();

                if (dates.isEmpty) {
                  return const Center(
                    child: Text('Немає повідомлень'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: dates.length * 2 - 1,
                  itemBuilder: (context, index) {
                    if (index.isOdd) {
                      return const SizedBox(height: 8);
                    }

                    final dateIndex = index ~/ 2;
                    final date = dates[dateIndex];
                    final messagesForDate = groupedMessages[date]!;

                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                date,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ...messagesForDate.map((message) {
                          final isMe = message['senderId'] == _auth.currentUser!.uid;
                          final time = DateTime.fromMillisecondsSinceEpoch(
                            message['timestamp'] ?? 0
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe 
                                    ? Theme.of(context).colorScheme.onSecondary
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['text'] ?? '',
                                      style: TextStyle(
                                        color: isMe 
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('HH:mm').format(time),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMe 
                                          ? Colors.white70
                                          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Введіть повідомлення...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}