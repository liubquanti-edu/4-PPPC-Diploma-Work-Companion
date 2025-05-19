//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_simple_calculator/flutter_simple_calculator.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор'),
        centerTitle: true,
      ),
      body: SizedBox(
        width: double.infinity,
        child: SimpleCalculator(
            theme: CalculatorThemeData(
              borderWidth: 0,
            displayColor: Colors.transparent,
            displayStyle: const TextStyle(
              fontSize: 40,
              fontFamily: 'Comfortaa',
            ),
            operatorStyle: const TextStyle(
              fontSize: 40,
              fontFamily: 'Comfortaa',
            ),
            commandStyle: const TextStyle(
              fontSize: 30,
              fontFamily: 'Comfortaa',
            ),
            numStyle: const TextStyle(
              fontSize: 30,
              fontFamily: 'Comfortaa',
            ),
            operatorColor: Theme.of(context).colorScheme.onPrimary,
            commandColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ),
    );
  }
}