import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:card_loading/card_loading.dart';
import 'package:weather/weather.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'dart:async';
import 'dart:convert';
import 'config/api.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/schedule.dart';
import '/models/week_type.dart';
import '/pages/news/read.dart';
import '/pages/info/subject.dart';
import '/providers/alert_provider.dart';
import '../models/transport.dart';

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
  late ScrollController _scrollController;
  bool _showAppBarLogo = false;
  List<Map<String, dynamic>> _emergencyMessages = [];
  List<TransportSchedule>? _schedules;
  bool _isScheduleLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _showAppBarLogo = _scrollController.offset > 100;
      });
    });
    _fetchNews().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
    _fetchWeather();
    _fetchEmergencyMessages();
    _loadSchedule();
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) {
      return;
    }

    super.setState(fn);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    final response = await http.get(Uri.parse('https://polytechnic-news.blogspot.com/rss.xml'));
    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item').take(10);
      setState(() {
        _news = items.map((item) {
          final title = item.findElements('title').single.text;
          // Store raw description without parsing
          final description = item.findElements('description').single.text;
          final link = item.findElements('link').single.text;
          final thumbnail = item.findElements('media:thumbnail').isEmpty 
              ? 'assets/img/news.jpg'
              : item.findElements('media:thumbnail').single.getAttribute('url') ?? 'assets/img/news.jpg';
          return {
            'title': title,
            'description': description,  // Raw HTML content
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

  Future<List<Lesson>> _fetchTimetable() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .get();
    final group = userDoc.data()?['group'];

    final weekday = DateFormat('EEEE').format(DateTime.now()).toLowerCase();
    
    final weekType = WeekType.getCurrentType();

    final snapshot = await FirebaseFirestore.instance
        .collection('timetable')
        .doc(group.toString())
        .collection(weekday)
        .orderBy(FieldPath.documentId)
        .get();

    return snapshot.docs.map((doc) {
      final lesson = Lesson.fromJson(doc.data());
      if (lesson.week == null || lesson.week == weekType) {
        return lesson;
      }
      return null;
    }).whereType<Lesson>().toList();
  }


Future<Map<String, String>> _fetchBellSchedule(int lessonNumber) async {
  final doc = await FirebaseFirestore.instance
      .collection('bell')
      .doc(lessonNumber.toString())
      .get();

  final startParts = (doc.data()?['start'] as String?)?.split(':') ?? [];
  final endParts = (doc.data()?['end'] as String?)?.split(':') ?? [];
  
  if (startParts.length != 2 || endParts.length != 2) {
    return {'start': '', 'end': ''};
  }

  final now = DateTime.now();
  
  final ukraineOffset = () {
    final month = now.month;
    final isDST = month >= 3 && month <= 10;
    return isDST ? 3 : 2;
  }();
  
  final startTime = DateTime.utc(
    now.year,
    now.month,
    now.day,
    int.parse(startParts[0]) - ukraineOffset,
    int.parse(startParts[1])
  );
  
  final endTime = DateTime.utc(
    now.year,
    now.month,
    now.day,
    int.parse(endParts[0]) - ukraineOffset,
    int.parse(endParts[1])
  );

  final localStartTime = startTime.toLocal();
  final localEndTime = endTime.toLocal();

  final formatter = DateFormat('HH:mm');
  return {
    'start': formatter.format(localStartTime),
    'end': formatter.format(localEndTime),
  };
}

  Future<void> _fetchEmergencyMessages() async {
    try {
      final now = Timestamp.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('emergency')
          .where('end', isGreaterThan: now)
          .get();
          
      setState(() {
        _emergencyMessages = snapshot.docs
            .map((doc) => {
              'name': doc.data()['name'] as String,
              'description': doc.data()['description'] as String,
              'end': doc.data()['end'] as Timestamp,
            })
            .toList();
      });
    } catch (e) {
      debugPrint('Error fetching emergency messages: $e');
    }
  }

  Future<List<TransportSchedule>> _fetchSchedule() async {
  try {
    final response = await http.get(
      Uri.parse('https://gps.easyway.info/api/city/poltava/lang/ua/stop/80'),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'ok') {
        final routes = (data['data']['routes'] as List)
          .map((route) => TransportSchedule.fromJson(route))
          .toList();
        
        // Сортуємо маршрути за часом прибуття
        routes.sort(TransportSchedule.compareByArrivalTime);
        
        return routes;
      }
    }
    throw Exception('Failed to load schedule');
  } catch (e) {
    debugPrint('Error fetching schedule: $e');
    rethrow;
  }
}

  Future<void> _loadSchedule() async {
  try {
    setState(() => _isScheduleLoading = true);
    final schedules = await _fetchSchedule();
    setState(() {
      _schedules = schedules;
      _isScheduleLoading = false;
    });
  } catch (e) {
    setState(() => _isScheduleLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Помилка завантаження розкладу: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

  PreferredSizeWidget _buildNormalAppBar() {
  return AppBar(
    
    title: AnimatedOpacity(
      opacity: _showAppBarLogo ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 100),
      child: Center(
        child: SvgPicture.asset(
          'assets/svg/ППФК.svg',
          color: Theme.of(context).colorScheme.primary,
          height: 30,
        ),
      ),
    ),
  );
}

  PreferredSizeWidget _buildEmergencyAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.onError,
      title: Column(
        children: [
          Container(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _emergencyMessages.length,
              itemBuilder: (context, index) {
                final message = _emergencyMessages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(message['name']),
                          content: Text(message['description']),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          message['name'],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _emergencyMessages.isNotEmpty 
      ? _buildEmergencyAppBar()
      : _buildNormalAppBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20.0, width: double.infinity),
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
                  const SizedBox(height: 10.0, width: double.infinity),
                  FutureBuilder<List<Lesson>>(
                    future: _fetchTimetable(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSecondary,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.0,
                            ),
                          ),
                          child: snapshot.data!.isEmpty 
                            ? Row(
                                children: [
                                  SizedBox(
                                    height: 50,
                                    width: 5,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'На сьогодні занять немає',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0),
                                        ),
                                        Row(
                                          children: [
                                          Icon(
                                            Icons.weekend_outlined,
                                            size: 16.0,
                                            color: Theme.of(context).colorScheme.secondary,
                                          ),
                                          const SizedBox(width: 5.0),
                                          Expanded(
                                            child: Text(
                                            'Відпочивай та набирайся сил!',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0),
                                            ),),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                          : Column(
                            children: snapshot.data!.asMap().entries.map((entry) {
                              final index = entry.key;
                              final lesson = entry.value;
                              
                              return FutureBuilder<Map<String, String>>(
                                future: _fetchBellSchedule(index + 1),
                                builder: (context, bellSnapshot) {
                                  if (bellSnapshot.hasData) {
                                    return Column(
                                      children: [
                                      if (index > 0) const SizedBox(height: 10.0),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => LessonDetailsScreen(
                                                lesson: lesson,
                                                startTime: bellSnapshot.data!['start'] ?? '',
                                                endTime: bellSnapshot.data!['end'] ?? '',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(
                                                  height: 60, 
                                                  width: 5,
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.secondary,
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10.0),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        lesson.name,
                                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0),
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.info_outline,
                                                            size: 16.0,
                                                            color: Theme.of(context).colorScheme.secondary,
                                                          ),
                                                          const SizedBox(width: 5.0),
                                                          Expanded(
                                                            child: Text(
                                                              '${lesson.prof} ${lesson.place}',
                                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.access_time_outlined,
                                                            size: 16.0,
                                                            color: Theme.of(context).colorScheme.secondary,
                                                          ),
                                                          const SizedBox(width: 5.0),
                                                          Expanded(
                                                            child: Text(
                                                              '${bellSnapshot.data!['start']} - ${bellSnapshot.data!['end']}',
                                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      ],
                                    );
                                  }
                                  return Padding(
                                    padding: index < snapshot.data!.length - 1 ? const EdgeInsets.only(bottom: 10.0) : EdgeInsets.zero,
                                    child: Row(
                                      children: [
                                        CardLoading(
                                          height: 60,
                                          width: 5,
                                          borderRadius: BorderRadius.circular(5),
                                          margin: const EdgeInsets.all(0),
                                          animationDuration: const Duration(milliseconds: 1000),
                                          cardLoadingTheme: CardLoadingTheme(
                                            colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          ),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CardLoading(
                                                height: 20,
                                                borderRadius: BorderRadius.circular(5),
                                                margin: const EdgeInsets.only(bottom: 5),
                                                animationDuration: const Duration(milliseconds: 1000),
                                                cardLoadingTheme: CardLoadingTheme(
                                                  colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                ),
                                              ),
                                              CardLoading(
                                                height: 15,
                                                width: 200,
                                                borderRadius: BorderRadius.circular(5),
                                                margin: const EdgeInsets.only(bottom: 5),
                                                animationDuration: const Duration(milliseconds: 1000),
                                                cardLoadingTheme: CardLoadingTheme(
                                                  colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                ),
                                              ),
                                              CardLoading(
                                                height: 15,
                                                width: 150,
                                                borderRadius: BorderRadius.circular(5),
                                                margin: const EdgeInsets.all(0),
                                                animationDuration: const Duration(milliseconds: 1000),
                                                cardLoadingTheme: CardLoadingTheme(
                                                  colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        );
                      }
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          children: List.generate(3, (index) => Padding(
                            padding: index < 2 ? const EdgeInsets.only(bottom: 10.0) : EdgeInsets.zero,
                            child: Row(
                              children: [
                                CardLoading(
                                  height: 60,
                                  width: 5,
                                  borderRadius: BorderRadius.circular(5),
                                  margin: const EdgeInsets.all(0),
                                  animationDuration: const Duration(milliseconds: 1000),
                                  cardLoadingTheme: CardLoadingTheme(
                                    colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  ),
                                ),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CardLoading(
                                        height: 20,
                                        borderRadius: BorderRadius.circular(5),
                                        margin: const EdgeInsets.only(bottom: 5),
                                        animationDuration: const Duration(milliseconds: 1000),
                                        cardLoadingTheme: CardLoadingTheme(
                                          colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        ),
                                      ),
                                      CardLoading(
                                        height: 15,
                                        width: 200,
                                        borderRadius: BorderRadius.circular(5),
                                        margin: const EdgeInsets.only(bottom: 5),
                                        animationDuration: const Duration(milliseconds: 1000),
                                        cardLoadingTheme: CardLoadingTheme(
                                          colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        ),
                                      ),
                                      CardLoading(
                                        height: 15,
                                        width: 150,
                                        borderRadius: BorderRadius.circular(5),
                                        margin: const EdgeInsets.all(0),
                                        animationDuration: const Duration(milliseconds: 1000),
                                        cardLoadingTheme: CardLoadingTheme(
                                          colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ),
                      );
                    },
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
                    GestureDetector(
                    child: Ink(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSecondary,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10.0),
                    onTap: () => _launchUrl('https://openweathermap.org/city/696643'),
                    child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: Stack(
                        children: [
                        Column(
                          children: [
                            if (_isWeatherLoading)
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  CardLoading(
                                    height: 25,
                                    width: 250,
                                    borderRadius: const BorderRadius.all(Radius.circular(10)),
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
                                    borderRadius: const BorderRadius.all(Radius.circular(10)),
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
                                                Icon(
                                                Icons.thermostat_rounded, 
                                                color: (_weather!.tempFeelsLike?.celsius ?? 0) < -15 || (_weather!.tempFeelsLike?.celsius ?? 0) > 30
                                                  ? Colors.red.shade400 
                                                  : Theme.of(context).colorScheme.secondary
                                                ),
                                              const SizedBox(width: 2),
                                              Text(
                                                  '${_weather!.tempFeelsLike?.celsius?.round()}°C',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 10.0),
                                          Row(
                                            children: [
                                              Icon(Icons.water_drop_rounded, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${_weather!.humidity?.round() ?? 0}%',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 10.0),
                                          Row(
                                            children: [
                                              Transform.rotate(
                                                angle: (_weather!.windDegree ?? 0) * (3.1415927 / 360),
                                                child: Icon(Icons.navigation_rounded, color: (_weather!.windSpeed ?? 0) > 13 ? Colors.red.shade400 : Theme.of(context).colorScheme.secondary),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${_weather!.windSpeed?.round() ?? 0} м/с',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 10.0),
                                          Row(
                                            children: [
                                              Icon(Icons.arrow_downward_rounded, color: Theme.of(context).colorScheme.secondary),
                                              const SizedBox(width: 2),
                                              Text(
                                                  '${_weather!.pressure?.round() ?? 0} Pa',
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
                      if (_weather?.weatherMain?.toLowerCase() == 'rain')
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: ParallaxRain(
                              dropColors: [Theme.of(context).colorScheme.primary],
                              trail: true,
                              dropFallSpeed: 2,
                              numberOfDrops: 10,
                              dropHeight: 15,
                            ),
                          ),
                        )
                      else if (_weather?.weatherMain?.toLowerCase() == 'snow')
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.0),
                            child: ParallaxRain(
                              dropColors: [Theme.of(context).colorScheme.primary],
                              trail: true,
                              dropFallSpeed: 0.5,
                              numberOfDrops: 10,
                              dropHeight: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),),),),),
                  const SizedBox(height: 20.0, width: double.infinity),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Статус тривоги 🚨',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0), 
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 10.0, width: double.infinity),
                  Consumer<AlertProvider>(
                    builder: (context, alertProvider, child) {
                      return GestureDetector(
                        child: Ink(
                          height: 80,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSecondary,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10.0),
                            onTap: () => _launchUrl('https://alerts.in.ua'),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: alertProvider.isLoading
                                ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CardLoading(
                                    height: 25,
                                    width: 250,
                                    borderRadius: const BorderRadius.all(Radius.circular(10)),
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
                                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                                    animationDuration: const Duration(milliseconds: 1000),
                                    animationDurationTwo: const Duration(milliseconds: 700),
                                    cardLoadingTheme: CardLoadingTheme(
                                      colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ),
                                    ),
                                  ],
                                  )
                                : Row(
                                    children: [
                                      SizedBox(
                                        height: 50,
                                        width: 50,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainer,
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: Icon(
                                            alertProvider.alertInfo.status == 'A' 
                                              ? Icons.warning_rounded
                                              : Icons.check_box_rounded,
                                            size: 30.0,
                                            color: alertProvider.alertInfo.status == 'A' 
                                              ? Colors.red.shade400
                                              : Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                              alertProvider.alertInfo.status == 'A'
                                              ? 'Повітряна тривога!'
                                              : 'Тривоги немає',
                                              style: Theme.of(context).textTheme.titleLarge,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              ),
                                            ),
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.6,
                                              child: Text(
                                                alertProvider.alertInfo.status == 'A'
                                                ? 'Початок: ${DateFormat('HH:mm').format(alertProvider.alertInfo.startTime!.toLocal())}'
                                                ' • ${(() {
                                                  final diff = DateTime.now().difference(alertProvider.alertInfo.startTime!);
                                                  if (diff.inDays > 0) {
                                                  return '${diff.inDays}:${diff.inHours.remainder(24).toString().padLeft(2, '0')}:${diff.inMinutes.remainder(60).toString().padLeft(2, '0')}';
                                                  } else if (diff.inHours > 0) {
                                                  return '${diff.inHours}:${diff.inMinutes.remainder(60).toString().padLeft(2, '0')}';
                                                  } else {
                                                  return '0:${diff.inMinutes.toString().padLeft(2, '0')}';
                                                  }
                                                })()}'
                                                : 'Оповіщень не надходило.',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20.0, width: double.infinity),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Транспорт 🚍',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0), 
                      textAlign: TextAlign.left,
                    ),
                  ),
                    Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.0,
                      ),
                    ),
                    child: _isScheduleLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _schedules == null
                        ? const Center(child: Text('Немає даних про розклад'))
                        : Column(
                          children: _schedules!.map((schedule) {
                            return Container(
                            child: ListTile(
                              leading: schedule.transportName == 'Тролейбус'
                                ? SvgPicture.asset('assets/svg/transport/trolleybus.svg', width: 20, color: const Color(0xFFA2C9FE))
                                : schedule.transportName == 'Автобус'
                                  ? SvgPicture.asset('assets/svg/transport/bus.svg', width: 20, color: const Color(0xff9ed58b))
                                  : schedule.transportName == 'Маршрутка'
                                  ? SvgPicture.asset('assets/svg/transport/route.svg', width: 20, color: const Color(0xfffeb49f))
                                  : SvgPicture.asset('assets/svg/transport/bus.svg', width: 20, color: const Color(0xFFFE9F9F)),
                              title: Text(
                              '№${schedule.routeName} • ${schedule.directionName}',
                              ),
                              subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Інтервал: ${schedule.interval} хв'),
                                if (schedule.times.isNotEmpty) ...[
                                Text(
                                  'Наступний: ${schedule.times.first.arrivalTimeFormatted}${schedule.times.first.bortNumber != null 
                                  ? ' (${schedule.times.first.bortNumber})'
                                  : ''}',
                                ),
                                ],
                              ],
                              ),
                            ),
                            );
                          }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20.0, width: double.infinity),
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
                              color: Theme.of(context).colorScheme.onSecondary,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  CardLoading(
                                    height: 85,
                                    width: 85,
                                    borderRadius: BorderRadius.circular(5),
                                    margin: const EdgeInsets.all(0),
                                    animationDuration: const Duration(milliseconds: 1000),
                                    cardLoadingTheme: CardLoadingTheme(
                                      colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CardLoading(
                                          height: 20,
                                          borderRadius: BorderRadius.circular(5),
                                          margin: const EdgeInsets.only(bottom: 10),
                                          animationDuration: const Duration(milliseconds: 1000),
                                          cardLoadingTheme: CardLoadingTheme(
                                            colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          ),
                                        ),
                                        CardLoading(
                                          height: 40,
                                          borderRadius: BorderRadius.circular(5),
                                          margin: const EdgeInsets.all(0),
                                          animationDuration: const Duration(milliseconds: 1000),
                                          cardLoadingTheme: CardLoadingTheme(
                                            colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ))
                        : List.generate(_news.length, (index) {
                            final newsItem = _news[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: InkWell(
                                customBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NewsDetailScreen(newsItem: newsItem),
                                  ),
                                ),
                                child: Ink(
                                  padding: const EdgeInsets.all(10.0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSecondary,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                                  ),
                                    child: Row(
                                    children: [
                                      Container(
                                      width: 85,
                                      height: 85,
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
                                      Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                        Text(
                                          newsItem['title'] ?? '',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 14.0),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        Text(
                                          _parseHtmlString(newsItem['description'] ?? ''),
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10.0),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 4,
                                        ),
                                        ],
                                      ),
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
                      backgroundColor: Theme.of(context).colorScheme.onSecondary,
                      foregroundColor: Theme.of(context).colorScheme.primary,
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

class AlertInfo {
  final String status;
  final DateTime? startTime;

  AlertInfo({required this.status, this.startTime});
}
