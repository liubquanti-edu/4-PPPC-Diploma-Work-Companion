import 'package:flutter/material.dart';
import '/models/schedule.dart';

class LessonDetailsScreen extends StatelessWidget {
  final Lesson lesson;
  final String startTime;
  final String endTime;

  const LessonDetailsScreen({
    Key? key,
    required this.lesson,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Деталі заняття'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, 
                          color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('$startTime - $endTime'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_rounded,
                          color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(lesson.prof)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                          color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(lesson.place),
                      ],
                    ),
                    if (lesson.week != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                            color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                            Text('${lesson.week == 'numerator' ? 'Чисельник' : 'Знаменник'}'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}