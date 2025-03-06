import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
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
            );
          },
        );
      },
    );
  }

  Widget _buildSpecialisationsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('specialisations')
          .orderBy('number')
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16, // горизонтальний відступ між картками
            runSpacing: 16, // вертикальний відступ між рядками
            alignment: WrapAlignment.start,
            children: [
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return SizedBox(
                  width: 300,
                  height: 350,
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                        children: [
                        Text(
                          data['number']?.toString() ?? '',
                          style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['name'] ?? '',
                          style: FluentTheme.of(context).typography.subtitle,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            FilledButton(
                              child: const Text('Редагувати'),
                              onPressed: () => _showEditSpecialisationDialog(context, doc),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(Colors.red.light),
                              ),
                              child: const Text('Видалити'),
                              onPressed: () => _deleteSpecialisation(context, doc),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              GestureDetector(
                onTap: () => _showCreateSpecialisationDialog(context),
                child: SizedBox(
                  width: 300,
                  height: 350,
                  child: Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    const Icon(
                      FluentIcons.add,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text('Нова спеціальність'),
                    ],
                  ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // Add this new method for creating specializations
  Future<void> _showCreateSpecialisationDialog(BuildContext context) async {
    final numberController = TextEditingController();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Створення спеціальності'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Номер',
                child: NumberBox(
                value: int.tryParse(numberController.text),
                onChanged: (value) => numberController.text = value?.toString() ?? '',
                placeholder: 'Введіть номер спеціальності',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву спеціальності',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис спеціальності',
                minLines: 3,
                maxLines: 20,
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
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance.collection('specialisations').add({
          'number': numberController.text,
          'name': nameController.text,
          'description': descriptionController.text,
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Спеціальність створено'),
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
      }
    }

    numberController.dispose();
    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditSpecialisationDialog(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final numberController = TextEditingController(text: data['number']?.toString() ?? '');
    final nameController = TextEditingController(text: data['name'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Редагування спеціальності'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Номер',
                child: NumberBox(
                value: int.tryParse(numberController.text),
                onChanged: (value) => numberController.text = value?.toString() ?? '',
                placeholder: 'Введіть номер спеціальності',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву спеціальності',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис спеціальності',
                minLines: 3,
                maxLines: 20,
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
            child: const Text('Зберегти'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await doc.reference.update({
          'number': numberController.text,
          'name': nameController.text,
          'description': descriptionController.text,
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Спеціальність оновлено'),
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
      }
    }

    numberController.dispose();
    nameController.dispose();
    descriptionController.dispose();
  }

  Widget _buildCycleCommissionsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cyclecommission')
          .orderBy('name')
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.start,
            children: [
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return SizedBox(
                  width: 300,
                  height: 200,
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                        children: [
                        Text(
                          data['name'] ?? '',
                          style: FluentTheme.of(context).typography.subtitle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['description'] ?? '',
                          style: FluentTheme.of(context).typography.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            FilledButton(
                              child: const Text('Редагувати'),
                              onPressed: () => _showEditCycleCommissionDialog(context, doc),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(Colors.red.light),
                              ),
                              child: const Text('Видалити'),
                              onPressed: () => _deleteCycleCommission(context, doc),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
                }).toList(),
                GestureDetector(
                onTap: () => _showCreateCycleCommissionDialog(context),
                child: SizedBox(
                  width: 300,
                  height: 200,
                  child: Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                    Icon(
                      FluentIcons.add,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text('Нова циклова комісія'),
                    ],
                  ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateCycleCommissionDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Створення циклової комісії'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву циклової комісії',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис циклової комісії',
                maxLines: 3,
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
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance.collection('cyclecommission').add({
          'name': nameController.text,
          'description': descriptionController.text,
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Циклову комісію створено'),
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
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditCycleCommissionDialog(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Редагування циклової комісії'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву циклової комісії',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис циклової комісії',
                maxLines: 3,
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
            child: const Text('Зберегти'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await doc.reference.update({
          'name': nameController.text,
          'description': descriptionController.text,
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Циклову комісію оновлено'),
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
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Widget _buildDisciplinesView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cyclecommission')
          .orderBy('name')
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

        final commissions = snapshot.data!.docs;

        return ListView.builder(
          itemCount: commissions.length,
          itemBuilder: (context, index) {
            final commission = commissions[index];
            final commissionData = commission.data() as Map<String, dynamic>;

            return Expander(
              leading: const Icon(FluentIcons.education),
              header: Text(
                commissionData['name'] ?? '',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              content: StreamBuilder<QuerySnapshot>(
                stream: commission.reference
                    .collection('subjects')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, subjectsSnapshot) {
                  if (subjectsSnapshot.hasError) {
                    return Text('Помилка: ${subjectsSnapshot.error}');
                  }

                  if (subjectsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: ProgressRing());
                  }

                  final subjects = subjectsSnapshot.data!.docs;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ...subjects.map((subject) {
                        final subjectData = subject.data() as Map<String, dynamic>;
                        return SizedBox(
                          width: 300,
                          height: 200,
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                                children: [
                                Text(
                                  subjectData['name'] ?? '',
                                  style: FluentTheme.of(context).typography.subtitle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subjectData['description'] ?? '',
                                  style: FluentTheme.of(context).typography.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    FilledButton(
                                      child: const Text('Редагувати'),
                                      onPressed: () => _showEditSubjectDialog(
                                        context, 
                                        commission.reference,
                                        subject,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all(Colors.red.light),
                                      ),
                                      child: const Text('Видалити'),
                                      onPressed: () => _deleteSubject(context, commission.reference, subject),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      GestureDetector(
                        onTap: () => _showCreateSubjectDialog(context, commission.reference),
                        child: SizedBox(
                          width: 300,
                          height: 200,
                          child: Card(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  FluentIcons.add,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text('Нова дисципліна'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateSubjectDialog(BuildContext context, DocumentReference commissionRef) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Створення дисципліни'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву дисципліни',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис дисципліни',
                maxLines: 3,
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
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await commissionRef.collection('subjects').add({
          'name': nameController.text,
          'description': descriptionController.text,
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Дисципліну створено'),
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
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditSubjectDialog(
    BuildContext context, 
    DocumentReference commissionRef,
    DocumentSnapshot subject,
  ) async {
    final data = subject.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name'] ?? '');
    final descriptionController = TextEditingController(text: data['description'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Редагування дисципліни'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву дисципліни',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис дисципліни',
                maxLines: 3,
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
            child: const Text('Зберегти'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await subject.reference.update({
          'name': nameController.text,
          'description': descriptionController.text,
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Дисципліну оновлено'),
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
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  // Add this method to handle specialty deletion
  Future<void> _deleteSpecialisation(BuildContext context, DocumentSnapshot doc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалення спеціальності'),
        content: const Text('Ви впевнені, що хочете видалити цю спеціальність?'),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red.light),
            ),
            child: const Text('Видалити'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await doc.reference.delete();
        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Спеціальність видалено'),
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
      }
    }
  }

  // Add this method to handle cycle commission deletion
  Future<void> _deleteCycleCommission(BuildContext context, DocumentSnapshot doc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалення циклової комісії'),
        content: const Text('Ви впевнені, що хочете видалити цю циклову комісію? Всі дисципліни також будуть видалені.'),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red.light),
            ),
            child: const Text('Видалити'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await doc.reference.delete();
        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Циклову комісію видалено'),
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
      }
    }
  }

  // Add this method to handle subject deletion
  Future<void> _deleteSubject(BuildContext context, DocumentReference commissionRef, DocumentSnapshot subject) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалення дисципліни'),
        content: const Text('Ви впевнені, що хочете видалити цю дисципліну?'),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red.light),
            ),
            child: const Text('Видалити'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await subject.reference.delete();
        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Дисципліну видалено'),
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
      }
    }
  }

  Widget _buildCoursesView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .orderBy('end', descending: true)
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
        final now = DateTime.now();
        
        // Розділяємо курси на активні та архівні
        final activeCourses = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['end'] as Timestamp).toDate().isAfter(now);
        }).toList();
        
        final archivedCourses = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['end'] as Timestamp).toDate().isBefore(now);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Активні курси',
                    style: FluentTheme.of(context).typography.title,
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    child: const Text('Створити курс'),
                    onPressed: () => _showCreateCourseDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: activeCourses.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildCourseCard(context, doc, data);
                }).toList(),
              ),
              if (archivedCourses.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Архів курсів',
                  style: FluentTheme.of(context).typography.title,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: archivedCourses.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCourseCard(context, doc, data);
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data['name'] ?? '',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            Text('Семестр: ${data['semester']}'),
            const SizedBox(height: 8),
            Text(
              'Початок: ${DateFormat('dd.MM.yyyy').format((data['start'] as Timestamp).toDate())}',
            ),
            Text(
              'Кінець: ${DateFormat('dd.MM.yyyy').format((data['end'] as Timestamp).toDate())}',
            ),
            const SizedBox(height: 8),
            Text('Групи: ${(data['groups'] as List<dynamic>).join(", ")}'),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  child: const Text('Редагувати'),
                  onPressed: () => _showEditCourseDialog(context, doc),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.red.light),
                  ),
                  child: const Text('Видалити'),
                  onPressed: () => _deleteCourse(context, doc),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateCourseDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final groupsController = TextEditingController();
    DateTime? startDate = DateTime.now();
    DateTime? endDate = DateTime.now().add(const Duration(days: 120));
    int selectedSemester = 1;
    List<String> specialties = [];

    // Отримуємо список спеціальностей
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('specialisations')
          .orderBy('number')
          .get();
      specialties = snapshot.docs
          .map((doc) => (doc.data()['name'] as String))
          .toList();
    } catch (e) {
      debugPrint('Error loading specialties: $e');
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Створення курсу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Спеціальність', 
              child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, setState) {
                String? selectedSpecialty = nameController.text;
                return ComboBox<String>(
                isExpanded: true,
                value: selectedSpecialty,
                items: specialties.map<ComboBoxItem<String>>((name) {
                return ComboBoxItem<String>(
                  value: name,
                  child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  ),
                );
                }).toList(),
                onChanged: (value) {
                if (value != null) {
                  setState(() {
                  selectedSpecialty = value;
                  nameController.text = value;
                  });
                }
                },
                placeholder: const Text('Оберіть спеціальність'),
                );
                }
              ),
              ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Семестр',
              child: StatefulBuilder(
                builder: (context, setState) {
                  return ComboBox<int>(
                    value: selectedSemester,
                    items: [1, 2, 3, 4, 5, 6, 7, 8].map((semester) {
                      return ComboBoxItem<int>(
                        value: semester,
                        child: Text('$semester семестр'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSemester = value;
                        });
                      }
                    },
                  );
                }
              ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Початок',
                child: StatefulBuilder(
                builder: (context, setDateState) {
                  return DatePicker(
                  selected: startDate,
                  onChanged: (date) {
                    setDateState(() {
                    startDate = date;
                    });
                  },
                  );
                }
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Кінець',
                child: StatefulBuilder(
                builder: (context, setDateState) {
                  return DatePicker(
                  selected: endDate,
                  onChanged: (date) {
                    setDateState(() {
                    endDate = date;
                    });
                  },
                  );
                }
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Групи (через кому)',
              child: TextBox(
                controller: groupsController,
                placeholder: 'Наприклад: 401, 402, 403',
              ),
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
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && startDate != null && endDate != null) {
      try {
        final groups = groupsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map((e) => int.parse(e)) // Convert to integers
            .toList();

        await FirebaseFirestore.instance.collection('courses').add({
          'name': nameController.text,
          'semester': selectedSemester,
          'start': Timestamp.fromDate(startDate!),
          'end': Timestamp.fromDate(endDate!),
          'groups': groups, // Now storing as List<int>
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Курс створено'),
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
              content: Text(e is FormatException 
                ? 'Номери груп мають бути числами' 
                : e.toString()),
              severity: InfoBarSeverity.error,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      }
    }

    nameController.dispose();
    groupsController.dispose();
  }

  Future<void> _showEditCourseDialog(BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final groupsController = TextEditingController(
      text: (data['groups'] as List<dynamic>)
          .map((e) => e.toString())
          .join(', ')
    );
    DateTime startDate = (data['start'] as Timestamp).toDate();
    DateTime endDate = (data['end'] as Timestamp).toDate();
    int selectedSemester = data['semester'] ?? 1;
    List<String> specialties = [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('specialisations')
          .orderBy('number')
          .get();
      specialties = snapshot.docs
          .map((doc) => (doc.data()['name'] as String))
          .toList();
    } catch (e) {
      debugPrint('Error loading specialties: $e');
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Редагування курсу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Спеціальність', 
              child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, setState) {
                String? selectedSpecialty = nameController.text;
                return ComboBox<String>(
                isExpanded: true,
                value: selectedSpecialty,
                items: specialties.map<ComboBoxItem<String>>((name) {
                return ComboBoxItem<String>(
                  value: name,
                  child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  ),
                );
                }).toList(),
                onChanged: (value) {
                if (value != null) {
                  setState(() {
                  selectedSpecialty = value;
                  nameController.text = value;
                  });
                }
                },
                placeholder: const Text('Оберіть спеціальність'),
                );
                }
              ),
              ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Семестр',
              child: StatefulBuilder(
                builder: (context, setState) {
                  return ComboBox<int>(
                    value: selectedSemester,
                    items: [1, 2, 3, 4, 5, 6, 7, 8].map((semester) {
                      return ComboBoxItem<int>(
                        value: semester,
                        child: Text('$semester семестр'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSemester = value;
                        });
                      }
                    },
                  );
                }
              ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Початок',
              child: StatefulBuilder(
                builder: (context, setDateState) {
                  return DatePicker(
                    selected: startDate,
                    onChanged: (date) {
                      setDateState(() {
                        startDate = date;
                      });
                    },
                  );
                }
              ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Кінець',
                child: StatefulBuilder(
                builder: (context, setDateState) {
                  return DatePicker(
                  selected: endDate,
                  onChanged: (date) {
                    setDateState(() {
                    endDate = date;
                    });
                  },
                  );
                }
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Групи (через кому)',
              child: TextBox(
                controller: groupsController,
                placeholder: 'Наприклад: 401, 402, 403',
              ),
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
            child: const Text('Зберегти'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final groups = groupsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map((e) => int.parse(e)) // Convert to integers
            .toList();

        await doc.reference.update({
          'name': nameController.text,
          'semester': selectedSemester,
          'start': Timestamp.fromDate(startDate),
          'end': Timestamp.fromDate(endDate),
          'groups': groups, // Now storing as List<int>
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Курс оновлено'),
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
              content: Text(e is FormatException 
                ? 'Номери груп мають бути числами' 
                : e.toString()),
              severity: InfoBarSeverity.error,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      }
    }

    nameController.dispose();
    groupsController.dispose();
  }

  Future<void> _deleteCourse(BuildContext context, DocumentSnapshot doc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалення курсу'),
        content: const Text('Ви впевнені, що хочете видалити цей курс?'),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red.light),
            ),
            child: const Text('Видалити'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await doc.reference.delete();
        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Курс видалено'),
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
      }
    }
  }

  Widget _buildEventsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .orderBy('end', descending: true)
          .snapshots(),
      builder: (context, coursesSnapshot) {
        if (coursesSnapshot.hasError) {
          return Center(child: Text('Помилка: ${coursesSnapshot.error}'));
        }

        if (coursesSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        }

        final courses = coursesSnapshot.data!.docs;
        final now = DateTime.now();
        
        // Розділяємо курси на активні та архівні
        final activeCourses = courses.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['end'] as Timestamp).toDate().isAfter(now);
        }).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .snapshots(),
          builder: (context, eventTypesSnapshot) {
            if (eventTypesSnapshot.hasError) {
              return Center(child: Text('Помилка: ${eventTypesSnapshot.error}'));
            }

            if (eventTypesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: ProgressRing());
            }

            final eventTypes = eventTypesSnapshot.data!.docs;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Події',
                        style: FluentTheme.of(context).typography.title,
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        child: const Text('Створити подію'),
                        onPressed: () => _showCreateEventDialog(
                          context, 
                          activeCourses,
                          eventTypes,
                        ),
                      ),
                    ],
                  ),
                  ...activeCourses.map((course) {
                    final courseData = course.data() as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${courseData['name']} (${courseData['groups'].join(", ")})',
                          style: FluentTheme.of(context).typography.subtitle,
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream: course.reference
                              .collection('events')
                              .orderBy('start')
                              .snapshots(),
                          builder: (context, eventsSnapshot) {
                            if (eventsSnapshot.hasError) {
                              return Text('Помилка: ${eventsSnapshot.error}');
                            }

                            if (eventsSnapshot.connectionState == ConnectionState.waiting) {
                              return const ProgressRing();
                            }

                            final events = eventsSnapshot.data!.docs;
                            
                            if (events.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text('Немає подій'),
                              );
                            }

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: events.map((event) {
                                final eventData = event.data() as Map<String, dynamic>;
                                final eventType = eventTypes
                                    .where((t) => t.id == eventData['type'])
                                    .firstOrNull;
                                final typeData = eventType?.data() as Map<String, dynamic>? ?? {'name': 'Невідомий тип'};
                                
                                return SizedBox(
                                  width: 300,
                                  child: Card(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          eventData['name'] ?? '',
                                          style: FluentTheme.of(context).typography.subtitle,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          typeData['name'] ?? '',
                                          style: FluentTheme.of(context).typography.body,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          eventData['description'] ?? '',
                                          style: FluentTheme.of(context).typography.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Початок: ${DateFormat('dd.MM.yyyy').format((eventData['start'] as Timestamp).toDate())}',
                                        ),
                                        Text(
                                          'Кінець: ${DateFormat('dd.MM.yyyy').format((eventData['end'] as Timestamp).toDate())}',
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            FilledButton(
                                              child: const Text('Редагувати'),
                                              onPressed: () => _showEditEventDialog(
                                                context,
                                                course.reference,
                                                event,
                                                eventTypes,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton(
                                              style: ButtonStyle(
                                                backgroundColor: WidgetStateProperty.all(
                                                  Colors.red.light,
                                                ),
                                              ),
                                              child: const Text('Видалити'),
                                              onPressed: () => _deleteEvent(
                                                context,
                                                course.reference,
                                                event,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  Text(
                    'Типи подій',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ...eventTypes.map((type) {
                        final data = type.data() as Map<String, dynamic>;
                        return SizedBox(
                          width: 300,
                          height: 150,
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                Text(
                                  data['name'] ?? '',
                                  style: FluentTheme.of(context).typography.subtitle,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['description'] ?? '',
                                  style: FluentTheme.of(context).typography.body,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                  FilledButton(
                                    child: const Text('Редагувати'),
                                    onPressed: () => _showEditEventTypeDialog(
                                    context, 
                                    type,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                      Colors.red.light,
                                    ),
                                    ),
                                    child: const Text('Видалити'),
                                    onPressed: () => _deleteEventType(
                                    context, 
                                    type,
                                    ),
                                  ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      GestureDetector(
                        onTap: () => _showCreateEventTypeDialog(context),
                        child: SizedBox(
                          width: 300,
                          height: 150,
                          child: Card(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  FluentIcons.add,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text('Новий тип подій'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Event Type Management Methods
  Future<void> _showCreateEventTypeDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Створення типу подій'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву типу',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис типу',
                maxLines: 3,
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
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance.collection('events').add({
          'name': nameController.text,
          'description': descriptionController.text,
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Тип подій створено'),
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
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditEventTypeDialog(BuildContext context, DocumentSnapshot type) async {
    final data = type.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final descriptionController = TextEditingController(text: data['description']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Редагування типу подій'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву типу',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис типу',
                maxLines: 3,
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
            child: const Text('Зберегти'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await type.reference.update({
          'name': nameController.text,
          'description': descriptionController.text,
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Тип подій оновлено'),
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
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteEventType(BuildContext context, DocumentSnapshot type) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалення типу подій'),
        content: const Text('Ви впевнені, що хочете видалити цей тип подій?'),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red.light),
            ),
            child: const Text('Видалити'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await type.reference.delete();
        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Тип подій видалено'),
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
      }
    }
  }

  // Event Management Methods
  Future<void> _showCreateEventDialog(
    BuildContext context,
    List<DocumentSnapshot> courses,
    List<DocumentSnapshot> eventTypes,
  ) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedTypeId = eventTypes.isNotEmpty ? eventTypes.first.id : null;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Створення події'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву події',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Тип події',
              child: StatefulBuilder(
                builder: (context, setState) => ComboBox<String>(
                value: selectedTypeId,
                items: eventTypes.map((type) {
                  final typeData = type.data() as Map<String, dynamic>;
                  return ComboBoxItem<String>(
                  value: type.id,
                  child: Text(typeData['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedTypeId = value);
                },
                ),
              ),
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис події',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Початок',
              child: StatefulBuilder(
                builder: (context, setDateState) => DatePicker(
                selected: startDate,
                onChanged: (date) => setDateState(() => startDate = date),
                ),
              ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Кінець',
              child: StatefulBuilder(
                builder: (context, setDateState) => DatePicker(
                selected: endDate,
                onChanged: (date) => setDateState(() => endDate = date),
                ),
              ),
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
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && selectedTypeId != null) {
      try {
        for (final course in courses) {
          await course.reference.collection('events').add({
            'name': nameController.text,
            'type': selectedTypeId,
            'description': descriptionController.text,
            'start': Timestamp.fromDate(startDate),
            'end': Timestamp.fromDate(endDate),
          });
        }

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Подію створено'),
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
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showEditEventDialog(
    BuildContext context,
    DocumentReference courseRef,
    DocumentSnapshot event,
    List<DocumentSnapshot> eventTypes,
  ) async {
    final data = event.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final descriptionController = TextEditingController(text: data['description']);
    String? selectedTypeId = data['type'];
    DateTime startDate = (data['start'] as Timestamp).toDate();
    DateTime endDate = (data['end'] as Timestamp).toDate();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Редагування події'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва',
              child: TextBox(
                controller: nameController,
                placeholder: 'Введіть назву події',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Тип події',
              child: StatefulBuilder(
                builder: (context, setState) => ComboBox<String>(
                value: selectedTypeId,
                items: eventTypes.map((type) {
                  final typeData = type.data() as Map<String, dynamic>;
                  return ComboBoxItem<String>(
                  value: type.id,
                  child: Text(typeData['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedTypeId = value);
                },
                ),
              ),
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Опис',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Введіть опис події',
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Початок',
              child: StatefulBuilder(
                builder: (context, setDateState) => DatePicker(
                selected: startDate,
                onChanged: (date) => setDateState(() => startDate = date),
                ),
              ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InfoLabel(
              label: 'Кінець',
              child: StatefulBuilder(
                builder: (context, setDateState) => DatePicker(
                selected: endDate,
                onChanged: (date) => setDateState(() => endDate = date),
                ),
              ),
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
            child: const Text('Зберегти'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && selectedTypeId != null) {
      try {
        await event.reference.update({
          'name': nameController.text,
          'type': selectedTypeId,
          'description': descriptionController.text,
          'start': Timestamp.fromDate(startDate),
          'end': Timestamp.fromDate(endDate),
        });

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Подію оновлено'),
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
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteEvent(
    BuildContext context,
    DocumentReference courseRef,
    DocumentSnapshot event,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалення події'),
        content: const Text('Ви впевнені, що хочете видалити цю подію?'),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red.light),
            ),
            child: const Text('Видалити'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await event.reference.delete();
        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Подію видалено'),
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
      }
    }
  }

  Widget _buildScheduleView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .orderBy('end', descending: true)
          .where('end', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Помилка: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        }

        final courses = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: courses.expand((course) {
              final courseData = course.data() as Map<String, dynamic>;
              final groups = (courseData['groups'] as List<dynamic>).cast<int>();
              
              return groups.map((group) {
                return SizedBox(
                  width: 300,
                  height: 200,
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Група $group',
                              style: FluentTheme.of(context).typography.title,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              courseData['name'],
                              style: FluentTheme.of(context).typography.body,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            FilledButton(
                              child: const Text('Редагувати'),
                              onPressed: () => _showScheduleEditor(
                                context, 
                                course.reference, 
                                group,
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(Colors.red.light),
                              ),
                              child: const Text('Очистити'),
                              onPressed: () => _clearSchedule(
                                context, 
                                course.reference, 
                                group,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              });
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _clearSchedule(
    BuildContext context, 
    DocumentReference courseRef, 
    int group,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: Text('Очистити розклад групи $group'),
        content: const Text('Ви впевнені, що хочете видалити весь розклад для цієї групи?'),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red.light),
            ),
            child: const Text('Очистити'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await courseRef
            .collection('schedule')
            .doc(group.toString())
            .delete();

        if (!mounted) return;
        await displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: const Text('Розклад очищено'),
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
      }
    }
  }

  Future<void> _showScheduleEditor(BuildContext context, DocumentReference courseRef, int group) async {
  final schedule = await courseRef
      .collection('schedule')
      .doc(group.toString())
      .get();

  final scheduleData = schedule.data() ?? {};
  
  // Get all subjects and teachers
  final subjects = <String, Map<String, dynamic>>{};
  final teachers = <String, Map<String, dynamic>>{};

  // Load subjects
  final commissionsSnapshot = await FirebaseFirestore.instance
      .collection('cyclecommission')
      .get();
      
  for (var commission in commissionsSnapshot.docs) {
    final subjectsSnapshot = await commission.reference
        .collection('subjects')
        .get();
    
    for (var doc in subjectsSnapshot.docs) {
      subjects[doc.id] = {
        'name': doc.data()['name'] as String,
        'ref': doc.reference,
      };
    }
  }

  // Load teachers
  final teachersSnapshot = await FirebaseFirestore.instance
      .collection('teachers')
      .get();
  
  for (var doc in teachersSnapshot.docs) {
    teachers[doc.id] = {
      'name': '${doc.data()['name']} ${doc.data()['surname']}',
      'ref': doc.reference,
    };
  }

  final days = ['Понеділок', 'Вівторок', 'Середа', 'Четвер', "П'ятниця"];
  final lessons = ['1', '2', '3', '4'];
  
  final selectedLessons = <String, Map<String, Map<String, dynamic>>>{};
  for (var day in days) {
    selectedLessons[day] = {};
    for (var lesson in lessons) {
      final lessonData = scheduleData[day]?[lesson] ?? {};
      selectedLessons[day]![lesson] = {
        'subjectId': lessonData['subjectId'],
        'teacherId': lessonData['teacherId'],
        'room': lessonData['room'],
      };
    }
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ContentDialog(
      constraints: const BoxConstraints(maxWidth: 1300),
      title: Text('Розклад для групи $group'),
      content: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: days.map((day) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 8),
                    ...lessons.map((lesson) {
                      final lessonData = selectedLessons[day]![lesson]!;
                      final roomController = TextEditingController(
                        text: lessonData['room']?.toString() ?? '',
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$lesson пара'),
                            const SizedBox(height: 4),
                            StatefulBuilder(
                              builder: (context, setState) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ComboBox<String?>(
                                      isExpanded: true,
                                      placeholder: const Text('-'),
                                      value: lessonData['subjectId'],
                                      items: [
                                        const ComboBoxItem<String?>(
                                        value: null,
                                        child: Text('Немає пари'),
                                        ),
                                        ...subjects.entries.map(
                                        (entry) => ComboBoxItem<String>(
                                        value: entry.key,
                                        child: Text(entry.value['name']),
                                        ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                        lessonData['subjectId'] = value;
                                        });
                                      },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Flexible(
                                          flex: 3,
                                          child: ComboBox<String?>(
                                            isExpanded: true,
                                            placeholder: const Text('-'),
                                            value: lessonData['teacherId'],
                                            items: [
                                              const ComboBoxItem<String?>(
                                                value: null,
                                                child: Text('Не призначено'),
                                              ),
                                              ...teachers.entries.map(
                                                (entry) => ComboBoxItem<String>(
                                                  value: entry.key,
                                                  child: Text(
                                                    entry.value['name'],
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                lessonData['teacherId'] = value;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          flex: 1,
                                          child: SizedBox(
                                            child: TextBox(
                                              controller: roomController,
                                              placeholder: 'Ауд.',
                                              onChanged: (value) {
                                                lessonData['room'] = value;
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        Button(
          child: const Text('Скасувати'),
          onPressed: () => Navigator.pop(context, false),
        ),
        FilledButton(
          child: const Text('Зберегти'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );

  if (result == true) {
    try {
      await courseRef
          .collection('schedule')
          .doc(group.toString())
          .set(selectedLessons);

      if (!mounted) return;
      await displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Успіх'),
            content: const Text('Розклад збережено'),
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
    }
  }
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
            icon: const Icon(FluentIcons.education),
            title: const Text('Курси'),
            body: _buildCoursesView(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.table),
            title: const Text('Розклад'),
            body: _buildScheduleView(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.calendar),
            title: const Text('Події'),
            body: _buildEventsView(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.college_hoops),
            title: const Text('Дисципліни'),
            body: _buildDisciplinesView(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.c_r_m_report),
            title: const Text('Циклові комісії'),
            body: _buildCycleCommissionsView(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.developer_tools),
            title: const Text('Спеціальності'),
            body: _buildSpecialisationsView(),
          ),
            PaneItem(
            icon: const Icon(FluentIcons.clock),
            title: const Text('Дзвінок'),
            body: _buildBellSchedule(),
          ),
        ],
      ),
    );
  }
}