import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:pppc_companion/pages/contact.dart';
import 'package:pppc_companion/pages/profile.dart';
import 'pages/home.dart';
import 'pages/education.dart';
import 'pages/auth/email_screen.dart';
import 'pages/chat/chat.dart';
import 'services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/alert_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'dart:convert';
import '/providers/transport_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? currentOpenChatId;

// Додайте змінну для відстеження ID сповіщень
int _notificationId = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Get FCM token
  final fcmToken = await FirebaseMessaging.instance.getToken();
  
  // Save token to Firestore
  if (fcmToken != null) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({'fcmToken': fcmToken});
    }
  }
  
  // Handle token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((token) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  });

  final prefs = await SharedPreferences.getInstance();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    Firebase.app();
  }

  await initializeDateFormatting('uk');

  // Handle notification when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final chatRoomId = message.data['chatRoomId'];
    if (chatRoomId != null) {
      // Get recipient info and navigate to chat
      _handleNotificationTap(chatRoomId);
    }
  });

  await _initNotifications();

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      // Check if the notification is from the currently open chat
      final notificationChatId = message.data['chatRoomId'];
      
      // Show notification only if it's not from the current open chat
      if (notificationChatId != currentOpenChatId) {
        // Збільшуємо ID для кожного нового сповіщення
        _notificationId++;
        
        FlutterLocalNotificationsPlugin().show(
          _notificationId, // Використовуємо унікальний ID замість 0
          message.notification!.title,
          message.notification!.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_channel',
              'Chat Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: 'notification_icon',
              // Додаємо налаштування для групування сповіщень
              groupKey: 'chat_messages',
              setAsGroupSummary: false,
              groupAlertBehavior: GroupAlertBehavior.all,
              channelShowBadge: true,
              autoCancel: true,
            ),
          ),
          payload: json.encode(message.data),
        );

        // Показуємо групове сповіщення
        FlutterLocalNotificationsPlugin().show(
          0, // ID для групового сповіщення завжди 0
          'Нові повідомлення',
          'У вас є непрочитані повідомлення',
          NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_channel',
              'Chat Notifications',
              groupKey: 'chat_messages',
              setAsGroupSummary: true,
              icon: 'notification_icon',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  });

  // Додайте в функцію main() після існуючої обробки сповіщень:

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      final notificationType = message.data['type'];
      
      // Показуємо сповіщення тільки якщо це коментар до поста
      if (notificationType == 'post_comment') {
        _notificationId++;
        
        FlutterLocalNotificationsPlugin().show(
          _notificationId,
          message.notification!.title,
          message.notification!.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'post_comments_channel', // Новий канал для сповіщень коментарів
              'Post Comments Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: 'notification_icon',
              channelShowBadge: true,
              autoCancel: true,
            ),
          ),
          payload: json.encode(message.data),
        );
      }
    }
  });

  // Handle notification tap
  FlutterLocalNotificationsPlugin().initialize(
    InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'), // Changed from ic_launcher
    ),
    onDidReceiveNotificationResponse: (details) async {
      if (details.payload != null) {
        final data = json.decode(details.payload!);
        if (data['type'] == 'chat_message') {
          // Очікуємо ініціалізації Firebase і авторизації
          await Firebase.initializeApp();
          final auth = FirebaseAuth.instance;
          if (auth.currentUser == null) {
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (context) => const EmailScreen())
            );
            return;
          }
          _handleNotificationTap(data['chatRoomId']);
        }
      }
    },
  );

  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Configure notification settings
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(prefs),
      child: MyApp(navigatorKey: navigatorKey),  // Pass the key to MyApp
    ),
  );
}

Future<void> _initNotifications() async {
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM Token: $fcmToken');

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'chat_channel',
              'Chat Notifications',
              description: 'Notifications for new chat messages',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );
    }

    if (Platform.isAndroid) {
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'post_comments_channel',
              'Post Comments Notifications',
              description: 'Notifications for post comments',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );
    }
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }
}

void _handleNotificationTap(String chatRoomId) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final recipientId = chatRoomId.split('_').firstWhere(
      (id) => id != currentUser.uid,
    );

    final recipientDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(recipientId)
        .get();

    if (recipientDoc.exists) {
      final data = recipientDoc.data()!;
      
      // Перевіряємо чи є активний навігатор
      if (navigatorKey.currentState?.mounted ?? false) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainScreen(), // Спочатку відкриваємо головний екран
          ),
          (route) => false,
        );
        
        // Потім відкриваємо чат
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              recipientId: recipientId,
              recipientName: '${data['surname']} ${data['name']}',
              recipientAvatar: data['avatar'] ?? '',
            ),
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('Error handling notification tap: $e');
  }
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  
  const MyApp({Key? key, required this.navigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => TransportProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          if (!themeProvider.isInitialized) {
            return MaterialApp(
              home: Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              ColorScheme lightColorScheme;
              ColorScheme darkColorScheme;

              if (themeProvider.useDynamicColors && lightDynamic != null && darkDynamic != null) {
                lightColorScheme = lightDynamic.harmonized();
                darkColorScheme = darkDynamic.harmonized();
              } else {
                lightColorScheme = ColorScheme.fromSeed(
                  seedColor: Colors.deepOrange,
                  brightness: Brightness.light,
                );
                darkColorScheme = ColorScheme.fromSeed(
                  seedColor: Colors.deepOrange,
                  brightness: Brightness.dark,
                );
              }

              return MaterialApp(
                navigatorKey: navigatorKey,  // Set the navigator key
                title: 'Flutter Demo',
                theme: ThemeData(
                  colorScheme: lightColorScheme,
                  useMaterial3: true,
                  fontFamily: 'Comfortaa',
                ),
                darkTheme: ThemeData(
                  colorScheme: darkColorScheme,
                  useMaterial3: true,
                  fontFamily: 'Comfortaa',
                ),
                themeMode: themeProvider.themeMode,
                home: StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return const MainScreen();
                    }
                    return const EmailScreen();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInForeground = true;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _userService.getUserName(),
      builder: (context, snapshot) {
        final List<Widget> _pages = [
          MyHomePage(
            title: 'Привіт, ${snapshot.data ?? 'користувач'} 👋'
          ),
          const EducationPage(),
          const ContactPage(),
          const ProfilePage(),
        ];

        final bool isTablet = MediaQuery.of(context).size.width >= 600;

        if (isTablet) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  useIndicator: true,
                  groupAlignment: 0,
                  backgroundColor: Theme.of(context).colorScheme.onSecondary,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Головна'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school_rounded),
                      label: Text('Освіта'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.message_outlined),
                      selectedIcon: Icon(Icons.message_rounded),
                      label: Text('Зв\'язок'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outlined),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Профіль'),
                    ),
                  ],
                ),
                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            ),
          );
        }
        
        return Scaffold(
          body: _pages[_selectedIndex],
            bottomNavigationBar: NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.onSecondary,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            height: 80,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Головна',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Освіта',
              ),
              NavigationDestination(
                icon: Icon(Icons.message_outlined),
                selectedIcon: Icon(Icons.message_rounded),
                label: 'Зв\'язок',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outlined),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Профіль',
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isInForeground) {
        _updateLastSeen();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _isInForeground = state == AppLifecycleState.resumed;
  }

  void _updateLastSeen() async {
    await FirebaseFirestore.instance
        .collection('students')
        .doc(_auth.currentUser!.uid)
        .update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
