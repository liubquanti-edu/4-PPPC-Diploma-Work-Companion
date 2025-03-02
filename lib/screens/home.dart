import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../widgets/window_buttons.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  DateTime selectedTime = DateTime.now();

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showEmergencyDialog(BuildContext context) async {
    // Set end time 6 hours from now by default
    selectedTime = DateTime.now().add(const Duration(hours: 6));
    selectedDate = selectedTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Створення екстреного оповіщення'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Заголовок',
              child: TextBox(
                controller: nameController,
                placeholder: 'Що трапилося?',
              ),
            ),
            const SizedBox(height: 10),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Чому?',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: DatePicker(
                header: 'Оберіть дату завершення',
                selected: selectedDate,
                onChanged: (date) {
                  setState(() {
                    selectedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TimePicker(
                header: 'Оберіть час завершення',
                selected: selectedTime,
                onChanged: (time) {
                  setState(() {
                    selectedTime = time;
                    selectedDate = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
                hourFormat: HourFormat.HH,
              ),
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            child: const Text('Створити'),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                await displayInfoBar(context, builder: (context, close) {
                  return InfoBar(
                    title: const Text('Помилка'),
                    content: const Text('Заголовок є обов\'язковим полем'),
                    action: IconButton(
                      icon: const Icon(FluentIcons.clear),
                      onPressed: close,
                    ),
                    severity: InfoBarSeverity.error,
                  );
                });
                return;
              }
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _createEmergencyAlert();
    }
  }

  Future<void> _createEmergencyAlert() async {
    try {
      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // Get current user and force token refresh
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Користувач не авторизований');

      // Get fresh token with claims
      await user.getIdToken(true); // Force refresh
      final idToken = await user.getIdToken();
      final decodedToken = JwtDecoder.decode(idToken!);
      
      debugPrint('Token claims: $decodedToken');
      
      if (decodedToken['admin'] != true) {
        throw Exception('Недостатньо прав для виконання операції');
      }

      await FirebaseFirestore.instance.collection('emergency').add({
        'name': nameController.text,
        'description': descriptionController.text,
        'end': Timestamp.fromDate(endDateTime),
        'createdAt': Timestamp.now(),
        'createdBy': user.uid,
      });

      if (!mounted) return;
      
      await showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Успіх'),
          content: const Text('Оповіщення успішно створено'),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
                nameController.clear();
                descriptionController.clear();
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Помилка'),
          content: Text('Помилка при створенні оповіщення: $e'),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      
      // Navigate to login screen and remove all previous routes
      await Navigator.of(context).pushAndRemoveUntil(
        FluentPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // This removes all previous routes
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Помилка'),
          content: Text('Помилка при виході: $e'),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: MoveWindow(
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Адміністратор компаньйону'),
          ),
        ),
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 46,
              height: 32,
              child: IconButton(
                icon: const Icon(FluentIcons.sign_out),
                onPressed: _handleSignOut,
              ),
            ),
            const WindowButtons(),
          ],
        ),
      ),
      content: ScaffoldPage(
        content: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                SizedBox(
                  width: 200,
                  height: 60,
                  child: SvgPicture.asset(
                    'assets/svg/ППФК.svg',
                    height: 30,
                  ),
                ),

                Text(
                  'Адміністратор компаньйону',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 400,
                  child: Divider(style: DividerThemeData(thickness: 2)),
                ),
                const SizedBox(height: 10),
                Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Button(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(const EdgeInsets.all(50)),
                    ),
                    onPressed: () => _showEmergencyDialog(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                      Icon(
                        FluentIcons.education,
                        size: 24,
                        ),
                      SizedBox(height: 8),
                      Text(
                        'Навчання',
                        style: TextStyle(
                        fontSize: 16,
                        ),
                      ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                    Button(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(const EdgeInsets.all(50)),
                    ),
                    onPressed: () => _showEmergencyDialog(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                      Icon(
                        FluentIcons.people,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Студенти',
                        style: TextStyle(
                        fontSize: 16,
                        ),
                      ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                    Button(
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all(const EdgeInsets.all(50)),
                    ),
                    onPressed: () => _showEmergencyDialog(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, 
                      children: const [
                      Icon(
                        FluentIcons.contact,
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Викладачі',
                        style: TextStyle(
                        fontSize: 16,
                        ),
                      ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 400,
                child: Divider(style: DividerThemeData(thickness: 2)),
              ),
              const SizedBox(height: 10),
              Button(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.isPressed ? Colors.red.darker : Colors.red.darkest,
                  ),
                ),
                onPressed: () => _showEmergencyDialog(context),
                child: const Text(
                  'Екстренне оповіщення',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}