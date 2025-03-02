import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:system_theme/system_theme.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system theme
  if (defaultTargetPlatform.supportsAccentColor) {
    SystemTheme.fallbackColor = Colors.blue;
    await SystemTheme.accentColor.load();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(800, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(800, 600);
    win.alignment = Alignment.center;
    win.title = "PPPC Companion Admin";
    win.show();
  });

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    SystemTheme.onChange.listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Convert system accent color to FluentUI AccentColor
    final systemAccent = AccentColor.swatch({
      'darkest': SystemTheme.accentColor.darkest,
      'darker': SystemTheme.accentColor.darker,
      'dark': SystemTheme.accentColor.dark,
      'normal': SystemTheme.accentColor.accent,
      'light': SystemTheme.accentColor.light,
      'lighter': SystemTheme.accentColor.lighter,
      'lightest': SystemTheme.accentColor.lightest,
    });

    return FluentApp(
      title: 'PPPC Companion Admin',
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: systemAccent,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: systemAccent,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
