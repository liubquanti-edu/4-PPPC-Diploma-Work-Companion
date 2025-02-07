import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pppc_companion/pages/users/user.dart';
import '/models/avatars.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pppc_companion/main.dart';

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
  String? _editingMessageKey;
  bool get _isEditing => _editingMessageKey != null;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
    final DatabaseReference _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://pppc-companion-default-rtdb.europe-west1.firebasedatabase.app'
  ).ref();
  final _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _replyTo;

  String get chatRoomId {
    final List<String> ids = [_auth.currentUser!.uid, widget.recipientId];
    ids.sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();
    // Set current chat when opened
    currentOpenChatId = chatRoomId;
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      if (_isEditing) {
        await _database.child('chats/$chatRoomId/messages/$_editingMessageKey').update({
          'text': _messageController.text.trim(),
          'edited': true,
          'editedAt': ServerValue.timestamp,
        });
        _cancelEdit();
      } else {
        final messageRef = _database.child('chats/$chatRoomId/messages').push();
        final message = {
          'senderId': _auth.currentUser!.uid,
          'text': _messageController.text.trim(),
          'timestamp': ServerValue.timestamp,
        };
        
        if (_replyTo != null) {
          message['replyTo'] = {
            'messageId': _replyTo!['key'],
            'text': _replyTo!['text'],
            'senderId': _replyTo!['senderId'],
          };
        }
        
        await messageRef.set(message);
        _cancelReply();
      }

      // Get recipient's FCM token
      final recipientDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.recipientId)
          .get();
      
      if (recipientDoc.exists) {
        final recipientToken = recipientDoc.data()?['fcmToken'];
        
        // Get sender's name
        final senderDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(_auth.currentUser!.uid)
            .get();
        final senderData = senderDoc.data();
        final senderName = '${senderData?['surname']} ${senderData?['name']}';

        if (recipientToken != null) { 
          debugPrint('Sending notification to token: $recipientToken');
          final response = await http.post(
            Uri.parse('https://us-central1-pppc-companion.cloudfunctions.net/sendChatNotification'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'token': recipientToken,
              'title': senderName, // Changed from widget.recipientName to senderName
              'body': _messageController.text.trim(),
              'data': {
                'chatRoomId': chatRoomId,
                'senderId': _auth.currentUser!.uid,
                'type': 'chat_message'
              }
            }),
          );
          debugPrint('Notification response: ${response.statusCode} - ${response.body}');

          if (response.statusCode != 200) {
            debugPrint('Notification error: ${response.body}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }

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

  void _startEditMessage(String messageKey, String currentText) {
  setState(() {
    _editingMessageKey = messageKey;
    _messageController.text = currentText;
  });
  _messageController.selection = TextSelection.fromPosition(
    TextPosition(offset: _messageController.text.length),
  );
  FocusScope.of(context).requestFocus();
}

  void _deleteMessage(String messageKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити повідомлення'),
        content: const Text('Ви впевнені, що хочете видалити це повідомлення?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _database.child('chats/$chatRoomId/messages/$messageKey').remove();
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageKey = null;
      _messageController.clear();
    });
  }

  void _startReply(Map<String, dynamic> message) {
    setState(() {
      _replyTo = message;
    });
    FocusScope.of(context).requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    userId: widget.recipientId,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CachedAvatar(
                    imageUrl: widget.recipientAvatar,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.recipientName,
                      style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .doc(widget.recipientId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        
                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                        final lastSeen = userData?['lastSeen'] as Timestamp?;
                        
                        if (lastSeen == null) return const SizedBox.shrink();
                        
                        final now = DateTime.now();
                        final lastSeenDate = lastSeen.toDate();
                        final difference = now.difference(lastSeenDate);
                        
                        String lastSeenText;
                        if (difference.inMinutes < 1) {
                          lastSeenText = 'Онлайн';
                        } else if (difference.inHours < 1) {
                          lastSeenText = 'Був(ла) ${difference.inMinutes} хв тому';
                        } else if (difference.inDays < 1) {
                          lastSeenText = 'Був(ла) ${difference.inHours} год тому';
                        } else {
                          lastSeenText = 'Був(ла) ${DateFormat('dd.MM.yyyy HH:mm').format(lastSeenDate)}';
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            lastSeenText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                    final messageData = Map<String, dynamic>.from(value);
                    messageData['key'] = key;
                    messages.add(messageData);
                  });
                }
                
                messages.sort((a, b) => 
                  (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

                final groupedMessages = _groupMessagesByDate(messages);
                final dates = groupedMessages.keys.toList()
                ..sort((a, b) {
                  final aDate = DateTime.fromMillisecondsSinceEpoch(
                    groupedMessages[a]!.first['timestamp'] ?? 0);
                  final bDate = DateTime.fromMillisecondsSinceEpoch(
                    groupedMessages[b]!.first['timestamp'] ?? 0);
                  return bDate.compareTo(aDate);
                });

                if (dates.isEmpty) {
                  return const Center(
                    child: Text('Немає повідомлень'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: dates.length * 2 - 1,
                  itemBuilder: (context, index) {
                    if (index.isOdd) {
                      return const SizedBox(height: 0);
                    }

                    final dateIndex = index ~/ 2;
                    final date = dates[dateIndex];
                    final messagesForDate = groupedMessages[date]!;

                    return Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Divider(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.1),
                            ),
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...messagesForDate.map((message) {
                          final isMe = message['senderId'] == _auth.currentUser!.uid;
                          final time = DateTime.fromMillisecondsSinceEpoch(
                            message['timestamp'] ?? 0
                          );

                          return Dismissible(
                            key: Key(message['key']),
                            direction: DismissDirection.endToStart,
                            onDismissed: null,
                            confirmDismiss: (direction) async {
                              _startReply(message);
                              return false;
                            },
                            background: Container(
                              padding: const EdgeInsets.only(right: 16),
                              alignment: Alignment.centerRight,
                              child: const Icon(Icons.reply),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: GestureDetector(
                                  onLongPress: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => SimpleDialog(
                                        children: [
                                          SimpleDialogOption(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _startReply(message);
                                            },
                                            child: const Row(
                                              children: [
                                                Icon(Icons.reply),
                                                SizedBox(width: 8),
                                                Text('Відповісти'),
                                              ],
                                            ),
                                          ),
                                          if (isMe) ...[
                                            SimpleDialogOption(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _startEditMessage(message['key'], message['text']);
                                              },
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(width: 8),
                                                  Text('Редагувати'),
                                                ],
                                              ),
                                            ),
                                            SimpleDialogOption(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteMessage(message['key']);
                                              },
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.delete),
                                                  SizedBox(width: 8),
                                                  Text('Видалити'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe 
                                            ? Theme.of(context).colorScheme.onSecondary
                                            : Theme.of(context).colorScheme.surfaceVariant,
                                          borderRadius: isMe 
                                            ? const BorderRadius.only(
                                                topLeft: Radius.circular(15),
                                                topRight: Radius.circular(15),
                                                bottomRight: Radius.circular(5),
                                                bottomLeft: Radius.circular(15),
                                              )
                                            : const BorderRadius.only(
                                                topLeft: Radius.circular(15),
                                                topRight: Radius.circular(15),
                                                bottomRight: Radius.circular(15),
                                                bottomLeft: Radius.circular(5),
                                              )
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (message['replyTo'] != null) ...[
                                                Container(
                                                  margin: const EdgeInsets.only(top: 4),
                                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                                  decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                                                  border: Border(
                                                    left: BorderSide(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      width: 2,
                                                    ),
                                                    top: BorderSide(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      width: 2,
                                                    ),
                                                    bottom: BorderSide(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      width: 2,
                                                    ),
                                                    right: BorderSide(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      widget.recipientName,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Theme.of(context).colorScheme.primary,
                                                      ),
                                                    ),
                                                    Text(
                                                      message['replyTo']['text'],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Text(
                                              message['text'] ?? '',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  DateFormat('HH:mm').format(time),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                                  ),
                                                ),
                                                if (message['edited'] == true) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.edit,
                                                    size: 10,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyTo != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Відповідь на',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                _replyTo!['text'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _cancelReply,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _cancelEdit,
                      ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _isEditing 
                            ? 'Редагування...' 
                            : 'Написати...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
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
                      child: Icon(_isEditing ? Icons.check : Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clear current chat when closed
    currentOpenChatId = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}