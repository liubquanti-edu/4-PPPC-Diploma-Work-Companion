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
import 'services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/alert_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(prefs),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlertProvider()),
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
