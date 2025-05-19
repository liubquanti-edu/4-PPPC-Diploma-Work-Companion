//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:pppc_companion/pages/contact.dart';
import 'package:pppc_companion/pages/other.dart';
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
import 'package:pppc_companion/pages/transport/route_details.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? currentOpenChatId;

int _notificationId = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RouteDetails.loadStations();
  await Firebase.initializeApp();
  
  final fcmToken = await FirebaseMessaging.instance.getToken();
  
  if (fcmToken != null) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .update({'fcmToken': fcmToken});
    }
  }
  
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

  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    final chatRoomId = message.data['chatRoomId'];
    if (chatRoomId != null) {
      _handleNotificationTap(chatRoomId);
    }
  });

  await _initNotifications();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      final notificationChatId = message.data['chatRoomId'];
      
      if (notificationChatId != currentOpenChatId) {
        _notificationId++;
        
        FlutterLocalNotificationsPlugin().show(
          _notificationId,
          message.notification!.title,
          message.notification!.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_channel',
              'Chat Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: 'notification_icon',
              groupKey: 'chat_messages',
              setAsGroupSummary: false,
              groupAlertBehavior: GroupAlertBehavior.all,
              channelShowBadge: true,
              autoCancel: true,
            ),
          ),
          payload: json.encode(message.data),
        );

        FlutterLocalNotificationsPlugin().show(
          0,
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

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      final notificationType = message.data['type'];
      
      if (notificationType == 'post_comment') {
        _notificationId++;
        
        FlutterLocalNotificationsPlugin().show(
          _notificationId,
          message.notification!.title,
          message.notification!.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'post_comments_channel',
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
      } else if (notificationType == 'chat_message') {
        _notificationId++;
        
        FlutterLocalNotificationsPlugin().show(
          _notificationId,
          message.notification!.title,
          message.notification!.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_channel',
              'Chat Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: 'notification_icon',
              channelShowBadge: true,
              autoCancel: true,
            ),
          ),
          payload: json.encode(message.data),
        );
      } else if (notificationType == 'alert_status') {
        _notificationId++;
        
        FlutterLocalNotificationsPlugin().show(
          _notificationId,
          message.notification!.title,
          message.notification!.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'alert_channel',
              'Air Raid Alert Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: 'notification_icon',
              channelShowBadge: true,
              autoCancel: true,
              color: message.data['status'] == 'A' ? Colors.red : Colors.green,
            ),
          ),
          payload: json.encode(message.data),
        );
      }
    }
  });

  FlutterLocalNotificationsPlugin().initialize(
    InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'),
    ),
    onDidReceiveNotificationResponse: (details) async {
      if (details.payload != null) {
        final data = json.decode(details.payload!);
        if (data['type'] == 'chat_message') {
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

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => TransportProvider(prefs),
        ),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
      ],
      child: MyApp(navigatorKey: navigatorKey),
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
          
      await FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'alert_channel',
              'Air Raid Alert Notifications',
              description: 'Air raid alert notifications',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );
    }

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
      
      if (navigatorKey.currentState?.mounted ?? false) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainScreen(),
          ),
          (route) => false,
        );
        
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
    return Consumer<ThemeProvider>(
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
              navigatorKey: navigatorKey,
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
              builder: (context, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
                    systemNavigationBarColor: Theme.of(context).colorScheme.onSecondary,
                    systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.light 
                        ? Brightness.dark 
                        : Brightness.light,
                  ));
                });
                
                return child!;
              },
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
          const OtherPage(),
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
                      label: Text('Домівка'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school_rounded),
                      label: Text('Навчання'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outlined),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: Text('Спільнота'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.more_horiz_outlined),
                      selectedIcon: Icon(Icons.more_horiz_rounded),
                      label: Text('Інше'),
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
                label: 'Домівка',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Навчання',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outlined),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Спільнота',
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz_outlined),
                selectedIcon: Icon(Icons.more_horiz_rounded),
                label: 'Інше',
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
