import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/models/course.dart';
import 'package:card_loading/card_loading.dart';

class EducationPage extends StatefulWidget {
  const EducationPage({Key? key}) : super(key: key);

  @override
  _EducationPageState createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<Course?> _fetchMainCourse() async {
    try {
      // Get user's group
      final userDoc = await _firestore
          .collection('students')
          .doc(_auth.currentUser?.uid)
          .get();
      final userGroup = userDoc.data()?['group'] as int?;

      if (userGroup == null) return null;

      final now = Timestamp.now();

      // Modified query to work with composite index
      final coursesSnapshot = await _firestore
          .collection('courses')
          .where('groups', arrayContains: userGroup)
          .where('start', isLessThanOrEqualTo: now)
          .where('end', isGreaterThan: now)
          .limit(1)
          .get();

      if (coursesSnapshot.docs.isEmpty) return null;

      return Course.fromFirestore(coursesSnapshot.docs.first.data());
    } catch (e) {
      debugPrint('Error fetching course: $e');
      return null;
    }
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
                child: FutureBuilder<Course?>(
                  future: _fetchMainCourse(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard();
                  }

                  final course = snapshot.data;
                  if (course == null) {
                    return _buildEmptyCourseCard();
                  }

                  return _buildCourseCard(course);
                },
              ),
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
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            Icons.verified,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Захист курсової роботи', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('13/11/2024 - 14/11/2024', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
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
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            Icons.how_to_reg_sharp,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Сесія', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('11/11/2024 - 22/11/2024', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
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
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            Icons.work,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Практика', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('01/12/2024 - 31/12/2024', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
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
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Icon(
                            Icons.stream_rounded,
                            size: 30.0,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Зимові канікули', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16.0)),
                          Row(
                            children: [
                              Icon(Icons.access_time_outlined, size: 16.0, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 5.0),
                              Text('01/01/2025 - 15/10/2025', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 12.0)),
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
                height: 16,
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
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSecondary,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2.0
        ),
      ),
      child: const Text('Немає активних курсів'),
    );
  }

  Widget _buildCourseCard(Course course) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
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
              Text(
                course.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 20.0
                ),
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
                  Text(
                    '${dateFormat.format(course.start)} - ${dateFormat.format(course.end)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 12.0  
                    ),
                  ),
                ],
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
}