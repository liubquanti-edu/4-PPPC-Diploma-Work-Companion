import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/window_buttons.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Інформація'),
        actions: WindowTitleBarBox(
          child: Row(
            children: [
              Expanded(child: MoveWindow()),
              const WindowButtons(),
            ],
          ),
        ),
      ),
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.wifi),
            title: const Text('Wi-Fi точки'),
            body: _buildWiFiTab(),
          ),
          // Тут можна додати інші вкладки за потреби
        ],
      ),
    );
  }

  Widget _buildWiFiTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('wifi').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Помилка: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        }

        final wifiNetworks = snapshot.data!.docs;

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Wi-Fi точки доступу'),
            commandBar: CommandBar(
              mainAxisAlignment: MainAxisAlignment.end,
              primaryItems: [
                CommandBarButton(
                  icon: const Icon(FluentIcons.add),
                  label: const Text('Додати мережу'),
                  onPressed: () => _showAddWiFiDialog(context),
                ),
              ],
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: wifiNetworks.isEmpty
                ? Center(
                    child: Text(
                      'Немає збережених мереж WiFi',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      mainAxisExtent: 250,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: wifiNetworks.length,
                    itemBuilder: (context, index) {
                      final network = wifiNetworks[index];
                      final data = network.data() as Map<String, dynamic>;
                      
                      return _buildWiFiCard(
                        context, 
                        network.id,
                        data['ssid'] ?? 'Невідома мережа',
                        data['password'] ?? '',
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildWiFiCard(BuildContext context, String id, String ssid, String password) {
    return SizedBox( 
      width: 300,
      height: 250,
      child: 
        Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(FluentIcons.wifi),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ssid,
                      style: FluentTheme.of(context).typography.subtitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Пароль: '),
                  Expanded(
                    child: Text(
                      password.isNotEmpty 
                        ? (password.length > 2 
                          ? password.substring(0, 2) + '•' * (password.length - 2) 
                          : password)
                        : '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FilledButton(
                    child: const Text('Редагувати'),
                    onPressed: () => _showEditWiFiDialog(context, id, ssid, password),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: ButtonStyle(
                      backgroundColor: ButtonState.all(Colors.red.light),
                    ),
                    child: const Text('Видалити'),
                    onPressed: () => _showDeleteWiFiDialog(context, id, ssid),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddWiFiDialog(BuildContext context) async {
    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Додати WiFi мережу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва мережі (SSID)',
              child: TextBox(
                controller: ssidController,
                placeholder: 'Введіть назву мережі',
              ),
            ),
            const SizedBox(height: 16),
            InfoLabel(
              label: 'Пароль',
              child: TextBox(
                controller: passwordController,
                placeholder: 'Введіть пароль',
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

    if (result == true && ssidController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('wifi').add({
          'ssid': ssidController.text,
          'password': passwordController.text,
        });

        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('WiFi мережу "${ssidController.text}" додано'),
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
              content: Text('Не вдалося додати WiFi мережу: ${e.toString()}'),
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

    ssidController.dispose();
    passwordController.dispose();
  }

  Future<void> _showEditWiFiDialog(BuildContext context, String id, String currentSsid, String currentPassword) async {
    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    final ssidController = TextEditingController(text: currentSsid);
    final passwordController = TextEditingController(text: currentPassword);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Редагувати WiFi мережу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Назва мережі (SSID)',
              child: TextBox(
                controller: ssidController,
                placeholder: 'Введіть назву мережі',
              ),
            ),
            const SizedBox(height: 16),
            InfoLabel(
              label: 'Пароль',
              child: TextBox(
                controller: passwordController,
                placeholder: 'Введіть пароль',
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

    if (result == true && ssidController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('wifi').doc(id).update({
          'ssid': ssidController.text,
          'password': passwordController.text,
        });

        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('WiFi мережу "${ssidController.text}" оновлено'),
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
              content: Text('Не вдалося оновити WiFi мережу: ${e.toString()}'),
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

    ssidController.dispose();
    passwordController.dispose();
  }

  Future<void> _showDeleteWiFiDialog(BuildContext context, String id, String ssid) async {
    // Зберігаємо стабільний контекст
    final scaffoldContext = context;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Видалити WiFi мережу'),
        content: Text('Ви дійсно бажаєте видалити мережу "$ssid"?'),
        actions: [
          Button(
            child: const Text('Скасувати'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: ButtonState.all(Colors.red.light),
            ),
            child: const Text('Видалити'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance.collection('wifi').doc(id).delete();

        // Перевіряємо, чи контекст все ще валідний
        if (!scaffoldContext.mounted) return;
        
        await displayInfoBar(
          scaffoldContext,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Успіх'),
              content: Text('WiFi мережу "$ssid" видалено'),
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
              content: Text('Не вдалося видалити WiFi мережу: ${e.toString()}'),
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