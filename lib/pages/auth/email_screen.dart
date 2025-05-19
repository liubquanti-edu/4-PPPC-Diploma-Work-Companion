//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:flutter/material.dart';
import 'password_screen.dart';
import 'register_screen.dart';
import '/services/auth_service.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({Key? key}) : super(key: key);

  @override
  _EmailScreenState createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  Future<void> _handleEmailSubmit() async {
  if (_formKey.currentState!.validate()) {
    try {
      final email = _emailController.text;
      
      final student = await _authService.findStudentByEmail(email);
      
      if (student != null) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PasswordScreen(email: email),
            ),
          );
        }
        return;
      }

      final person = await _authService.findPersonByEmail(email);
      
      if (person == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Користувача з такою поштою не знайдено. Перевір, чи саме цю пошту ти надав коледжу при вступі.')),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(
              email: email,
              personData: person.data() as Map<String, dynamic>,
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: ${e.toString()}')),
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Text(
                '👋 Привіт!',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                'Пройди авторизацію, аби почати використовувати компаньйон.',
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
                ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Електронна пошта',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Будь ласка, введіть email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Введіть коректний email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleEmailSubmit,
                child: const Text('Далі'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onSecondary,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}