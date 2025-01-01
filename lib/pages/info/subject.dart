import 'package:flutter/material.dart';
import '/models/schedule.dart';

class LessonDetailsScreen extends StatefulWidget {
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
  State<LessonDetailsScreen> createState() => _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends State<LessonDetailsScreen> {
  int currentFloor = 1;

  String getFloorFromRoom() {
    final roomNumber = int.tryParse(widget.lesson.place.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return (roomNumber ~/ 100).toString();
  }

  void navigateFloor(int direction) {
    setState(() {
      currentFloor = (currentFloor + direction).clamp(1, 3);
    });
  }

  String getFloorName(int floor) {
    switch (floor) {
      case 1:
        return 'Перший поверх';
      case 2:
        return 'Другий поверх';
      case 3:
        return 'Третій поверх';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    currentFloor = int.parse(getFloorFromRoom());
  }

  void _showEnlargedMap(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ColorFiltered(
                  colorFilter: Theme.of(context).brightness == Brightness.dark
                    ? const ColorFilter.matrix([
                        -1, 0, 0, 0, 255,
                        0, -1, 0, 0, 255,
                        0, 0, -1, 0, 255,
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.matrix([
                        1, 0, 0, 0, 0,
                        0, 1, 0, 0, 0,
                        0, 0, 1, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                  child: Image.asset(
                    'assets/img/map/$currentFloor.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
                      widget.lesson.name,
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
                        Text('${widget.startTime} - ${widget.endTime}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_rounded,
                          color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(child: Text(widget.lesson.prof)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                          color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(widget.lesson.place),
                      ],
                    ),
                    if (widget.lesson.week != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                            color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(widget.lesson.week == 'numerator' ? 'Чисельник' : 'Знаменник'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showEnlargedMap(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ColorFiltered(
                          colorFilter: Theme.of(context).brightness == Brightness.dark
                            ? const ColorFilter.matrix([
                                -1, 0, 0, 0, 255,
                                0, -1, 0, 0, 255,
                                0, 0, -1, 0, 255,
                                0, 0, 0, 1, 0,
                              ])
                            : const ColorFilter.matrix([
                                1, 0, 0, 0, 0,
                                0, 1, 0, 0, 0,
                                0, 0, 1, 0, 0,
                                0, 0, 0, 1, 0,
                              ]),
                          child: Image.asset(
                            'assets/img/map/$currentFloor.jpg',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: currentFloor > 1 ? () => navigateFloor(-1) : null,
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        Text(
                          getFloorName(currentFloor),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: currentFloor < 3 ? () => navigateFloor(1) : null,
                          icon: const Icon(Icons.arrow_upward),
                        ),
                      ],
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
}