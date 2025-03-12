import 'package:flutter/material.dart';
import 'package:flutter_simple_calculator/flutter_simple_calculator.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор'),
      ),
      body: SizedBox(
        width: double.infinity,
        child: SimpleCalculator(
          theme: CalculatorThemeData(
            displayColor: Colors.transparent,
            displayStyle: const TextStyle(fontSize: 40),
            operatorColor: Theme.of(context).colorScheme.onPrimary,
            commandColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ),
    );
  }
}