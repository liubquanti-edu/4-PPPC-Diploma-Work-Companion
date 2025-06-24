import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/window_buttons.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: true,
        title: MoveWindow(
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Студенти'),
          ),
        ),
        actions: const WindowButtons(),
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.people),
            title: const Text('Люди'),
            body: _buildPeopleTab(),
          ),
          // Тут можна додати інші вкладки за необхідністю
        ],
      ),
    );
  }

  Widget _buildPeopleTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('people')
          .orderBy('surname')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Помилка: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        }

        final people = snapshot.data!.docs;

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Користувачі'),
            commandBar: CommandBar(
              mainAxisAlignment: MainAxisAlignment.end,
              primaryItems: [
                CommandBarButton(
                  icon: const Icon(FluentIcons.add),
                  label: const Text('Додати користувача'),
                  onPressed: () => _showAddUserDialog(context),
                ),
              ],
            ),
          ),
          content: people.isEmpty
              ? Center(
                  child: Text(
                    'Немає зареєстрованих користувачів',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      final user = people[index];
                      final data = user.data() as Map<String, dynamic>;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                FluentIcons.contact,
                                size: 36,
                                color: Color(0xFF0078D4),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data['surname'] ?? ''} ${data['name'] ?? ''}',
                                      style: FluentTheme.of(context).typography.subtitle,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'Email: ${data['email'] ?? 'Не вказано'}',
                                      style: FluentTheme.of(context).typography.body,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'Група: ${data['group'] ?? 'Не вказано'}',
                                      style: FluentTheme.of(context).typography.body,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Button(
                                    child: const Text('Редагувати'),
                                    onPressed: () => _showEditUserDialog(context, user),
                                  ),
                                  const SizedBox(width: 8.0),
                                  FilledButton(
                                    style: ButtonStyle(
                                      backgroundColor: ButtonState.all(Colors.red),
                                    ),
                                    child: const Text('Видалити'),
                                    onPressed: () => _showDeleteUserDialog(context, user),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    final groupController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Додати користувача'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: "Ім'я",
              child: TextBox(
                controller: nameController,
                placeholder: "Введіть ім'я",
              ),
            ),
            const SizedBox(height: 8.0),
            InfoLabel(
              label: 'Прізвище',
              child: TextBox(
                controller: surnameController,
                placeholder: 'Введіть прізвище',
              ),
            ),
            const SizedBox(height: 8.0),
            InfoLabel(
              label: 'Email',
              child: TextBox(
                controller: emailController,
                placeholder: 'Введіть email',
              ),
            ),
            const SizedBox(height: 8.0),
            InfoLabel(
              label: 'Група',
              child: TextBox(
                controller: groupController,
                placeholder: 'Введіть номер групи',
              ),
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton(
            child: const Text('Додати'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Перевірка на заповненість основних полів
        if (nameController.text.isEmpty || surnameController.text.isEmpty || emailController.text.isEmpty) {
          throw Exception("Ім'я, прізвище та email обов'язкові для заповнення");
        }
        
        // Додаємо користувача у Firebase
        await FirebaseFirestore.instance.collection('people').add({
          'name': nameController.text,
          'surname': surnameController.text,
          'email': emailController.text,
          'group': groupController.text.isNotEmpty ? int.parse(groupController.text) : null,
        });

        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('Користувача ${nameController.text} ${surnameController.text} додано'),
              severity: InfoBarSeverity.success,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      } catch (e) {
        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Помилка'),
              content: Text('Не вдалося додати користувача: ${e.toString()}'),
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
    surnameController.dispose();
    emailController.dispose();
    groupController.dispose();
  }

  Future<void> _showEditUserDialog(BuildContext context, DocumentSnapshot user) async {
    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    final data = user.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final surnameController = TextEditingController(text: data['surname']);
    final emailController = TextEditingController(text: data['email']);
    final groupController = TextEditingController(
      text: data['group'] != null ? data['group'].toString() : '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Редагувати користувача'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: "Ім'я",
              child: TextBox(
                controller: nameController,
                placeholder: "Введіть ім'я",
              ),
            ),
            const SizedBox(height: 8.0),
            InfoLabel(
              label: 'Прізвище',
              child: TextBox(
                controller: surnameController,
                placeholder: 'Введіть прізвище',
              ),
            ),
            const SizedBox(height: 8.0),
            InfoLabel(
              label: 'Email',
              child: TextBox(
                controller: emailController,
                placeholder: 'Введіть email',
              ),
            ),
            const SizedBox(height: 8.0),
            InfoLabel(
              label: 'Група',
              child: TextBox(
                controller: groupController,
                placeholder: 'Введіть номер групи',
              ),
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton(
            child: const Text('Зберегти'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Перевірка на заповненість основних полів
        if (nameController.text.isEmpty || surnameController.text.isEmpty || emailController.text.isEmpty) {
          throw Exception("Ім'я, прізвище та email обов'язкові для заповнення");
        }
        
        // Оновлюємо дані користувача
        await user.reference.update({
          'name': nameController.text,
          'surname': surnameController.text,
          'email': emailController.text,
          'group': groupController.text.isNotEmpty ? int.parse(groupController.text) : null,
        });

        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('Дані користувача ${nameController.text} ${surnameController.text} оновлено'),
              severity: InfoBarSeverity.success,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      } catch (e) {
        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Помилка'),
              content: Text('Не вдалося оновити дані користувача: ${e.toString()}'),
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
    surnameController.dispose();
    emailController.dispose();
    groupController.dispose();
  }

  Future<void> _showDeleteUserDialog(BuildContext context, DocumentSnapshot user) async {
    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    final data = user.data() as Map<String, dynamic>;
    final userName = '${data['surname']} ${data['name']}';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалити користувача'),
        content: Text('Ви дійсно хочете видалити користувача "$userName"?'),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: ButtonState.all(Colors.red),
            ),
            child: const Text('Видалити'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Видаляємо користувача
        await user.reference.delete();

        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('Користувача $userName видалено'),
              severity: InfoBarSeverity.success,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      } catch (e) {
        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Помилка'),
              content: Text('Не вдалося видалити користувача: ${e.toString()}'),
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
}