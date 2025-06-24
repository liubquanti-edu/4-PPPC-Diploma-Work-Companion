import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/window_buttons.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: true,
        title: MoveWindow(
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text('Викладачі'),
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
            title: const Text('Контакти'),
            body: _buildTeachersTab(),
          ),
          // Тут можна додати інші вкладки за необхідністю
        ],
      ),
    );
  }

  Widget _buildTeachersTab() {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Контакти'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Додати контакт'),
              onPressed: () => _showAddTeacherDialog(context),
            ),
          ],
        ),
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextBox(
              controller: _searchController,
              focusNode: _searchFocusNode,
              placeholder: 'Пошук за іменем, прізвищем, email або телефоном',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(FluentIcons.search),
              ),
              suffix: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(FluentIcons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _searchFocusNode.requestFocus();
                      },
                    )
                  : null,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _buildTeachersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers')
          .orderBy('surname')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Помилка: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        }

        final allTeachers = snapshot.data!.docs;
        
        // Фільтруємо дані на основі пошукового запиту
        final teachers = _searchQuery.isEmpty 
            ? allTeachers 
            : allTeachers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final surname = (data['surname'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final phone = (data['phone'] ?? '').toString().toLowerCase();
                
                final query = _searchQuery.toLowerCase();
                
                return name.contains(query) || 
                      surname.contains(query) || 
                      email.contains(query) ||
                      phone.contains(query) ||
                      '$surname $name'.contains(query);
              }).toList();

        return teachers.isEmpty
            ? Center(
                child: Text(
                  allTeachers.isEmpty
                      ? 'Немає зареєстрованих викладачів'
                      : 'Нічого не знайдено за запитом "$_searchQuery"',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.builder(
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    final data = teacher.data() as Map<String, dynamic>;
                    
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
                                    'Телефон: ${data['phone'] ?? 'Не вказано'}',
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
                                  onPressed: () => _showEditTeacherDialog(context, teacher),
                                ),
                                const SizedBox(width: 8.0),
                                FilledButton(
                                  style: ButtonStyle(
                                    backgroundColor: ButtonState.all(Colors.red),
                                  ),
                                  child: const Text('Видалити'),
                                  onPressed: () => _showDeleteTeacherDialog(context, teacher),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
      },
    );
  }

  Future<void> _showAddTeacherDialog(BuildContext context) async {
    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    final nameController = TextEditingController();
    final surnameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Додати контакт'),
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
              label: 'Телефон',
              child: TextBox(
                controller: phoneController,
                placeholder: 'Введіть номер телефону',
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
        if (nameController.text.isEmpty || surnameController.text.isEmpty) {
          throw Exception("Ім'я та прізвище обов'язкові для заповнення");
        }
        
        // Додаємо контакт у Firebase
        await FirebaseFirestore.instance.collection('teachers').add({
          'name': nameController.text,
          'surname': surnameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
        });

        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('контакт ${nameController.text} ${surnameController.text} додано'),
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
              content: Text('Не вдалося додати контакт: ${e.toString()}'),
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
    phoneController.dispose();
  }

  Future<void> _showEditTeacherDialog(BuildContext context, DocumentSnapshot teacher) async {
    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    final data = teacher.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final surnameController = TextEditingController(text: data['surname']);
    final emailController = TextEditingController(text: data['email']);
    final phoneController = TextEditingController(text: data['phone']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Редагувати контакт'),
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
              label: 'Телефон',
              child: TextBox(
                controller: phoneController,
                placeholder: 'Введіть номер телефону',
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
        if (nameController.text.isEmpty || surnameController.text.isEmpty) {
          throw Exception("Ім'я та прізвище обов'язкові для заповнення");
        }
        
        // Оновлюємо дані контакт
        await teacher.reference.update({
          'name': nameController.text,
          'surname': surnameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
        });

        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('Дані контакту ${nameController.text} ${surnameController.text} оновлено'),
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
              content: Text('Не вдалося оновити дані контакту: ${e.toString()}'),
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
    phoneController.dispose();
  }

  Future<void> _showDeleteTeacherDialog(BuildContext context, DocumentSnapshot teacher) async {
    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    final data = teacher.data() as Map<String, dynamic>;
    final teacherName = '${data['surname']} ${data['name']}';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалити контакт'),
        content: Text('Ви дійсно хочете видалити контакт "$teacherName"?'),
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
        // Видаляємо контакт
        await teacher.reference.delete();

        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('контакт $teacherName видалено'),
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
              content: Text('Не вдалося видалити контакт: ${e.toString()}'),
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