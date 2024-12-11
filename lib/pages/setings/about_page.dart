import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Про програму'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              color: Theme.of(context).colorScheme.onSecondary,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Text(
                    'Розробник',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text('Любченко Олег', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text(
                    'Зв\'язок',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () async {
                      final Uri url = Uri.parse('https://www.youtube.com/@liubquanti');
                      if (!await launchUrl(url)) {
                        throw Exception('Could not launch $url');
                      }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.telegram),
                      onPressed: () async {
                      final Uri url = Uri.parse('https://t.me/liubquanti');
                      if (!await launchUrl(url)) {
                        throw Exception('Could not launch $url');
                      }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: () async {
                      final Uri url = Uri.parse('https://instagram.com/liubquanti');
                      if (!await launchUrl(url)) {
                        throw Exception('Could not launch $url');
                      }
                      },
                    ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Версія',
                    style: Theme.of(context).textTheme.titleLarge,
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