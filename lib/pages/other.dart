//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './tools/vibration.dart';
import './tools/calculator.dart';
import './tools/translator.dart';
import './tools/notes.dart';
import './settings/settings.dart'; 
import '/models/avatars.dart';
import 'package:pppc_companion/pages/users/user.dart';
import './wifi/wifi.dart';

class OtherPage extends StatelessWidget {
  const OtherPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _auth = FirebaseAuth.instance;
    final _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 20,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('students')
                    .doc(_auth.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(height: 100);
                  }

                  final userData = snapshot.data!.data() as Map<String, dynamic>?;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(
                              userId: _auth.currentUser!.uid,
                              isCurrentUser: true,
                            ),
                          ),
                        );
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Row(
                          children: [
                          SizedBox(
                            height: 50,
                            width: 50,
                            child: CachedAvatar(
                            imageUrl: userData?['avatar'],
                            radius: 25,
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                              '${userData?['surname'] ?? ''} ${userData?['name'] ?? ''}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0),
                              overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                              '@${userData?['nickname'] ?? ''}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0),
                              overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () async {
                    await Future.delayed(const Duration(milliseconds: 300));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          Icons.settings_rounded,
                          size: 30.0,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Налаштування', 
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0),
                          overflow: TextOverflow.ellipsis,
                          ),
                          Text('Налаштування програми', 
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0),
                          overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, 
                        size: 30.0, 
                        color: Theme.of(context).colorScheme.primary
                      ),
                      ],
                    ),
                  ),
                ),
              ),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  //_buildToolButton(
                  //  context,
                  //  icon: Icons.vibration_rounded,
                  //  label: 'Перевірка вібрації',
                  //  onTap: () async {
                  //    await Future.delayed(const Duration(milliseconds: 300));
                  //    Navigator.push(
                  //      context,
                  //      MaterialPageRoute(
                  //          builder: (context) => const VibrationTestScreen()),
                  //    );
                  //  },
                  //),
                  _buildToolButton(
                    context,
                    icon: Icons.calculate_rounded,
                    label: 'Калькулятор',
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 300));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CalculatorScreen()),
                      );
                    },
                  ),
                  _buildToolButton(
                    context,
                    icon: Icons.translate_rounded,
                    label: 'Перекладач',
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 300));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TranslatorScreen()),
                      );
                    },
                  ),
                  _buildToolButton(
                    context,
                    icon: Icons.note_alt_rounded,
                    label: 'Нотатки',
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 300));
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotesScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  customBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () async {
                    await Future.delayed(const Duration(milliseconds: 300));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (context) => const WiFiPage(),
                      ),
                    );
                  },
                  child: Ink(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(
                          Icons.wifi_rounded,
                          size: 30.0,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WI-FI точки', 
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0),
                          overflow: TextOverflow.ellipsis,
                          ),
                          Text('Інформація про точки доступу', 
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0),
                          overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, 
                        size: 30.0, 
                        color: Theme.of(context).colorScheme.primary
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.onSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(width: 2, color: Theme.of(context).colorScheme.primary),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(5),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(
                  icon,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary
                ),
                ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}