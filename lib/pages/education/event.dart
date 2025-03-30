import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../education.dart';

class EventDetailsPage extends StatelessWidget {
  final CourseEvent event;

  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'uk_UA');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Деталі події'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          event.icon,
                          size: 40.0,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Flexible(
                        child: Text(
                          event.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                  ),
                ),
                child: Row(
                  children: [
                  Icon(
                    Icons.date_range,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                      'Період проведення',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                      '${dateFormat.format(event.start)} - ${dateFormat.format(event.end)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    ),
                  ),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),
                Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                  ),
                ),
                child: Row(
                  children: [
                  Icon(
                    Icons.timelapse,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                      'Тривалість',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                      _getDurationText(event.start, event.end),
                      style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                    ),
                  ),
                  ],
                ),
              ),
              
              const SizedBox(height: 10.0),
              
              if (event.description.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.0,
                  ),
                  ),
                  child: Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ] else ...[

              ],
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getDurationText(DateTime start, DateTime end) {
    final difference = end.difference(start);
    
    final days = difference.inDays;
    final months = days ~/ 30;
    final years = days ~/ 365;
    
    if (years > 0) {
      return '$years ${_pluralizeYears(years)}';
    } else if (months > 0) {
      return '$months ${_pluralizeMonths(months)}';
    } else {
      return '$days ${_pluralizeDays(days)}';
    }
  }
  
  String _pluralizeDays(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'день';
    } else if ([2, 3, 4].contains(count % 10) && 
               ![12, 13, 14].contains(count % 100)) {
      return 'дні';
    } else {
      return 'днів';
    }
  }
  
  String _pluralizeMonths(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'місяць';
    } else if ([2, 3, 4].contains(count % 10) && 
               ![12, 13, 14].contains(count % 100)) {
      return 'місяці';
    } else {
      return 'місяців';
    }
  }
  
  String _pluralizeYears(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'рік';
    } else if ([2, 3, 4].contains(count % 10) && 
               ![12, 13, 14].contains(count % 100)) {
      return 'роки';
    } else {
      return 'років';
    }
  }
}