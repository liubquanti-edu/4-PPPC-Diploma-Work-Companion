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
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Тема',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
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
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Динамічні кольори',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Використовувати кольори системи'),
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
            ],
          );
        },
      ),
    );
  }
}