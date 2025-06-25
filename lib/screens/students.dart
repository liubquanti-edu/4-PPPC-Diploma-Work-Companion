import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/window_buttons.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _registeredSearchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _registeredSearchFocusNode = FocusNode();
  String _searchQuery = '';
  String _registeredSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _registeredSearchController.dispose();
    _registeredSearchFocusNode.dispose();
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
          PaneItem(
            icon: const Icon(FluentIcons.account_management),
            title: const Text('Студенти'),
            body: _buildRegisteredStudentsTab(),
          ),
          // Тут можна додати інші вкладки за необхідністю
        ],
      ),
    );
  }

  // Залишаємо існуючий метод _buildPeopleTab без змін

  Widget _buildPeopleTab() {
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
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextBox(
              controller: _searchController,
              focusNode: _searchFocusNode,
              placeholder: 'Пошук за іменем, прізвищем, email або групою',
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
            child: _buildPeopleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleList() {
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

        final allPeople = snapshot.data!.docs;
        
        // Фільтруємо дані на основі пошукового запиту
        final people = _searchQuery.isEmpty 
            ? allPeople 
            : allPeople.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final surname = (data['surname'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final group = data['group'] != null ? data['group'].toString().toLowerCase() : '';
                
                final query = _searchQuery.toLowerCase();
                
                return name.contains(query) || 
                      surname.contains(query) || 
                      email.contains(query) ||
                      group.contains(query) ||
                      '$surname $name'.contains(query);
              }).toList();

        return people.isEmpty
            ? Center(
                child: Text(
                  allPeople.isEmpty
                      ? 'Немає зареєстрованих користувачів'
                      : 'Нічого не знайдено за запитом "$_searchQuery"',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

  // Новий метод для вкладки зареєстрованих студентів
  Widget _buildRegisteredStudentsTab() {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Зареєстровані студенти'),
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextBox(
              controller: _registeredSearchController,
              focusNode: _registeredSearchFocusNode,
              placeholder: 'Пошук за іменем, прізвищем, нікнеймом або групою',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(FluentIcons.search),
              ),
              suffix: _registeredSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(FluentIcons.clear),
                      onPressed: () {
                        _registeredSearchController.clear();
                        setState(() {
                          _registeredSearchQuery = '';
                        });
                        _registeredSearchFocusNode.requestFocus();
                      },
                    )
                  : null,
              onChanged: (value) {
                setState(() {
                  _registeredSearchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _buildRegisteredStudentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredStudentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .orderBy('surname')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Помилка: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        }

        final allStudents = snapshot.data!.docs;
        
        // Фільтруємо дані на основі пошукового запиту
        final students = _registeredSearchQuery.isEmpty 
            ? allStudents 
            : allStudents.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final surname = (data['surname'] ?? '').toString().toLowerCase();
                final nickname = (data['nickname'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final group = data['group'] != null ? data['group'].toString().toLowerCase() : '';
                
                final query = _registeredSearchQuery.toLowerCase();
                
                return name.contains(query) || 
                      surname.contains(query) || 
                      nickname.contains(query) ||
                      email.contains(query) ||
                      group.contains(query) ||
                      '$surname $name'.contains(query);
              }).toList();

        return students.isEmpty
            ? Center(
                child: Text(
                  allStudents.isEmpty
                      ? 'Немає зареєстрованих студентів'
                      : 'Нічого не знайдено за запитом "$_registeredSearchQuery"',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final data = student.data() as Map<String, dynamic>;
                    
                    // Форматуємо дату останнього входу
                    String lastSeenText = 'Немає даних';
                    if (data['lastSeen'] != null) {
                      final lastSeen = (data['lastSeen'] as Timestamp).toDate();
                      lastSeenText = DateFormat('dd.MM.yyyy HH:mm').format(lastSeen);
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Аватар студента (якщо є)
                            if (data['avatar'] != null && (data['avatar'] as String).isNotEmpty)
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(data['avatar']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                FluentIcons.contact,
                                size: 50,
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
                                  if ((data['nickname'] ?? '').isNotEmpty)
                                    Text(
                                      '@${data['nickname']}',
                                      style: FluentTheme.of(context).typography.bodyStrong,
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
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Останній вхід: $lastSeenText',
                                    style: FluentTheme.of(context).typography.caption,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Button(
                                  child: const Text('Деталі'),
                                  onPressed: () => _showStudentDetailsDialog(context, student.id, data),
                                ),
                                const SizedBox(width: 8.0),
                                FilledButton(
                                  style: ButtonStyle(
                                    backgroundColor: ButtonState.all(Colors.red),
                                  ),
                                  child: const Text('Видалити'),
                                  onPressed: () => _showDeleteStudentDialog(context, student.id, data),
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

  Future<void> _showStudentDetailsDialog(BuildContext context, String studentId, Map<String, dynamic> data) async {
    // Форматуємо дату створення профілю
    String createdAtText = 'Немає даних';
    if (data['createdAt'] != null) {
      final createdAt = (data['createdAt'] as Timestamp).toDate();
      createdAtText = DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
    }
    
    // Форматуємо дату останнього входу
    String lastSeenText = 'Немає даних';
    if (data['lastSeen'] != null) {
      final lastSeen = (data['lastSeen'] as Timestamp).toDate();
      lastSeenText = DateFormat('dd.MM.yyyy HH:mm').format(lastSeen);
    }

    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    // Створюємо контролери для редагованих полів
    final nameController = TextEditingController(text: data['name'] ?? '');
    final surnameController = TextEditingController(text: data['surname'] ?? '');
    final nicknameController = TextEditingController(text: data['nickname'] ?? '');
    final emailController = TextEditingController(text: data['email'] ?? '');
    final groupController = TextEditingController(
      text: data['group'] != null ? data['group'].toString() : '',
    );

    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text('Інформація про студента: ${data['surname'] ?? ''} ${data['name'] ?? ''}'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Аватар студента
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.2),
                      image: data['avatar'] != null && (data['avatar'] as String).isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(data['avatar']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: data['avatar'] == null || (data['avatar'] as String).isEmpty
                        ? const Center(child: Icon(FluentIcons.contact, size: 60, color: Color(0xFF0078D4)))
                        : null,
                  ),
                ),
                
                // Поля, які можна редагувати
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
                  label: 'Нікнейм',
                  child: TextBox(
                    controller: nicknameController,
                    placeholder: 'Введіть нікнейм',
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

                // Поля, які не можна змінити
                const SizedBox(height: 20.0),
                const Text(
                  'Інформація, яку не можна змінити:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10.0),
                
                InfoLabel(
                  label: 'Контактний email',
                  child: TextBox(
                    placeholder: 'Не вказано',
                    enabled: false,
                    controller: TextEditingController(text: data['contactemail'] ?? ''),
                  ),
                ),
                const SizedBox(height: 8.0),
                
                InfoLabel(
                  label: 'Контактний номер',
                  child: TextBox(
                    placeholder: 'Не вказано',
                    enabled: false,
                    controller: TextEditingController(text: data['contactnumber'] ?? ''),
                  ),
                ),
                const SizedBox(height: 8.0),
                
                InfoLabel(
                  label: 'Дата реєстрації',
                  child: TextBox(
                    placeholder: 'Немає даних',
                    enabled: false,
                    controller: TextEditingController(text: createdAtText),
                  ),
                ),
                const SizedBox(height: 8.0),
                
                InfoLabel(
                  label: 'Останній вхід',
                  child: TextBox(
                    placeholder: 'Немає даних',
                    enabled: false,
                    controller: TextEditingController(text: lastSeenText),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Зберегти зміни'),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Оновлюємо дані студента у Firebase
                await FirebaseFirestore.instance.collection('students').doc(studentId).update({
                  'name': nameController.text,
                  'surname': surnameController.text,
                  'nickname': nicknameController.text,
                  'email': emailController.text,
                  'group': groupController.text.isNotEmpty 
                    ? int.parse(groupController.text) 
                    : null,
                });
                
                // Перевіряємо, чи контекст все ще валідний
                if (!scaffoldContext.mounted) return;
                
                // Показуємо повідомлення про успіх
                await displayInfoBar(
                  scaffoldContext,
                  builder: (context, close) {
                    return InfoBar(
                      title: const Text('Успіх'),
                      content: Text('Дані студента ${surnameController.text} ${nameController.text} оновлено'),
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
                
                // Показуємо повідомлення про помилку
                await displayInfoBar(
                  scaffoldContext,
                  builder: (context, close) {
                    return InfoBar(
                      title: const Text('Помилка'),
                      content: Text('Не вдалося оновити дані: ${e.toString()}'),
                      severity: InfoBarSeverity.error,
                      action: IconButton(
                        icon: const Icon(FluentIcons.clear),
                        onPressed: close,
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );

    // Видаляємо контролери
    nameController.dispose();
    surnameController.dispose();
    nicknameController.dispose();
    emailController.dispose();
    groupController.dispose();
  }

  // Додаємо новий метод для діалогу видалення студента
  Future<void> _showDeleteStudentDialog(BuildContext context, String studentId, Map<String, dynamic> data) async {
    final scaffoldContext = context;
    final studentName = '${data['surname']} ${data['name']}';
    final studentEmail = data['email'];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалити студента'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ви дійсно хочете видалити студента "$studentName"?'),
            const SizedBox(height: 12),
            const Text(
              'Увага: Цей студент також буде видалений із загального списку людей, якщо там є запис з такою ж електронною поштою.',
              style: TextStyle(color: Color(0xFFE81123)),
            ),
          ],
        ),
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
        // Показуємо індикатор завантаження
        showDialog(
          context: scaffoldContext,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const ContentDialog(
              title: Text('Обробка'),
              content: SizedBox(
                height: 100,
                child: Center(child: ProgressRing()),
              ),
            );
          },
        );
        
        // 1. Видаляємо студента з колекції 'students'
        await FirebaseFirestore.instance.collection('students').doc(studentId).delete();
        
        // 2. Шукаємо і видаляємо відповідний запис у колекції 'people' з такою ж поштою
        if (studentEmail != null && studentEmail.isNotEmpty) {
          final peopleQuery = await FirebaseFirestore.instance
              .collection('people')
              .where('email', isEqualTo: studentEmail)
              .get();
          
          for (final personDoc in peopleQuery.docs) {
            await personDoc.reference.delete();
          }
        }
        
        // Закриваємо діалог завантаження
        if (scaffoldContext.mounted) {
          Navigator.of(scaffoldContext).pop();
        }
        
        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        // Показуємо повідомлення про успіх
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('Студента $studentName видалено'),
              severity: InfoBarSeverity.success,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      } catch (e) {
        // Закриваємо діалог завантаження, якщо виникла помилка
        if (scaffoldContext.mounted) {
          Navigator.of(scaffoldContext).pop();
        }
        
        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        // Показуємо повідомлення про помилку
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Помилка'),
              content: Text('Не вдалося видалити студента: ${e.toString()}'),
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