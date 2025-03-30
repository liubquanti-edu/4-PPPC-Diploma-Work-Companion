import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/models/course.dart';
import 'package:pppc_companion/pages/education/event.dart';
import 'package:pppc_companion/pages/education/course.dart';
import 'package:card_loading/card_loading.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({Key? key}) : super(key: key);

  @override
  _EducationPageState createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  Course? _currentCourse;
  List<CourseEvent> _events = [];
  bool _isLoadingEvents = false;
  bool _isLoadingCourse = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoadingCourse = true;
        _isLoadingEvents = true;
      });
      
      final course = await _fetchMainCourse();
      
      if (course != null && mounted) {
        setState(() {
          _currentCourse = course;
          _isLoadingCourse = false;
        });
        await _fetchCourseEvents(course.id);
      } else if (mounted) {
        setState(() {
          _isLoadingCourse = false;
          _isLoadingEvents = false;
        });
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoadingCourse = false;
          _isLoadingEvents = false;
          _isInitialized = true;
        });
      }
    }
  }

  Future<Course?> _fetchMainCourse() async {
    try {
      final userDoc = await _firestore
          .collection('students')
          .doc(_auth.currentUser?.uid)
          .get();
      final userGroup = userDoc.data()?['group'] as int?;

      if (userGroup == null) return null;

      final now = Timestamp.now();

      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('groups', arrayContains: userGroup)
          .where('start', isLessThanOrEqualTo: now)
          .where('end', isGreaterThan: now)
          .limit(1)
          .get();

      if (coursesSnapshot.docs.isEmpty) return null;

      final course = Course.fromFirestore(coursesSnapshot.docs.first.data());
      course.id = coursesSnapshot.docs.first.id;
      
      return course;
    } catch (e) {
      debugPrint('Error fetching course: $e');
      return null;
    }
  }
  
  Future<void> _fetchCourseEvents(String courseId) async {
    if (!mounted) return;
    
    try {
      final eventsSnapshot = await _firestore
          .collection('courses')
          .doc(courseId)
          .collection('events')
          .orderBy('start')
          .get();
          
      final events = eventsSnapshot.docs
          .map((doc) => CourseEvent(
                id: doc.id,
                name: doc.data()['name'] as String? ?? 'Unnamed Event',
                start: (doc.data()['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
                end: (doc.data()['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
                icon: _getEventIcon(doc.data()['name'] as String? ?? ''),
                description: doc.data()['description'] as String? ?? '',
              ))
          .toList();
      
      if (mounted) {
        setState(() {
          _events = events;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching events: $e');
      if (mounted) {
        setState(() {
          _isLoadingEvents = false;
        });
      }
    }
  }
  
  IconData _getEventIcon(String eventName) {
    final lowerName = eventName.toLowerCase();
    if (lowerName.contains('курсов')) return Icons.verified;
    if (lowerName.contains('сесі')) return Icons.how_to_reg_sharp;
    if (lowerName.contains('практик')) return Icons.work;
    if (lowerName.contains('канікул')) return Icons.stream_rounded;
    return Icons.event;
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 20,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Головний курс 🎯',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 10.0, width: double.infinity),
              SizedBox(
                width: double.infinity,
                child: _isLoadingCourse
                  ? _buildLoadingCard()
                  : _currentCourse == null
                    ? _buildEmptyCourseCard()
                    : _buildCourseCard(_currentCourse!),
              ),
              const SizedBox(height: 20.0, width: double.infinity),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Основна інформація ℹ️',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20.0),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 10.0, width: double.infinity),
              _isLoadingCourse || _isLoadingEvents
                ? _buildLoadingEventsList()
                : _events.isEmpty
                    ? _buildEmptyEventsList()
                    : _buildEventsList(),
              const SizedBox(height: 20.0, width: double.infinity),
              SizedBox(
                width: double.infinity,
                child: Text(
                  'Додаткові курси 🔎',
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
                    color: Theme.of(context).colorScheme.onSecondary,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Іноземна мова', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 18.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('01/09/2024 - 01/01/2025', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
                              const SizedBox(width: 5.0),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Icon(Icons.arrow_forward, size: 30.0, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingEventsList() {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
            padding: EdgeInsets.only(bottom: index < 1 ? 10.0 : 0.0),
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSecondary,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary, 
                width: 2.0
              ),
            ),
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
                    child: CardLoading(
                      height: 50,
                      width: 50,
                      borderRadius: BorderRadius.circular(5),
                      cardLoadingTheme: CardLoadingTheme(
                        colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardLoading(
                      height: 16,
                      width: 150,
                      borderRadius: BorderRadius.circular(5),
                      margin: const EdgeInsets.only(bottom: 8),
                      cardLoadingTheme: CardLoadingTheme(
                        colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    CardLoading(
                      height: 12,
                      width: 120,
                      borderRadius: BorderRadius.circular(5),
                      cardLoadingTheme: CardLoadingTheme(
                        colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyEventsList() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSecondary,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0
        ),
      ),
      child: const Center(
        child: Text('Немає запланованих подій'),
      ),
    );
  }
  
  Widget _buildEventsList() {
    return Column(
      children: _events.map((event) => _buildEventCard(event)).toList(),
    );
  }
  
  Widget _buildEventCard(CourseEvent event) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: EdgeInsets.only(bottom: _events.indexOf(event) < _events.length - 1 ? 10.0 : 0.0),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: () async {
          await Future.delayed(const Duration(milliseconds: 300));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsPage(event: event),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSecondary,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary, 
              width: 2.0
            ),
          ),
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
                    event.icon,
                    size: 30.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.name, 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 5.0),
                        Flexible(
                          child: Text(
                            '${dateFormat.format(event.start)} - ${dateFormat.format(event.end)}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, size: 30.0, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSecondary,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardLoading(
                height: 24,
                width: 200,
                borderRadius: BorderRadius.circular(5),
                margin: const EdgeInsets.only(bottom: 8),
                cardLoadingTheme: CardLoadingTheme(
                  colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
              CardLoading(
                height: 10,
                width: 150,
                borderRadius: BorderRadius.circular(5), 
                margin: const EdgeInsets.only(bottom: 8),
                cardLoadingTheme: CardLoadingTheme(
                  colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
              CardLoading(
                height: 11,
                width: 180,
                borderRadius: BorderRadius.circular(5),
                cardLoadingTheme: CardLoadingTheme(
                  colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),  
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.arrow_forward,
            size: 30.0, 
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCourseCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSecondary,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0
        ),
      ),
      child: const Center(
        child: Text('Немає активних курсів'),
      ),
    );
  }

    Widget _buildCourseCard(Course course) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailsPage(course: course),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSecondary,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 20.0
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 5.0),
                      Text(
                        '${course.semester}-й семестр',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 12.0
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 16.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 5.0),
                      Flexible(
                        child: Text(
                          '${dateFormat.format(course.start)} - ${dateFormat.format(course.end)}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 12.0  
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10.0),
            Icon(
              Icons.arrow_forward,
              size: 30.0,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class CourseEvent {
  final String id;
  final String name;
  final DateTime start;
  final DateTime end;
  final IconData icon;
  final String description;

  CourseEvent({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.icon,
    this.description = '',
  });
}