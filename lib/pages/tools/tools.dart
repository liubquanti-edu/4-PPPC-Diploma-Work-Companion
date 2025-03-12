import 'package:flutter/material.dart';
import 'vibration.dart';
import 'calculator.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Інструменти'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
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
              MaterialPageRoute(builder: (context) => const VibrationTestScreen()),
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
              MaterialPageRoute(builder: (context) => const CalculatorScreen()),
              );
            },
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}