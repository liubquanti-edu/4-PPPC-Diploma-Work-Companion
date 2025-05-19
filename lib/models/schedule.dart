//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

class Lesson {
  final String name;
  final String place;
  final String prof;
  final String? week;

  Lesson({
    required this.name,
    required this.place, 
    required this.prof,
    this.week,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      name: json['name'],
      place: json['place'], 
      prof: json['prof'],
      week: json['week'],
    );
  }
}