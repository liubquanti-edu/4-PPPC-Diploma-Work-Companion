//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../providers/theme_provider.dart';
import '../transport/select_stop.dart';
import '../../config/map_config.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({Key? key}) : super(key: key);

  @override
  _AppearanceSettingsScreenState createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  final TextEditingController _stopIdController = TextEditingController();
  Map<String, dynamic> _stations = {};

  @override
  void initState() {
    super.initState();
    _stopIdController.text = Provider.of<ThemeProvider>(context, listen: false).stopId ?? '';
    _loadStations();
  }

  Future<void> _loadStations() async {
    final String response = await rootBundle.loadString('assets/json/stations.json');
    if (mounted) {
      setState(() {
        _stations = json.decode(response);
      });
    }
  }

  @override
  void dispose() {
    _stopIdController.dispose();
    super.dispose();
  }

  Widget _buildMapStyleSection(ThemeProvider themeProvider) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Стиль мапи',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...MapStyles.available.map((style) => 
              RadioListTile<String>(
              value: style.id,
              groupValue: themeProvider.mapStyle,
              onChanged: (String? value) {
                if (value != null) {
                themeProvider.setMapStyle(value);
                }
              },
              title: Text(style.name),
              secondary: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                'assets/img/map-styles/${style.id}.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Зовнішній вигляд'),
        centerTitle: true,
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
                      ...themeProvider.stopIds.map((stopId) {
                        final stopName = _stations[stopId]?[2] ?? 'Зупинка №$stopId';
                        return Container(
                          child: ListTile(
                            title: Text(stopName),
                            subtitle: Text('ID: $stopId'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => themeProvider.removeStopId(stopId),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                        Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.onSecondary,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () async {
                          final selectedStopId = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                            builder: (context) => StopSelectorScreen(),
                            ),
                          );
                          if (selectedStopId != null) {
                            themeProvider.addStopId(selectedStopId);
                          }
                          },
                          icon: const Icon(Icons.add_location),
                          label: const Text('Додати зупинку'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildMapStyleSection(themeProvider),
            ],
          );
        },
      ),
    );
  }
}