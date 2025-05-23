//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/transport.dart';
import 'route_details.dart';

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
        centerTitle: true,
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
                        '${schedule.routeName.isNotEmpty && RegExp(r'[0-9]').hasMatch(schedule.routeName[0]) ? '№' : ''}${schedule.routeName} • ${schedule.directionName}',
                        style: TextStyle(
                          decoration: schedule.worksNow ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (schedule.times.isNotEmpty) ...[
                          Text(
                            'Наступний: ${schedule.times.first.localTimeFormatted}'
                            '${schedule.times.first.bortNumber != null ? ' (${schedule.times.first.bortNumber})' : ''}',
                          ),
                        ],
                        if (schedule.interval.isNotEmpty)
                        Text('Інтервал: ${schedule.interval} хв'),
                        if (!schedule.worksNow)
                        Row(
                          children: [
                            Text('Не функціонує', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                        ),
                      ],
                    ),
                        onTap: () async {
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (context.mounted) {
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RouteDetailsScreen(
                            routeId: schedule.routeId,
                            routeName: schedule.routeName,
                            transportName: schedule.transportName,
                            ),
                          ),
                          );
                        }
                        },
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
        width: 24,
        color: const Color(0xFFA2C9FE),
      );
      case 'Автобус':
      return SvgPicture.asset(
        'assets/svg/transport/bus.svg',
        width: 24,
        color: const Color(0xff9ed58b),
      );
      case 'Маршрутка':
      return SvgPicture.asset(
        'assets/svg/transport/route.svg',
        width: 24,
        color: const Color(0xfffeb49f),
      );
      case 'Поїзд':
      return SvgPicture.asset(
        'assets/svg/transport/train.svg',
        width: 24,
        color: const Color(0xFFC39FFE),
      );
      case 'Електричка':
      return SvgPicture.asset(
        'assets/svg/transport/regional.svg',
        width: 24,
        color: const Color(0xFF9FE3FE),
      );
      case 'Міжміський':
      return SvgPicture.asset(
        'assets/svg/transport/intercity.svg',
        width: 30,
        color: const Color(0xFFFEF89F),
      );
      default:
      return SvgPicture.asset(
        'assets/svg/transport/bus.svg',
        width: 24,
        color: const Color(0xFFFE9F9F),
      );
    }
  }
}