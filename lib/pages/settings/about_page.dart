//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Про програму'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Container(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Text(
                    'Мій ППФК',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('Компаньйон студентів та викладачів коледжа, який має на цілі полегшити студентське життя навчального закладу та спростити модель взаємодії з ним.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text(
                    'Розробник',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('Створено силами білого серця для безсердечних.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                      children: [
                        GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://sites.google.com/polytechnic.co.cc/main')),
                        child: Container(
                        decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                        shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                        child: Image.asset('assets/img/pppclogo.png', width: 80),
                        ),
                        ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                        'ППФК',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                        ),
                      ],
                      ),
                      const SizedBox(width: 20),
                      Text(
                      '//',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 20),
                      Column(
                      children: [
                        GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://liubquanti.click/')),
                        child: Container(
                          decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                          shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                          child: Image.asset('assets/img/liubquantilogo.png', width: 80),
                          ),
                        ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                        'liubquanti',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                        ),
                      ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Версія',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('1.0.0', textAlign: TextAlign.center),
                  ],
                ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}