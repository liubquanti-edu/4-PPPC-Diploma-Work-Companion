import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:url_launcher/url_launcher.dart';
import 'package:card_loading/card_loading.dart';
import 'package:weather/weather.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'config/api.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> _news = [];
  bool _isLoading = true;
  Weather? _weather;
  bool _isWeatherLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNews().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
    _fetchWeather();
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) {
      return;
    }

    super.setState(fn);
  }

  Future<void> _fetchNews() async {
    final response = await http.get(Uri.parse('https://polytechnic-news.blogspot.com/rss.xml'));
    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item').take(10);
      setState(() {
        _news = items.map((item) {
          final title = item.findElements('title').single.text;
          final description = _parseHtmlString(item.findElements('description').single.text);
          final link = item.findElements('link').single.text;
          final thumbnail = item.findElements('media:thumbnail').isEmpty 
              ? 'assets/img/news.jpg' // Fallback image
              : item.findElements('media:thumbnail').single.getAttribute('url') ?? 'assets/img/news.jpg';
          return {
            'title': title,
            'description': description,
            'link': link,
            'thumbnail': thumbnail
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<void> _fetchWeather() async {
    try {
      setState(() {
        _isWeatherLoading = true;
      });
      
      WeatherFactory wf = WeatherFactory(ApiConfig.weatherApiKey, language: Language.UKRAINIAN);
      Weather weather = await wf.currentWeatherByCityName("Poltava,UA");
      
      setState(() {
        _weather = weather;
        _isWeatherLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      setState(() {
        _isWeatherLoading = false;
        _weather = null;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Помилка API ключа OpenWeatherMap. Будь ласка, перевірте ключ.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  String _parseHtmlString(String htmlString) {
    final document = xml.XmlDocument.parse('<body>$htmlString</body>');
    return document.rootElement.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
        body: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: SvgPicture.asset(
                  'assets/svg/ППФК.svg',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24.0),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 10.0, width: double.infinity),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Твій календар 📆',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(top: 10.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceBright,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(height: 70, width: 5, child: DecoratedBox(decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(5)))),
                                      const SizedBox(width: 10.0),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Архітект.комп.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0)),
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 16.0, color: Theme.of(context).colorScheme.primary),
                                              const SizedBox(width: 5.0),
                                              Text('Ігор Дегтяр 304 ауд.', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                                              const SizedBox(width: 5.0),
                                              Text('09:00 - 10:00', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                              const SizedBox(width: 5.0),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0, width: double.infinity),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(height: 60, width: 5, child: DecoratedBox(decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(5)))),
                                      const SizedBox(width: 10.0),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Проєктування АІС', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 16.0, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 5.0),
                                              Text('Світлана Гриценко 317 ауд.', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 5.0),
                                              Text('10:10 - 11:10', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                              const SizedBox(width: 5.0),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0, width: double.infinity),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(height: 60, width: 5, child: DecoratedBox(decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(5)))),
                                      const SizedBox(width: 10.0),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Осн.патентознав.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                                          Row(
                                            children: [
                                              Icon(Icons.info_outline, size: 16.0, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 5.0),
                                              Text('Марина Яненко 313 ауд.', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 5.0),
                                              Text('11:50 - 12:50', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                                              const SizedBox(width: 5.0),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0, width: double.infinity),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Погода в Полтаві 🌤️',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0), 
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 10.0, width: double.infinity),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceBright,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primary, width: 2.0),
                      ),
                      child: Stack(
                        children: [
                          if (_weather?.weatherMain?.toLowerCase() == 'rain')
                            Positioned.fill(
                              child: ParallaxRain(
                                dropColors: [Theme.of(context).colorScheme.primary],
                                trail: true,
                                dropFallSpeed: 2,
                                numberOfDrops: 10,
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_isWeatherLoading)
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    CardLoading(
                                      height: 25,
                                      width: 250,
                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                      animationDuration: const Duration(milliseconds: 1000),
                                      animationDurationTwo: const Duration(milliseconds: 700),
                                      cardLoadingTheme: CardLoadingTheme(
                                        colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      ),
                                    ),
                                    const SizedBox(height: 10.0),
                                    CardLoading(
                                      height: 20,
                                      width: 300,
                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                      animationDuration: const Duration(milliseconds: 1000),
                                      animationDurationTwo: const Duration(milliseconds: 700),
                                      cardLoadingTheme: CardLoadingTheme(
                                        colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                )
                              else if (_weather != null) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${_weather!.temperature?.celsius?.round()}°C • ',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                        Text(
                                          _weather!.weatherDescription?.replaceFirst(
                                            _weather!.weatherDescription![0],
                                            _weather!.weatherDescription![0].toUpperCase()) ?? '',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.arrow_upward_rounded, color: Theme.of(context).colorScheme.secondary),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${_weather!.tempMax?.celsius?.round()}°C',
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            Row(
                                              children: [
                                                Icon(Icons.arrow_downward_rounded, color: Theme.of(context).colorScheme.secondary),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${_weather!.tempMin?.celsius?.round()}°C',
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            Row(
                                              children: [
                                                Icon(Icons.water_drop_rounded, color: Theme.of(context).colorScheme.secondary),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${_weather!.humidity ?? 0}%',
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            Row(
                                              children: [
                                                Transform.rotate(
                                                  angle: (_weather!.windDegree ?? 0) * (3.1415927 / 180),
                                                  child: Icon(Icons.navigation_rounded, color: Theme.of(context).colorScheme.secondary),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${_weather!.windSpeed?.round() ?? 0} м/с',
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ] else
                                const Text('Не вдалося завантажити погоду'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0, width: double.infinity),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Останні новини 📰',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0), 
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Column(
                      children: _isLoading 
                        ? List.generate(3, (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceBright,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                              ),
                              child: CardLoading(
                              height: 104,
                              borderRadius: BorderRadius.circular(10),
                              margin: const EdgeInsets.all(0),
                              animationDuration: const Duration(milliseconds: 1000),
                              animationDurationTwo: const Duration(milliseconds: 700),
                              cardLoadingTheme: CardLoadingTheme(
                                colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              ),
                            ),
                            ),
                          ))
                        : List.generate(_news.length, (index) {
                            final newsItem = _news[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: InkWell(
                                onTap: () => _launchUrl(newsItem['link'] ?? ''),
                                child: Container(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceBright,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                          image: DecorationImage(
                                            image: newsItem['thumbnail']?.startsWith('http') ?? false
                                                ? NetworkImage(newsItem['thumbnail']!)
                                                : const AssetImage('assets/img/news.jpg') as ImageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context).size.width * 0.6,
                                            child: Text(
                                              newsItem['title'] ?? '',
                                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 14.0),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context).size.width * 0.6,
                                            child: Text(
                                              newsItem['description'] ?? '',
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10.0),
                                              softWrap: true,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _launchUrl('https://polytechnic-news.blogspot.com'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Більше новин'),
                  ),
                  const SizedBox(height: 10.0, width: double.infinity),
                ],
              ),
            ),
          ],
        ), 
      ),
    );
  }
}
