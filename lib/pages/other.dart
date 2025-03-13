import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './tools/vibration.dart';
import './tools/calculator.dart';
import './tools/translator.dart';
import './other/profile.dart';
import '/models/avatars.dart';

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
      body: Column(
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

              return Material(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CachedAvatar(
                          imageUrl: userData?['avatar'],
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${userData?['surname'] ?? ''} ${userData?['name'] ?? ''}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '@${userData?['nickname'] ?? ''}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildToolButton(
                  context,
                  icon: Icons.vibration_rounded,
                  label: 'Перевірка вібрації',
                  onTap: () async {
                    await Future.delayed(const Duration(milliseconds: 300));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VibrationTestScreen()),
                    );
                  },
                ),
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
              ],
            ),
          ),
        ],
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
              Icon(
                icon,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}