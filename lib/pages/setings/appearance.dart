import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class AppearanceSettings extends StatelessWidget {
  const AppearanceSettings({Key? key}) : super(key: key);

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
            ],
          );
        },
      ),
    );
  }
}