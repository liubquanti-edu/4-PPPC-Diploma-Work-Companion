import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pppc_companion/pages/users/user.dart';
import '/models/avatars.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pppc_companion/main.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

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
  bool _isUploading = false;

  // Додаємо нові змінні для управління прикріпленим фото
  File? _attachedImage;
  bool _isImageAttached = false;

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

  // Модифікуємо метод вибору зображення
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024, // Обмежуємо розмір
      imageQuality: 85 // Стискаємо якість
    );
    
    if (image != null) {
      setState(() {
        _attachedImage = File(image.path);
        _isImageAttached = true;
      });
    }
  }

  // Метод для відкріплення фото
  void _detachImage() {
    setState(() {
      _attachedImage = null;
      _isImageAttached = false;
    });
  }

  // Модифікуємо метод відправки повідомлення
  Future<void> _sendMessage() async {
  final messageText = _messageController.text.trim();
  final hasText = messageText.isNotEmpty;
  final hasImage = _attachedImage != null;

  if (!hasText && !hasImage) return;

  setState(() {
    _isUploading = true;
    _messageController.clear();
  });

  try {
    debugPrint('Початок відправки повідомлення');
    final messageRef = _database.child('chats/$chatRoomId/messages').push();
    String? imageUrl;

    // Завантажуємо зображення якщо воно є
    if (hasImage) {
      debugPrint('Завантаження зображення...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(chatRoomId)
          .child(fileName);

      // Завантажуємо файл
      final uploadTask = await storageRef.putFile(
        _attachedImage!,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'chatId': chatRoomId,
            'senderId': _auth.currentUser!.uid,
            'timestamp': timestamp.toString(),
          },
        ),
      );

      // Отримуємо URL завантаженого файлу
      imageUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('URL завантаженого зображення: $imageUrl');
    }

    // Створюємо повідомлення
    final message = {
      'senderId': _auth.currentUser!.uid,
      'timestamp': ServerValue.timestamp,
      'type': hasImage ? 'image' : 'text',
      if (hasText) 'text': messageText,
      if (hasImage && imageUrl != null) 'imageUrl': imageUrl,
    };

    // Додаємо дані про відповідь якщо є
    if (_replyTo != null) {
      message['replyTo'] = {
        'messageId': _replyTo!['key'],
        'text': _replyTo!['text'],
        'senderId': _replyTo!['senderId'],
      };
    }

    debugPrint('Збереження повідомлення: $message');
    await messageRef.set(message);

    // Отримуємо дані відправника
    final senderDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(_auth.currentUser!.uid)
        .get();
    
    debugPrint('Дані відправника: ${senderDoc.data()}');
    
    // Отримуємо дані отримувача
    final recipientDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(widget.recipientId)
        .get();

    debugPrint('Дані отримувача: ${recipientDoc.data()}');

    if (recipientDoc.exists) {
      final recipientToken = recipientDoc.data()?['fcmToken'] as String?;
      final senderName = "${senderDoc.data()?['surname']} ${senderDoc.data()?['name']}";

      debugPrint('FCM токен отримувача: $recipientToken');
      
      // Відправляємо сповіщення якщо є токен
      if (recipientToken != null) {
        debugPrint('Відправка HTTP запиту на Cloud Function...');
        try {
          final notificationData = {
            'token': recipientToken,
            'title': senderName,
            'body': hasImage ? '📷 Фото' : messageText,
            'data': {
              'type': 'chat_message',
              'chatRoomId': chatRoomId,
              'senderId': _auth.currentUser!.uid,
            },
          };
          
          debugPrint('Дані сповіщення: $notificationData');

          final response = await http.post(
            Uri.parse('https://us-central1-pppc-companion.cloudfunctions.net/sendChatNotification'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(notificationData),
          );

          debugPrint('Статус відповіді: ${response.statusCode}');
          debugPrint('Тіло відповіді: ${response.body}');

          if (response.statusCode != 200) {
            debugPrint('Помилка відправки сповіщення: ${response.body}');
          } else {
            debugPrint('Сповіщення успішно відправлено');
          }
        } catch (e) {
          debugPrint('Помилка при відправці сповіщення: $e');
        }
      }
    }

    setState(() {
      _attachedImage = null;
      _isUploading = false;
      _replyTo = null;
    });
  } catch (e) {
    debugPrint('Загальна помилка: $e');
    setState(() => _isUploading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e')),
      );
    }
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
      final now = DateTime.now();
      return date.year == now.year
          ? DateFormat('d MMMM', 'uk').format(date)
          : DateFormat('d MMMM y', 'uk').format(date);
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

  Future<void> _deleteMessage(String messageKey) async {
  // Отримуємо дані повідомлення перед видаленням
  final messageSnapshot = await _database
      .child('chats/$chatRoomId/messages/$messageKey')
      .get();
  
  if (!messageSnapshot.exists) return;
  
  final messageData = Map<String, dynamic>.from(
    messageSnapshot.value as Map
  );

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
    try {
      // Якщо повідомлення містить зображення, видаляємо його з Storage
      if (messageData['type'] == 'image' && messageData['imageUrl'] != null) {
        try {
          // Отримуємо посилання на зображення у Storage з URL
          final imageRef = FirebaseStorage.instance.refFromURL(messageData['imageUrl']);
          await imageRef.delete();
        } catch (e) {
          debugPrint('Помилка видалення зображення: $e');
        }
      }

      // Видаляємо саме повідомлення з бази даних
      await _database.child('chats/$chatRoomId/messages/$messageKey').remove();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка видалення: $e')),
        );
      }
    }
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
    _replyTo = {
      'key': message['key'],
      'text': message['type'] == 'image' ? '📷 Фото' : message['text'],
      'senderId': message['senderId'],
      'imageUrl': message['type'] == 'image' ? message['imageUrl'] : null,
    };
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
  // Update current chat ID when screen is opened
  if (currentOpenChatId != chatRoomId) {
    debugPrint('Opening chat: $chatRoomId');
    currentOpenChatId = chatRoomId;
  }

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
    body: Stack(
      children: [
        Column(
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
                                child: const Icon(Icons.reply_rounded),
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
                                                  Icon(Icons.reply_rounded),
                                                  SizedBox(width: 8),
                                                  Text('Відповісти'),
                                                ],
                                              ),
                                            ),
                                            if (isMe) ...[
                                              if (message['type'] != 'image') // Додаємо перевірку типу повідомлення
                                                SimpleDialogOption(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _startEditMessage(message['key'], message['text']);
                                                  },
                                                  child: const Row(
                                                    children: [
                                                      Icon(Icons.edit_rounded),
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
                                                    Icon(Icons.delete_rounded),
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
                                              if (message['type'] == 'image') ...[
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => Scaffold(
                                                          backgroundColor: Colors.black,
                                                          appBar: AppBar(
                                                            backgroundColor: Colors.black,
                                                            iconTheme: const IconThemeData(color: Colors.white),
                                                          ),
                                                          body: Container( // Додаємо Container для контролю розмірів
                                                            width: double.infinity,
                                                            height: double.infinity,
                                                            child: InteractiveViewer(
                                                              minScale: 0.5,
                                                              maxScale: 4,
                                                              child: Center( // Центруємо зображення
                                                                child: Hero(
                                                                  tag: message['imageUrl'] ?? message['key'],
                                                                  child: CachedNetworkImage(
                                                                    imageUrl: message['imageUrl'] ?? '',
                                                                    fit: BoxFit.contain, // Змінюємо на contain
                                                                    placeholder: (context, url) => const Center(
                                                                      child: CircularProgressIndicator(color: Colors.white),
                                                                    ),
                                                                    errorWidget: (context, url, error) => const Icon(
                                                                      Icons.error,
                                                                      color: Colors.white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [ 
                                                      Hero(
                                                        tag: message['imageUrl'] ?? message['key'],
                                                        child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(10),
                                                        child: CachedNetworkImage(
                                                          imageUrl: message['imageUrl'] ?? '',
                                                          width: 250,
                                                          height: 250,
                                                          fit: BoxFit.cover,
                                                          placeholder: (context, url) => Container(
                                                          width: 250,
                                                          height: 250,
                                                          decoration: BoxDecoration(
                                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          child: const Center(
                                                            child: CircularProgressIndicator(),
                                                          ),
                                                          ),
                                                          errorWidget: (context, url, error) => Container(
                                                          width: 250,
                                                          height: 250,
                                                          decoration: BoxDecoration(
                                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(10),
                                                          ),
                                                          child: const Center(
                                                            child: Icon(Icons.error_rounded),
                                                          ),
                                                          ),
                                                        ),
                                                        ),
                                                      ),
                                                      if (message['text'] != null && message['text'].isNotEmpty) ...[
                                                        const SizedBox(height: 5),
                                                        Text(
                                                        message['text'],
                                                        style: TextStyle(
                                                          color: Theme.of(context).colorScheme.onSurfaceVariant
                                                        ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                              ] else ...[
                                                Text(
                                                  message['text'] ?? '',
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant
                                                  ),
                                                ),
                                              ],
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
              color: Theme.of(context).colorScheme.onSecondary,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUploading)
                      Container(
                      margin: const EdgeInsets.only(right: 12, left: 12),
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: LinearProgressIndicator(
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary
                        ),
                      ),
                    ),
                  if (_replyTo != null)
                    Container(
                      padding: const EdgeInsets.only(right: 8, left: 8, top: 0, bottom: 0),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(width: 2, color: Theme.of(context).colorScheme.primary),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8, left: 10, top: 0, bottom: 0),
                                      child: Icon(
                                        Icons.reply_rounded,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_replyTo!['imageUrl'] != null) ...[
                                      Expanded(
                                        child: Text(
                                          '📷 Фото',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ] else ...[
                                      Expanded(
                                        child: Text(
                                          _replyTo!['text'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _cancelReply,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isImageAttached && _attachedImage != null)
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _attachedImage!,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                      Positioned(
                                      top: -8,
                                      right: -8,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 16),
                                        onPressed: _detachImage,
                                        iconSize: 16,
                                        style: IconButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size(24, 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  Row(
                    children: [
                      if (!_isEditing)
                        IconButton(
                        icon: const Icon(Icons.image_rounded),
                        onPressed: _pickImage,
                        ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
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
                              borderSide: BorderSide.none,
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
                      IconButton(
                        onPressed: _sendMessage,
                        icon: Icon(_isEditing ? Icons.check_rounded : Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  @override
  void dispose() {
  debugPrint('Closing chat: $chatRoomId');
  // Clear current chat ID when the screen is closed
  currentOpenChatId = null;
  _messageController.dispose();
  _scrollController.dispose();
  super.dispose();
}
}