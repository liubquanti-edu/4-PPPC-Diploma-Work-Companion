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
                    padding: const EdgeInsets.all(24),
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
                                backgroundColor: ButtonState.all(Colors.red.light),
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
                  padding: const EdgeInsets.all(24),
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
                    padding: const EdgeInsets.all(24),
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
                                backgroundColor: ButtonState.all(Colors.red.light),
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
                  padding: const EdgeInsets.all(24),
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
                            padding: const EdgeInsets.all(24),
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
                                        backgroundColor: ButtonState.all(Colors.red.light),
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
                            padding: const EdgeInsets.all(24),
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
              backgroundColor: ButtonState.all(Colors.red.light),
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
              backgroundColor: ButtonState.all(Colors.red.light),
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
              backgroundColor: ButtonState.all(Colors.red.light),
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