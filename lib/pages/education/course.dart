import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/models/course.dart';
import '/models/schedule.dart';
import '/pages/info/subject.dart';

class CourseDetailsPage extends StatefulWidget {
  final Course course;

  const CourseDetailsPage({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  int _userGroup = 0;
  
  Map<String, Map<int, Map<String, Lesson>>> _scheduleData = {};
  
  final List<String> _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
  
  final Map<String, String> _dayNames = {
    'monday': 'Понеділок',
    'tuesday': 'Вівторок',
    'wednesday': 'Середа',
    'thursday': 'Четвер',
    'friday': 'П\'ятниця',
  };
  
  Map<String, dynamic> _cachedSubjects = {};
  Map<String, dynamic> _cachedTeachers = {};
  
  int _maxLessons = 0;

  @override
  void initState() {
    super.initState();
    _loadUserGroup();
  }
  
  Future<void> _loadUserGroup() async {
    try {
      final userDoc = await _firestore
          .collection('students')
          .doc(_auth.currentUser?.uid)
          .get();
          
      final group = userDoc.data()?['group'] as int?;
      
      if (group != null) {
        setState(() {
          _userGroup = group;
        });
        
        await _fetchSchedule();
      }
    } catch (e) {
      debugPrint('Error loading user group: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSchedule() async {
    if (_userGroup == 0) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      final scheduleDoc = await _firestore
          .collection('courses')
          .doc(widget.course.id)
          .collection('schedule')
          .doc(_userGroup.toString())
          .get();

      if (!scheduleDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final numeratorData = scheduleDoc.data()?['numerator'] as Map<String, dynamic>?;
      final denominatorData = scheduleDoc.data()?['denominator'] as Map<String, dynamic>?;

      if (numeratorData == null && denominatorData == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, Map<int, Map<String, Lesson>>> scheduleData = {};
      
      for (final day in _days) {
        scheduleData[day] = {};
      }

      int maxLessons = 0;
      
      if (numeratorData != null) {
        for (final day in numeratorData.keys) {
          final daySchedule = numeratorData[day] as Map<String, dynamic>?;
          if (daySchedule != null) {
            for (final lessonNumber in daySchedule.keys) {
              final lessonData = daySchedule[lessonNumber] as Map<String, dynamic>;
              final lesson = await _processLesson(lessonData);
              
              final lessonNum = int.tryParse(lessonNumber) ?? 0;
              if (lessonNum > maxLessons) maxLessons = lessonNum;
              
              if (!scheduleData.containsKey(day)) {
                scheduleData[day] = {};
              }
              
              if (!scheduleData[day]!.containsKey(lessonNum)) {
                scheduleData[day]![lessonNum] = {};
              }
              
              scheduleData[day]![lessonNum]!['numerator'] = lesson;
            }
          }
        }
      }
      
      if (denominatorData != null) {
        for (final day in denominatorData.keys) {
          final daySchedule = denominatorData[day] as Map<String, dynamic>?;
          if (daySchedule != null) {
            for (final lessonNumber in daySchedule.keys) {
              final lessonData = daySchedule[lessonNumber] as Map<String, dynamic>;
              final lesson = await _processLesson(lessonData);
              
              final lessonNum = int.tryParse(lessonNumber) ?? 0;
              if (lessonNum > maxLessons) maxLessons = lessonNum;
              
              if (!scheduleData.containsKey(day)) {
                scheduleData[day] = {};
              }
              
              if (!scheduleData[day]!.containsKey(lessonNum)) {
                scheduleData[day]![lessonNum] = {};
              }
              
              scheduleData[day]![lessonNum]!['denominator'] = lesson;
            }
          }
        }
      }

      setState(() {
        _scheduleData = scheduleData;
        _maxLessons = maxLessons;
        _isLoading = false;
      });
      
    } catch (e) {
      debugPrint('Error fetching schedule: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Lesson> _processLesson(Map<String, dynamic> lessonData) async {
    final subjectId = lessonData['subjectId'];
    final teacherId = lessonData['teacherId'];
    final commissionId = lessonData['commissionId'];

    String subjectName = '';
    if (_cachedSubjects.containsKey(subjectId)) {
      subjectName = _cachedSubjects[subjectId]['name'] ?? '';
    } else {
      try {
        final commissionDoc = await _firestore
            .collection('cyclecommission')
            .doc(commissionId)
            .get();

        final subjectDoc = await commissionDoc.reference
            .collection('subjects')
            .doc(subjectId)
            .get();
            
        if (subjectDoc.exists) {
          _cachedSubjects[subjectId] = subjectDoc.data() ?? {};
          subjectName = subjectDoc.data()?['name'] ?? '';
        }
      } catch (e) {
        debugPrint('Error fetching subject: $e');
      }
    }

    String teacherName = '';
    if (_cachedTeachers.containsKey(teacherId)) {
      teacherName = _cachedTeachers[teacherId]['name'] ?? '';
    } else {
      try {
        final teacherDoc = await _firestore
            .collection('teachers')
            .doc(teacherId)
            .get();
            
        if (teacherDoc.exists) {
          _cachedTeachers[teacherId] = teacherDoc.data() ?? {};
          teacherName = teacherDoc.data()?['name'] ?? '';
        }
      } catch (e) {
        debugPrint('Error fetching teacher: $e');
      }
    }

    return Lesson(
      name: subjectName,
      place: lessonData['room'] ?? '',
      prof: teacherName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Деталі курсу'),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Група $_userGroup',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month, 
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.course.semester}-й семестр',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time_outlined, 
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('dd.MM.yy').format(widget.course.start)} - ${DateFormat('dd.MM.yy').format(widget.course.end)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    'Розклад занять',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ч - чисельник, З - знаменник',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildScheduleTable(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
            headingRowColor: MaterialStateProperty.resolveWith<Color>(
              (Set<MaterialState> states) => Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            clipBehavior: Clip.antiAlias,
            border: TableBorder.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 1,
              borderRadius: BorderRadius.circular(10),
            ),
          headingRowHeight: 40,
          dataRowMinHeight: 50,
          dataRowMaxHeight: 80,
          columns: [
            DataColumn(
              label: Container(
                alignment: Alignment.center,
                child: const Text(
                  '№',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ...List.generate(_days.length, (index) {
              final day = _days[index];
              return DataColumn(
                label: Container(
                  width: 120,
                  alignment: Alignment.center,
                  child: Text(
                    _dayNames[day] ?? day,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ],
          rows: List.generate(_maxLessons, (index) {
            final lessonNumber = index + 1;
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      '$lessonNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                ..._days.map((day) {
                  final lessonData = _scheduleData[day]?[lessonNumber] ?? {};
                  
                  final numeratorLesson = lessonData['numerator'];
                  final denominatorLesson = lessonData['denominator'];
                  
                  if (numeratorLesson == null && denominatorLesson == null) {
                    return const DataCell(SizedBox());
                  }
                  
                  if (numeratorLesson?.name == denominatorLesson?.name || 
                      (numeratorLesson != null && denominatorLesson == null) || 
                      (numeratorLesson == null && denominatorLesson != null)) {
                    final lesson = numeratorLesson ?? denominatorLesson!;
                    return DataCell(
                      InkWell(
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 300));
                          _showLessonDetails(lesson, lessonNumber);
                        },
                        child: Ink(
                          width: 120,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            lesson.name,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    );
                  } 
                  else {
                    return DataCell(
                      Container(
                        width: 120,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (numeratorLesson != null)
                              InkWell(
                                customBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onTap: () async {
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  _showLessonDetails(numeratorLesson, lessonNumber);
                                },
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Ч: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          numeratorLesson.name,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            Divider(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              thickness: 1.5,
                            ),
                            if (denominatorLesson != null)
                              InkWell(
                                customBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onTap: () async {
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  _showLessonDetails(denominatorLesson, lessonNumber);
                                },
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'З: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          denominatorLesson.name,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                }).toList(),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _showLessonDetails(Lesson lesson, int lessonNumber) async {
    final bellTimes = await _fetchBellSchedule(lessonNumber);
    
    if (!context.mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailsScreen(
          lesson: lesson,
          startTime: bellTimes['start'] ?? '',
          endTime: bellTimes['end'] ?? '',
        ),
      ),
    );
  }
  
  Future<Map<String, String>> _fetchBellSchedule(int lessonNumber) async {
    try {
      final doc = await _firestore
          .collection('bell')
          .doc(lessonNumber.toString())
          .get();

      final startParts = (doc.data()?['start'] as String?)?.split(':') ?? [];
      final endParts = (doc.data()?['end'] as String?)?.split(':') ?? [];
      
      if (startParts.length != 2 || endParts.length != 2) {
        return {'start': '', 'end': ''};
      }

      return {'start': '${startParts[0]}:${startParts[1]}', 'end': '${endParts[0]}:${endParts[1]}'};
    } catch (e) {
      debugPrint('Error fetching bell schedule: $e');
      return {'start': '', 'end': ''};
    }
  }
}