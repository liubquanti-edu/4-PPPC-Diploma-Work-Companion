import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pppc_companion/firebase_options.dart';
import 'package:pppc_companion/pages/contact.dart';
import 'package:pppc_companion/pages/profile.dart';
import 'pages/home.dart';
import 'pages/education.dart';
import 'pages/auth/email_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange, brightness: Brightness.dark),
        useMaterial3: true,
        fontFamily: 'Comfortaa',
      ),
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
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final UserService _userService = UserService();

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
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
}
