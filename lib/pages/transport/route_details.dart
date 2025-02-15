import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/routedetails.dart';

class RouteDetailsScreen extends StatefulWidget {
  final int routeId;
  final String routeName;
  final String transportName;

  const RouteDetailsScreen({
    Key? key,
    required this.routeId,
    required this.routeName,
    required this.transportName,
  }) : super(key: key);

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  RouteDetails? _routeDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteDetails();
  }

  Future<void> _loadRouteDetails() async {
    try {
      setState(() => _isLoading = true);
      
      // Отримуємо деталі маршруту
      final routeResponse = await http.get(
        Uri.parse('https://gps.easyway.info/api/city/poltava/route/${widget.routeId}'),
      );

      if (routeResponse.statusCode == 200) {
        final routeData = json.decode(routeResponse.body);
        if (routeData['status'] == 'ok') {
          // Завантажуємо назви для кожної зупинки
          final directions = routeData['data']['directions'] as List;
          for (var direction in directions) {
            final stops = direction['stops'] as List;
            for (var stop in stops) {
              final stopId = stop['stop_id'];
              // Отримуємо дані про конкретну зупинку
              final stopResponse = await http.get(
                Uri.parse('https://gps.easyway.info/api/city/poltava/lang/ua/stop/$stopId'),
              );
              
              if (stopResponse.statusCode == 200) {
                final stopData = json.decode(stopResponse.body);
                if (stopData['status'] == 'ok') {
                  stop['stop_name'] = stopData['data']['name'];
                }
              }
            }
          }

          setState(() {
            _routeDetails = RouteDetails.fromJson(routeData);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка завантаження деталей: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Додамо новий метод для групування транспорту за першою зупинкою:
  Map<int, StopTime> _findFirstStopForEachTransport(RouteDirection direction) {
    Map<int, StopTime> firstStopForTransport = {};
    Map<String, int> vehicleFirstStop = {};

    for (int i = 0; i < direction.stops.length; i++) {
      final stop = direction.stops[i];
      for (var time in stop.times) {
        if (time.vehicleNumber != null && 
            !vehicleFirstStop.containsKey(time.vehicleNumber)) {
          vehicleFirstStop[time.vehicleNumber!] = i;
          firstStopForTransport[i] = time;
        }
      }
    }
    return firstStopForTransport;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.transportName}${widget.routeName.startsWith(RegExp(r'[0-9]')) ? ' №' : ' '}${widget.routeName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routeDetails == null
              ? const Center(child: Text('Немає даних про маршрут'))
              : RefreshIndicator(
                  onRefresh: _loadRouteDetails,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _routeDetails!.directions.length,
                    itemBuilder: (context, directionIndex) {
                      final direction = _routeDetails!.directions[directionIndex];
                      final firstStopForTransport = _findFirstStopForEachTransport(direction);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    '${direction.stops.first.stopName}',
                                    style: Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Icon(Icons.arrow_downward),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${direction.stops.last.stopName}',
                                    style: Theme.of(context).textTheme.titleLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            ...direction.stops.asMap().entries.map((entry) {
                              final index = entry.key;
                              final stop = entry.value;
                              final transportAtThisStop = firstStopForTransport[index];
                              
                              return Column(
                                children: [
                                  if (transportAtThisStop != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            widget.transportName == 'Тролейбус'
                                                ? 'assets/svg/transport/trolleybus.svg'
                                                : widget.transportName == 'Автобус'
                                                    ? 'assets/svg/transport/bus.svg'
                                                    : widget.transportName == 'Маршрутка'
                                                        ? 'assets/svg/transport/route.svg'
                                                        : 'assets/svg/transport/bus.svg',
                                            width: 24,
                                            color: widget.transportName == 'Тролейбус'
                                                ? const Color(0xFFA2C9FE)
                                                : widget.transportName == 'Автобус'
                                                    ? const Color(0xff9ed58b)
                                                    : widget.transportName == 'Маршрутка'
                                                        ? const Color(0xfffeb49f)
                                                        : const Color(0xFFFE9F9F),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${transportAtThisStop.vehicleNumber != null 
                                                ? ' ${transportAtThisStop.vehicleNumber}'
                                                : ''}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ListTile(
                                    leading: Icon(
                                      stop.times.isNotEmpty 
                                          ? Icons.location_on
                                          : Icons.location_on_outlined,
                                      color: stop.times.isNotEmpty 
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey,
                                    ),
                                    title: Text(stop.stopName),
                                    subtitle: stop.times.isNotEmpty
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: stop.times.map((time) {
                                              return Text(
                                              'Прибуття: ${time.localTimeFormatted}'
                                              '${time.vehicleNumber != null ? ' (${time.vehicleNumber})' : ''}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            );
                                            }).toList(),
                                          )
                                        : const Text(
                                            'Немає даних про прибуття',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}