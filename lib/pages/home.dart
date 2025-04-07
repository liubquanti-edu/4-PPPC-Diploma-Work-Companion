import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:card_loading/card_loading.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/schedule.dart';
import '/models/week_type.dart';
import '/pages/news/read.dart';
import '/pages/info/subject.dart';
import '/providers/alert_provider.dart';
import '/pages/transport/transport_schedule.dart';
import '/providers/transport_provider.dart';
import '/providers/theme_provider.dart';
import '/models/weather.dart';
import '/pages/weather/weather_details.dart';
import '/pages/alert/alert.dart';

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
  Map<String, dynamic> _cachedSubjects = {};
  Map<String, dynamic> _cachedTeachers = {};
  DateTime? _lastCacheUpdate;

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
          final description = item.findElements('description').single.text;
          final link = item.findElements('link').single.text;
          final thumbnail = item.findElements('media:thumbnail').isEmpty 
              ? 'assets/img/news.jpg'
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

    final weatherDoc = await FirebaseFirestore.instance
        .collection('info')
        .doc('weather')
        .get();

    if (weatherDoc.exists) {
      final data = weatherDoc.data();
      if (data != null) {
        setState(() {
          _weather = Weather.fromFirestore(data);
          _isWeatherLoading = false;
        });
      }
    } else {
      throw Exception('Weather document does not exist in Firestore');
    }
  } catch (e) {
    debugPrint('Error fetching weather from Firestore: $e');
    setState(() {
      _isWeatherLoading = false;
      _weather = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Не вдалося отримати дані про погоду з Firestore.'),
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
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user.uid)
        .get();
    final group = userDoc.data()?['group'];
    if (group == null) return [];

    final now = Timestamp.now();
    final coursesSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('groups', arrayContains: group)
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThan: now)
        .limit(1)
        .get();

    if (coursesSnapshot.docs.isEmpty) return [];

    final courseDoc = coursesSnapshot.docs.first;
    
    final scheduleDoc = await courseDoc.reference
        .collection('schedule')
        .doc(group.toString())
        .get();

    if (!scheduleDoc.exists) return [];

    final weekType = WeekType.getCurrentType();
    final weekday = DateFormat('EEEE').format(DateTime.now()).toLowerCase();

    final weekData = scheduleDoc.data()?[weekType] as Map<String, dynamic>?;
    if (weekData == null) return [];

    final daySchedule = weekData[weekday] as Map<String, dynamic>?;
    if (daySchedule == null) return [];

    if (_lastCacheUpdate == null || 
        DateTime.now().difference(_lastCacheUpdate!) > const Duration(hours: 24)) {
      _cachedSubjects.clear();
      _cachedTeachers.clear();
      _lastCacheUpdate = DateTime.now();
    }

    final lessons = <Lesson>[];
    
    final sortedLessonNumbers = daySchedule.keys.toList()..sort();
    
    for (var lessonNumber in sortedLessonNumbers) {
      final lessonData = daySchedule[lessonNumber] as Map<String, dynamic>;
      final subjectId = lessonData['subjectId'];
      final teacherId = lessonData['teacherId'];
      final commissionId = lessonData['commissionId'];

      String? subjectName;
      if (_cachedSubjects.containsKey(subjectId)) {
        subjectName = _cachedSubjects[subjectId]['name'];
      } else {
        final commissionDoc = await FirebaseFirestore.instance
            .collection('cyclecommission')
            .doc(commissionId)
            .get();

        final subjectDoc = await commissionDoc.reference
            .collection('subjects')
            .doc(subjectId)
            .get();
            
        if (subjectDoc.exists) {
          _cachedSubjects[subjectId] = subjectDoc.data() ?? {};
          subjectName = subjectDoc.data()?['name'];
        }
      }

      if (subjectName == null) continue;

      String? teacherName;
      if (_cachedTeachers.containsKey(teacherId)) {
        teacherName = _cachedTeachers[teacherId]['name'];
      } else {
        final teacherDoc = await FirebaseFirestore.instance
            .collection('teachers')
            .doc(teacherId)
            .get();
            
        if (teacherDoc.exists) {
          _cachedTeachers[teacherId] = teacherDoc.data() ?? {};
          teacherName = teacherDoc.data()?['name'];
        }
      }

      lessons.add(Lesson(
        name: subjectName,
        place: lessonData['room'] ?? '',
        prof: teacherName ?? '',
      ));
    }

    return lessons;
  } catch (e) {
    print('Error fetching timetable: $e');
    return [];
  }
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
  ).toLocal();
  
  final endTime = DateTime.utc(
    now.year,
    now.month,
    now.day,
    int.parse(endParts[0]) - ukraineOffset,
    int.parse(endParts[1])
  ).toLocal();

  final formatter = DateFormat('HH:mm');
  return {
    'start': formatter.format(startTime),
    'end': formatter.format(endTime),
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

  Widget _getWeatherIcon(String? weatherMain) {
    IconData iconData;
    Color iconColor;

    switch (weatherMain?.toLowerCase()) {
      case 'clear':
        iconData = Icons.wb_sunny_rounded;
        iconColor = const Color(0xFFFEF89F);
        break;
      case 'rain':
        iconData = Icons.water_drop;
        iconColor = const Color(0xFF9FE3FE);
        break;
      case 'snow':
        iconData = Icons.ac_unit;
        iconColor = const Color(0xFFFFFFFF);
        break;
      case 'clouds':
        iconData = Icons.cloud_rounded;
        iconColor = const Color(0xFFB4B4B4);
        break;
      case 'thunderstorm':
        iconData = Icons.flash_on_rounded;
        iconColor = const Color(0xFFC39FFE);
        break;
      case 'drizzle':
        iconData = Icons.grain_rounded;
        iconColor = const Color(0xFF9FE3FE);
        break;
      case 'mist':
      case 'fog':
      case 'haze':
        iconData = Icons.blur_on_rounded;
        iconColor = const Color(0xFFB4B4B4);
        break;
      default:
        iconData = Icons.cloud_rounded;
        iconColor = const Color(0xFFB4B4B4);
        break;
    }

    return Icon(
      iconData,
      size: 30.0,
      color: iconColor,
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
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSecondary,
                        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10.0),
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (!mounted) return;
                          
                          if (_weather != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => WeatherDetailsScreen(weather: _weather!),
                            ),
                          );
                          } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                            content: const Text('Дані про погоду недоступні.'),
                            backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                          }
                        },
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
                                            height: 18,
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
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 50,
                                            width: 50,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.surfaceContainer,
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              child: Center(
                                                child: _getWeatherIcon(_weather!.weatherMain),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${_weather!.temperature?.celsius?.round()}°C • ${_weather!.weatherDescription?.replaceFirst(
                                                    _weather!.weatherDescription![0],
                                                    _weather!.weatherDescription![0].toUpperCase(),
                                                  ) ?? ''}',
                                                  style: Theme.of(context).textTheme.titleLarge,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                Row(
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.thermostat_rounded,
                                                          color: (_weather!.tempFeelsLike?.celsius ?? 0) < -15 ||
                                                                  (_weather!.tempFeelsLike?.celsius ?? 0) > 30
                                                              ? Colors.red.shade400
                                                              : Theme.of(context).colorScheme.secondary,
                                                          size: 16,
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
                                                        Icon(
                                                          Icons.water_drop_rounded,
                                                          color: Theme.of(context).colorScheme.secondary,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          '${_weather!.humidity?.round() ?? 0}%',
                                                          style: Theme.of(context).textTheme.bodyMedium,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
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
                          ),
                        ),
                      ),
                    ),
                  ),
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
                      return Ink(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSecondary,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10.0),
                            onTap: () async {
                              await Future.delayed(const Duration(milliseconds: 300));
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegionAlertMapScreen(region: 'Poltava'),
                                ),
                              );
                            },
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
                                    height: 18,
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
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return Consumer<TransportProvider>(
                        builder: (context, transportProvider, _) {
                          return Column(
                            children: themeProvider.stopIds.isEmpty
                                ? [const SizedBox(height: 10.0, width: double.infinity),
                                  Center(
                                  child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSecondary,
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
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
                                              Icons.signpost_rounded ,
                                              size: 30.0,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10.0),
                                        const Expanded(
                                          child: Text(
                                          'Вибрати зупинки можна в налаштуваннях.',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          ),
                                        )
                                      ]
                                    )
                                  ))
                                  )]
                                : themeProvider.stopIds.map((stopId) {
                                    final schedules = transportProvider.schedulesByStop[stopId];
                                    final isLoading = transportProvider.loadingStates[stopId] ?? false;
                                    final stopName = transportProvider.stopNames[stopId];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 10),
                                        child: isLoading
                                            ? Container(
                                              decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.onSecondary,
                                              borderRadius: BorderRadius.circular(10.0),
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.primary,
                                                width: 2.0,
                                              ),
                                              ),
                                                child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                                child: Column(
                                                  children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only( left: 10, right: 10, bottom: 5),
                                                    child: CardLoading(
                                                    height: 20,
                                                    width: double.infinity,
                                                    borderRadius: BorderRadius.circular(5),
                                                    margin: const EdgeInsets.all(0),
                                                    animationDuration: const Duration(milliseconds: 1000),
                                                      cardLoadingTheme: CardLoadingTheme(
                                                        colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                        colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                      ),
                                                    ),
                                                  ),
                                                  Column(
                                                  children: List.generate(
                                                  min(schedules?.length ?? 5, 5), 
                                                  (index) => ListTile(
                                                  contentPadding: const EdgeInsets.only( top: 5, left: 10.0, right: 10.0),
                                                  leading: CardLoading(
                                                  height: 50,
                                                  width: 50,
                                                  borderRadius: BorderRadius.circular(5),
                                                  margin: const EdgeInsets.all(0),
                                                  animationDuration: const Duration(milliseconds: 1000),
                                                  cardLoadingTheme: CardLoadingTheme(
                                                  colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  ),
                                                  ),
                                                  title: CardLoading(
                                                  height: 20,
                                                  borderRadius: BorderRadius.circular(5),
                                                  margin: const EdgeInsets.only(bottom: 5),
                                                  animationDuration: const Duration(milliseconds: 1000),
                                                  cardLoadingTheme: CardLoadingTheme(
                                                  colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  ),
                                                  ),
                                                  subtitle: CardLoading(
                                                  height: 15,
                                                  borderRadius: BorderRadius.circular(5),
                                                  margin: const EdgeInsets.all(0),
                                                  animationDuration: const Duration(milliseconds: 1000),
                                                  cardLoadingTheme: CardLoadingTheme(
                                                  colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  ),
                                                  ),
                                              )),),],
                                              ),),
                                            )
                                          : schedules == null
                                            ? Center(
                                              child: Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.onSecondary,
                                                borderRadius: BorderRadius.circular(10.0),
                                                border: Border.all(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  width: 2.0,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Row(
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
                                                          Icons.no_transfer_rounded,
                                                          size: 30.0,
                                                          color: Theme.of(context).colorScheme.primary,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10.0),
                                                    const Expanded(
                                                      child: Text(
                                                      'Немає даних про розклад.',
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                      ),
                                                    )
                                                  ]
                                                )
                                              ))
                                              )
                                            : GestureDetector(
                                              child: Ink(
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.onSecondary,
                                                borderRadius: BorderRadius.circular(10.0),
                                                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                                                ),
                                                child: InkWell(
                                                borderRadius: BorderRadius.circular(10.0),
                                                  onTap: () async {
                                                  await Future.delayed(const Duration(milliseconds: 300));
                                                  if (!mounted) return;
                                                  Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => TransportScheduleScreen(
                                                    schedules: schedules,
                                                    ),
                                                  ),
                                                  );
                                                },
                                                child: Column(
                                                  children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(10),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.location_on, size: 20),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                            child: Text(
                                                            stopName ?? 'Зупинка №$stopId',
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  ...schedules.take(5).map((schedule) {
                                                    return Column(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                                                          child: Row(
                                                            children: [
                                                              SizedBox(
                                                              height: 50,
                                                              width: 50,
                                                              child: DecoratedBox(
                                                                decoration: BoxDecoration(
                                                                color: Theme.of(context).colorScheme.surfaceContainer,
                                                                borderRadius: BorderRadius.circular(5),
                                                                ),
                                                                child: Center(
                                                                child: SizedBox(
                                                                  width: schedule.transportName == 'Міжміський' ? 28 : 22,
                                                                  child: switch (schedule.transportName) {
                                                                  'Тролейбус' => SvgPicture.asset(
                                                                    'assets/svg/transport/trolleybus.svg',
                                                                    color: const Color(0xFFA2C9FE),
                                                                    fit: BoxFit.contain,
                                                                  ),
                                                                  'Автобус' => SvgPicture.asset(
                                                                    'assets/svg/transport/bus.svg',
                                                                    color: const Color(0xff9ed58b),
                                                                    fit: BoxFit.contain,
                                                                  ),
                                                                  'Маршрутка' => SvgPicture.asset(
                                                                    'assets/svg/transport/route.svg',
                                                                    color: const Color(0xfffeb49f),
                                                                    fit: BoxFit.contain,
                                                                  ),
                                                                  'Поїзд' => SvgPicture.asset(
                                                                    'assets/svg/transport/train.svg',
                                                                    color: const Color(0xFFC39FFE),
                                                                    fit: BoxFit.contain,
                                                                  ),
                                                                  'Електричка' => SvgPicture.asset(
                                                                    'assets/svg/transport/regional.svg',
                                                                    color: const Color(0xFF9FE3FE),
                                                                    fit: BoxFit.contain,
                                                                  ),
                                                                  'Міжміський' => SvgPicture.asset(
                                                                    'assets/svg/transport/intercity.svg',
                                                                    color: const Color(0xFFFEF89F),
                                                                    fit: BoxFit.contain,
                                                                  ),
                                                                  _ => SvgPicture.asset(
                                                                    'assets/svg/transport/bus.svg',
                                                                    color: const Color(0xFFFE9F9F),
                                                                    fit: BoxFit.contain,
                                                                  ),
                                                                  },
                                                                ),
                                                                ),
                                                              ),),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      '${schedule.routeName.startsWith(RegExp(r'[0-9]')) ? '№' : ''}${schedule.routeName} • ${schedule.directionName}',
                                                                      style: TextStyle(
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.w500,
                                                                        decoration: schedule.worksNow ? null : TextDecoration.lineThrough,
                                                                      ),
                                                                      overflow: TextOverflow.ellipsis,
                                                                      maxLines: 1,
                                                                    ),
                                                                    const SizedBox(height: 4),
                                                                    schedule.worksNow
                                                                      ? Row(
                                                                          children: [
                                                                            if (schedule.times.isNotEmpty) ...[
                                                                              const Icon(
                                                                                Icons.transfer_within_a_station_rounded,
                                                                                size: 16,
                                                                              ),
                                                                              const SizedBox(width: 4),
                                                                              Text(
                                                                                schedule.times.first.localTimeFormatted,
                                                                              ),
                                                                            ],
                                                                            if (schedule.times.isNotEmpty && schedule.interval.isNotEmpty) ...[
                                                                              const SizedBox(width: 8),
                                                                              const Text('•'),
                                                                              const SizedBox(width: 8),
                                                                            ],
                                                                            if (schedule.interval.isNotEmpty) ...[
                                                                              const Icon(
                                                                                Icons.timelapse_rounded,
                                                                                size: 16,
                                                                              ),
                                                                              const SizedBox(width: 4),
                                                                              Text(
                                                                                '${schedule.interval} хв',
                                                                              ),
                                                                            ],
                                                                          ],
                                                                        )
                                                                      : Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.cancel_outlined,
                                                                              size: 16,
                                                                              color: Theme.of(context).colorScheme.error,
                                                                            ),
                                                                            const SizedBox(width: 4),
                                                                            Text(
                                                                              'Не функціонує',
                                                                              style: TextStyle(
                                                                                color: Theme.of(context).colorScheme.error,
                                                                                fontStyle: FontStyle.italic,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                  ],
                                                ),
                                                ),
                                              ),
                                              ),
                                              );
                                  }).toList(),
                          );
                        },
                      );
                    },
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
                                onTap: () async {
                                  await Future.delayed(const Duration(milliseconds: 300));  
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NewsDetailScreen(newsItem: newsItem),
                                    ),
                                  );
                                },
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
