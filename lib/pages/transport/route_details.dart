import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../models/routedetails.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';

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
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor? _busStopIcon;

  // Видалити змінні для відслідковування прокрутки
  final ScrollController _scrollController = ScrollController();

  // Додайте нове поле для зберігання стилю карти
  String? _lightMapStyle;
  String? _darkMapStyle;

  @override
  void initState() {
    super.initState();
    _initializeMapRenderer();
    _loadRouteDetails();
    _createBusStopIcon();
    _loadMapStyles(); // Завантажуємо обидва стилі
  }

  void _initializeMapRenderer() {
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true; 
    }
  }

  Future<void> _createBusStopIcon() async {
    final recorder = ui.PictureRecorder();
    const size = 75.0;
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    
    const padding = 15.0;
    const squareSize = 45.0;
    
    final bgPaint = Paint()
      ..color = const Color.fromARGB(255, 61, 61, 61)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, squareSize, squareSize),
        const Radius.circular(7),
      ),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = widget.transportName == 'Тролейбус'
          ? const Color(0xFFA2C9FE)
          : widget.transportName == 'Автобус'
              ? const Color(0xff9ed58b)
              : const Color(0xfffeb49f)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, squareSize, squareSize),
        const Radius.circular(10),
      ),
      borderPaint,
    );
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_bus.codePoint),
      style: TextStyle(
        fontSize: 30,
        color: const Color.fromARGB(255, 255, 255, 255),
        fontFamily: Icons.directions_bus.fontFamily,
      ),
    );
    
    textPainter.layout();
    final double iconX = padding + (squareSize - textPainter.width) / 2;
    final double iconY = padding + (squareSize - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(iconX, iconY));
    
    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      setState(() {
        _busStopIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      });
    }
  }

  Future<void> _loadRouteDetails() async {
    try {
      setState(() => _isLoading = true);
      
      final routeResponse = await http.get(
        Uri.parse('https://gps.easyway.info/api/city/poltava/route/${widget.routeId}'),
      );

      if (routeResponse.statusCode == 200) {
        final routeData = json.decode(routeResponse.body);
        if (routeData['status'] == 'ok') {
          await RouteDetails.loadStations();
          
          setState(() {
            _routeDetails = RouteDetails.fromJson(routeData);
            _createMapMarkers();
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

  // Оновити метод _createMapMarkers щоб показувати всі маршрути
  void _createMapMarkers() {
    if (_routeDetails == null || RouteDetails._stations == null) return;

    _markers.clear();
    _polylines.clear();

    // Для кожного напрямку
    for (var direction in _routeDetails!.directions) {
      List<LatLng> polylinePoints = [];
      
      for (var stop in direction.stops) {
        final stopData = RouteDetails._stations![stop.stopId.toString()];
        if (stopData != null && stopData.length >= 2) {
          final lat = stopData[0] / 1000000.0;
          final lng = stopData[1] / 1000000.0;
          final position = LatLng(lat, lng);
          
          polylinePoints.add(position);
          
          // Додаємо маркер тільки якщо його ще немає
          if (!_markers.any((m) => m.markerId.value == 'stop_${stop.stopId}')) {
            _markers.add(Marker(
              markerId: MarkerId('stop_${stop.stopId}'),
              position: position,
              icon: _busStopIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(title: stop.stopName),
            ));
          }
        }
      }

      _polylines.add(Polyline(
        polylineId: PolylineId('route_${direction.tripId}'),
        points: polylinePoints,
        color: widget.transportName == 'Тролейбус'
            ? const Color(0xFFA2C9FE)
            : widget.transportName == 'Автобус'
                ? const Color(0xff9ed58b)
                : const Color(0xfffeb49f),
        width: 3,
      ));
    }

    if (_mapController != null && _markers.isNotEmpty) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;

    for (var marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50,
      ),
    );
  }

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

  // Видалити метод _onScroll

  // Завантаження обох стилів карти
  Future<void> _loadMapStyles() async {
    _darkMapStyle = await rootBundle.loadString('assets/json/darkmap.json');
    // Можна залишити стандартний стиль для світлої теми
    // або створити окремий файл lightmap.json
    _lightMapStyle = null; 
  }

  // Оновлений метод _onMapCreated
  void _onMapCreated(GoogleMapController controller) {
    try {
      setState(() {
        _mapController = controller;
      });
      _setMapStyle();
      if (_markers.isNotEmpty) {
        _fitBounds();
      }
    } catch (e) {
      debugPrint('Error creating map: $e');
    }
  }

  // Новий метод для встановлення стилю в залежності від теми
  void _setMapStyle() {
    if (_mapController == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    _mapController!.setMapStyle(isDark ? _darkMapStyle : _lightMapStyle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Оновлюємо стиль карти при зміні теми
    if (_mapController != null) {
      _setMapStyle();
    }
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
              : Column(
                  children: [
                    Container(
                      height: 200,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(49.589633, 34.551417),
                            zoom: 12,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: false, // Вимкнути компас
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder( // Видалити RefreshIndicator
                        controller: _scrollController, // Додаємо контролер
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
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}

class RouteDetails {
  final List<RouteDirection> directions;
  static Map<String, dynamic>? _stations;

  RouteDetails({required this.directions});

  static Future<void> loadStations() async {
    if (_stations != null) return;
    
    final String jsonString = await rootBundle.loadString('assets/json/stations.json');
    _stations = json.decode(jsonString);
  }

  static String getStopName(String stopId) {
    if (_stations == null) return 'Зупинка №$stopId';
    
    final stopData = _stations![stopId];
    if (stopData == null || stopData.length < 3) return 'Зупинка №$stopId';
    
    return stopData[2] as String;
  }

  factory RouteDetails.fromJson(Map<String, dynamic> json) {
    final directionsData = json['data']['directions'] as List;
    return RouteDetails(
      directions: directionsData.map((dir) => RouteDirection.fromJson(dir)).toList(),
    );
  }
}

class RouteDirection {
  final int calendarTripId;
  final int calendarId;
  final int tripId;
  final List<RouteStop> stops;

  RouteDirection({
    required this.calendarTripId,
    required this.calendarId,
    required this.tripId,
    required this.stops,
  });

  factory RouteDirection.fromJson(Map<String, dynamic> json) {
    return RouteDirection(
      calendarTripId: json['calendar_trip_id'],
      calendarId: json['calendar_id'], 
      tripId: json['trip_id'],
      stops: (json['stops'] as List).map((stop) => RouteStop.fromJson(stop)).toList(),
    );
  }
}

class RouteStop {
  final int stopId;
  final String stopName;
  final List<StopTime> times;

  RouteStop({
    required this.stopId,
    required this.stopName,
    required this.times,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      stopId: json['stop_id'],
      stopName: RouteDetails.getStopName(json['stop_id'].toString()),
      times: (json['times'] as List).map((time) => StopTime.fromJson(time)).toList(),
    );
  }
}