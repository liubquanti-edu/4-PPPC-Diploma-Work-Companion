import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String name;
  final int semester;
  final List<int> groups;
  final DateTime start;
  final DateTime end;

  Course({
    required this.name,
    required this.semester,
    required this.groups,
    required this.start,
    required this.end,
  });

  factory Course.fromFirestore(Map<String, dynamic> data) {
    return Course(
      name: data['name'] ?? '',
      semester: data['semester'] ?? 0,
      groups: List<int>.from(data['groups'] ?? []),
      start: (data['start'] as Timestamp).toDate(),
      end: (data['end'] as Timestamp).toDate(),
    );
  }
}