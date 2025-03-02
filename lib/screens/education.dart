import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../widgets/window_buttons.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  int _selectedIndex = 0;
  bool isLoading = false;

  Future<void> _updateBellTime(String docId, String field, DateTime time) async {
    try {
      setState(() => isLoading = true);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Користувач не авторизований');

      final idToken = await user.getIdToken();
      final decodedToken = JwtDecoder.decode(idToken!);
      
      if (decodedToken['admin'] != true) {
        throw Exception('Недостатньо прав для виконання операції');
      }

      // Format time as "HH:mm"
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('bell')
          .doc(docId)
          .update({field: timeString});

      if (!mounted) return;

      // Force UI refresh
      setState(() {});

      await displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Успіх'),
            content: const Text('Час дзвінка оновлено'),
            severity: InfoBarSeverity.success,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      await displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Помилка'),
            content: Text(e.toString()),
            severity: InfoBarSeverity.error,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  DateTime _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Widget _buildBellSchedule() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bell')
          .orderBy(FieldPath.documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Помилка: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: ProgressRing(),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final startTime = _parseTimeString(data['start'] ?? '0:00');
            final endTime = _parseTimeString(data['end'] ?? '0:00');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                    children: [
                      Text(
                        'Пара $index',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      SizedBox(width: 30),
                        Container(
                        width: 3,
                        height: 120,
                        decoration: BoxDecoration(
                          color: FluentTheme.of(context).accentColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TimePicker(
                            selected: startTime,
                            header: 'Початок',
                            onChanged: (time) async {
                              await _updateBellTime(
                                doc.id,
                                'start',
                                time,
                              );
                              // Force rebuild after update
                              if (mounted) {
                                setState(() {});
                              }
                                                        },
                            hourFormat: HourFormat.HH,
                          ),
                          const SizedBox(height: 8),
                          TimePicker(
                            selected: endTime,
                            header: 'Кінець',
                            onChanged: (time) async {
                              await _updateBellTime(
                                doc.id,
                                'end',
                                time,
                              );
                            },
                            hourFormat: HourFormat.HH,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: true,
        title: MoveWindow(
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Навчання'),
          ),
        ),
        actions: const WindowButtons(),
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.clock),
            title: const Text('Дзвінок'),
            body: _buildBellSchedule(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.book_answers),
            title: const Text('Курси'),
            body: const Center(
              child: Text(
                'Налаштування дзвінків',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.calendar),
            title: const Text('Події'),
            body: const Center(
              child: Text(
                'Налаштування дзвінків',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}