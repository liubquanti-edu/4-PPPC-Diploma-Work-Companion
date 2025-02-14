import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({Key? key}) : super(key: key);

  @override
  _AppearanceSettingsScreenState createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  // Замість TextEditingController використовуємо ValueNotifier
  late final ValueNotifier<String?> _stopIdNotifier;

  @override
  void initState() {
    super.initState();
    // Ініціалізуємо нотіфаєр початковим значенням
    _stopIdNotifier = ValueNotifier(
      Provider.of<ThemeProvider>(context, listen: false).stopId
    );
  }

  @override
  void dispose() {
    _stopIdNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Зовнішній вигляд'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(10.0),
            children: [
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Тема',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      RadioListTile(
                        title: const Text('Системна'),
                        value: ThemeMode.system,
                        groupValue: themeProvider.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeProvider.setThemeMode(value);
                          }
                        },
                      ),
                      RadioListTile(
                        title: const Text('Світла'),
                        value: ThemeMode.light,
                        groupValue: themeProvider.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeProvider.setThemeMode(value);
                          }
                        },
                      ),
                      RadioListTile(
                        title: const Text('Темна'),
                        value: ThemeMode.dark,
                        groupValue: themeProvider.themeMode,
                        onChanged: (ThemeMode? value) {
                          if (value != null) {
                            themeProvider.setThemeMode(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Динамічні кольори',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SwitchListTile(
                        title: const Text('Системний колір'),
                        subtitle: const Text('Доступно на Android 12+'),
                        value: themeProvider.useDynamicColors,
                        onChanged: (bool value) {
                          themeProvider.setDynamicColors(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Стіна за замовчуванням',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      RadioListTile(
                        title: const Text('Потік'),
                        value: 0,
                        groupValue: themeProvider.defaultContactTab,
                        onChanged: (int? value) {
                          if (value != null) {
                            themeProvider.setDefaultContactTab(value);
                          }
                        },
                      ),
                      RadioListTile(
                        title: const Text('Стежу'),
                        value: 1,
                        groupValue: themeProvider.defaultContactTab,
                        onChanged: (int? value) {
                          if (value != null) {
                            themeProvider.setDefaultContactTab(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Розклад транспорту',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<String?>(
                        valueListenable: _stopIdNotifier,
                        builder: (context, stopId, _) {
                          return TextFormField(
                            initialValue: stopId,
                            decoration: InputDecoration(
                              labelText: 'ID зупинки',
                              helperText: 'ID зупинки для відображення розкладу на головному екрані',
                              border: const OutlineInputBorder(),
                              suffixIcon: stopId != null ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _stopIdNotifier.value = null;
                                  themeProvider.setStopId(null);
                                },
                              ) : null,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && !RegExp(r'^\d+$').hasMatch(value)) {
                                return 'ID має містити лише цифри';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.isEmpty) {
                                _stopIdNotifier.value = null;
                                themeProvider.setStopId(null);
                              } else if (RegExp(r'^\d+$').hasMatch(value)) {
                                _stopIdNotifier.value = value;
                                themeProvider.setStopId(value);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}