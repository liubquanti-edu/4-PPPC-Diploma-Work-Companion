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

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (_isEditing) {
      // Update existing message
      await _database.child('chats/$chatRoomId/messages/$_editingMessageKey').update({
        'text': _messageController.text.trim(),
        'edited': true,
        'editedAt': ServerValue.timestamp,
      });
      _cancelEdit();
    } else {
      // Send new message
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
                    final messageData = Map<String, dynamic>.from(value);
                    messageData['key'] = key;
                    messages.add(messageData);
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
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
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
                                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                                  border: Border(
                                                    left: BorderSide(
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}