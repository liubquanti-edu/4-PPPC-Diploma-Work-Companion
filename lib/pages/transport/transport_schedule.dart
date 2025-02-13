import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/transport.dart';

class TransportScheduleScreen extends StatelessWidget {
  final List<TransportSchedule> schedules;

  const TransportScheduleScreen({
    Key? key,
    required this.schedules,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Розклад транспорту'),
      ),
      body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: schedules.length,
                separatorBuilder: (context, index) {
                  return const SizedBox.shrink();
                },
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return ListTile(
                    leading: _getTransportIcon(schedule.transportName),
                    title: Text(
                      '№${schedule.routeName} • ${schedule.directionName}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (schedule.times.isNotEmpty) ...[
                          Text(
                            'Наступний: ${schedule.times.first.arrivalTimeFormatted}' +
                            (schedule.times.first.bortNumber != null 
                              ? ' (${schedule.times.first.bortNumber})'
                              : ''),
                          ),
                        ],
                        Text('Інтервал: ${schedule.interval} хв'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  Widget _getTransportIcon(String transportName) {
    switch (transportName) {
      case 'Тролейбус':
        return SvgPicture.asset(
          'assets/svg/transport/trolleybus.svg',
          width: 20,
          color: const Color(0xFFA2C9FE),
        );
      case 'Автобус':
        return SvgPicture.asset(
          'assets/svg/transport/bus.svg',
          width: 20,
          color: const Color(0xff9ed58b),
        );
      case 'Маршрутка':
        return SvgPicture.asset(
          'assets/svg/transport/route.svg',
          width: 20,
          color: const Color(0xfffeb49f),
        );
      default:
        return SvgPicture.asset(
          'assets/svg/transport/bus.svg',
          width: 20,
          color: const Color(0xFFFE9F9F),
        );
    }
  }
}