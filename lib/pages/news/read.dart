import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsItem;

  const NewsDetailScreen({
    Key? key,
    required this.newsItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новина'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (newsItem['thumbnail'] != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: newsItem['thumbnail'].startsWith('http')
                        ? NetworkImage(newsItem['thumbnail'])
                        : const AssetImage('assets/img/news.jpg') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 5),
            Text(
              newsItem['title'] ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Container(
              height: 3,
              decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(15),
              ),
            ),
            const SizedBox(height: 5),
            Html(
              data: newsItem['description'] ?? '',
              style: {
              "body": Style(
                fontSize: FontSize(14),
                fontFamily: 'Comfortaa',
                textAlign: TextAlign.justify,
              ),
              },
            ),
            Container(
              height: 3,
              decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(15),
              ),
            ),
            if (newsItem['link'] != null)
                Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton(
                  onPressed: () => launch(newsItem['link']),
                  child: const Text('Відкрити веб-версію'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSecondary,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  ),
                ),
                ),
          ],
        ),
      ),
    );
  }
}