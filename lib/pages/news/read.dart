import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as htmlparser;
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:card_loading/card_loading.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> newsItem;

  const NewsDetailScreen({
    Key? key,
    required this.newsItem,
  }) : super(key: key);

  List<String> _extractImages(String htmlContent) {
    final document = htmlparser.parse(htmlContent);
    final images = document.getElementsByTagName('img');
    return images.map((img) {
      String src = img.attributes['src'] ?? '';
      if (src.contains('s1600')) {
        return src;
      }
      return src.replaceAll(RegExp(r'w\d+-h\d+'), 's1600');
    }).toList();
  }

  String _removeImages(String htmlContent) {
    final document = htmlparser.parse(htmlContent);
    document.getElementsByTagName('img').forEach((element) => element.remove());
    return document.body?.innerHtml ?? '';
  }

  @override 
  Widget build(BuildContext context) {
    final images = _extractImages(newsItem['description'] ?? '');
    final cleanContent = _removeImages(newsItem['description'] ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новина'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newsItem['title'] ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Comfortaa',
              ),
            ),
            const SizedBox(height: 5),
            Divider(
              color: Theme.of(context).colorScheme.primary,
              thickness: 2,
            ),
            Html(
              data: cleanContent,
              style: {
                "*": Style(
                  textAlign: TextAlign.left
                ),
                "body": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontFamily: 'Comfortaa',
                  fontSize: FontSize(14),
                ),
                "p": Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  fontFamily: 'Comfortaa',
                ),
                "span": Style(
                  fontFamily: 'Comfortaa',
                ),
              },
            ),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
                ...images.map((imageUrl) => Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoView(
                      imageProvider: NetworkImage(imageUrl),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                      ),
                    ),
                    );
                  },
                  child: Hero(
                    tag: imageUrl,
                    child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    placeholder: (context, url) => Center(
                      child: CardLoading(
                      height: 200,
                      width: double.infinity,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      cardLoadingTheme: CardLoadingTheme(
                          colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    fit: BoxFit.contain,
                    ),
                  ),
                  ),
                ),
                )),),),
            ],
            const Divider(height: 32),
            if (newsItem['link'] != null)
              Center(
                child: ElevatedButton(
                  onPressed: () => launch(newsItem['link']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text(
                    'Відкрити веб-версію',
                    style: TextStyle(fontFamily: 'Comfortaa'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}