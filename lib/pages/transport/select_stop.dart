import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../helpers/map_loading_helper.dart';

class StopSelectorScreen extends StatefulWidget {
  const StopSelectorScreen({super.key});

  @override
  State<StopSelectorScreen> createState() => _StopSelectorScreenState();
}

class _StopSelectorScreenState extends State<StopSelectorScreen> {
  Map<String, dynamic> _stations = {};
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  BitmapDescriptor? _busStopIcon;
  BitmapDescriptor? _collegeIcon;
  BitmapDescriptor? _trainStopIcon; // New icon for train stops

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(49.589633, 34.551417), // Полтава center
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    _initializeMapRenderer();
    _loadResources();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mapController != null) {
      final brightness = MediaQuery.of(context).platformBrightness;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      MapStyleHelper.loadMapStyle(themeProvider.mapStyle, brightness).then((style) {
        if (style != null) {
          _mapController?.setMapStyle(style);
        }
      });
    }
  }

  // Update resource loading to include the new train icon
  Future<void> _loadResources() async {
    // Load all icons in parallel
    await Future.wait([
      _createBusStopIcon(),
      _createTrainStopIcon(), // Add this new method call
      _createCollegeIcon(),
    ]);
    
    // Load stations after icons are ready
    await _loadStations();
    
    // Create markers
    _createMarkers();
  }

  // Метод для створення кастомної іконки зупинки
  Future<void> _createBusStopIcon() async {
    // Створюємо canvas для малювання квадрата з іконкою автобуса
    final recorder = ui.PictureRecorder();
    const size = 75.0; // Зменшуємо розмір канвасу вдвічі (було 100.0)
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    
    // Додаємо відступ для уникнення обрізання
    const padding = 15.0; // Зменшуємо відступ (було 20.0)
    const squareSize = 45.0; // Зменшуємо розмір квадрата (було 60.0)
    
    // Малюємо квадрат з заокругленими кутами
    final bgPaint = Paint()
      ..color = const Color.fromARGB(255, 61, 61, 61)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, squareSize, squareSize),
        const Radius.circular(7), // Зменшуємо радіус заокруглення (було 10)
      ),
      bgPaint,
    );

    // Малюємо рамку
    final borderPaint = Paint()
      ..color = const Color(0xff9ed58b)
      ..strokeWidth = 3 // Зменшуємо товщину (було 4)
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, squareSize, squareSize),
        const Radius.circular(10), // Зменшуємо радіус заокруглення (було 15)
      ),
      borderPaint,
    );
    
    // Додаємо іконку автобуса
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.directions_bus.codePoint),
      style: TextStyle(
        fontSize: 30, // Зменшуємо розмір шрифта (було 40)
        color: const Color.fromARGB(255, 255, 255, 255),
        fontFamily: Icons.directions_bus_rounded.fontFamily,
      ),
    );
    
    textPainter.layout();
    // Позиціонуємо іконку по центру квадрата
    final double iconX = padding + (squareSize - textPainter.width) / 2;
    final double iconY = padding + (squareSize - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(iconX, iconY));
    
    // Конвертуємо canvas в зображення
    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final Uint8List uint8List = byteData.buffer.asUint8List();
      setState(() {
        _busStopIcon = BitmapDescriptor.fromBytes(uint8List);
      });
    }
  }

  // New method for train stop icon
  Future<void> _createTrainStopIcon() async {
    final recorder = ui.PictureRecorder();
    const size = 75.0;
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    
    const padding = 15.0;
    const squareSize = 45.0;
    
    // Background with different color for train stations
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

    // Orange border for train stops
    final borderPaint = Paint()
      ..color = const Color(0xFF9FE3FE)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, squareSize, squareSize),
        const Radius.circular(10),
      ),
      borderPaint,
    );
    
    // Train icon instead of bus
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.train.codePoint),
      style: TextStyle(
        fontSize: 30,
        color: const Color.fromARGB(255, 255, 255, 255),
        fontFamily: Icons.train.fontFamily,
      ),
    );
    
    textPainter.layout();
    final double iconX = padding + (squareSize - textPainter.width) / 2;
    final double iconY = padding + (squareSize - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(iconX, iconY));
    
    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final Uint8List uint8List = byteData.buffer.asUint8List();
      setState(() {
        _trainStopIcon = BitmapDescriptor.fromBytes(uint8List);
      });
    }
  }

  // Метод для створення кастомної іконки коледжу
  Future<void> _createCollegeIcon() async {
    // Створюємо canvas для малювання квадрата з іконкою коледжу
    final recorder = ui.PictureRecorder();
    const size = 150.0;
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    
    // Додаємо відступ для уникнення обрізання
    const padding = 30.0;
    const squareSize = 90.0;
    
    // Малюємо квадрат з заокругленими кутами
    final bgPaint = Paint()
      ..color = const Color.fromARGB(255, 61, 61, 61)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, squareSize, squareSize),
        const Radius.circular(15),
      ),
      bgPaint,
    );

    // Малюємо рамку
    final borderPaint = Paint()
      ..color = const Color(0xFF5389F5) // Синій колір для коледжу
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, squareSize, squareSize),
        const Radius.circular(20),
      ),
      borderPaint,
    );
    
    // Додаємо іконку школи
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.school_rounded.codePoint),
      style: TextStyle(
        fontSize: 60,
        color: const Color.fromARGB(255, 255, 255, 255),
        fontFamily: Icons.school.fontFamily,
      ),
    );
    
    textPainter.layout();
    // Позиціонуємо іконку по центру квадрата
    final double iconX = padding + (squareSize - textPainter.width) / 2;
    final double iconY = padding + (squareSize - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(iconX, iconY));
    
    // Конвертуємо canvas в зображення
    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final Uint8List uint8List = byteData.buffer.asUint8List();
      setState(() {
        _collegeIcon = BitmapDescriptor.fromBytes(uint8List);
      });
    }
  }

  void _initializeMapRenderer() {
    final GoogleMapsFlutterPlatform mapsImplementation = 
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }

  Future<void> _loadStations() async {
    final String response = 
        await rootBundle.loadString('assets/json/stations.json');
    setState(() {
      _stations = json.decode(response);
    });
  }

  // Update the marker creation logic to check for train data
  void _createMarkers() {
    // Clear existing markers before adding new ones
    _markers.clear();
    
    // Markers for stops with custom icon
    _stations.forEach((key, value) {
      final stationData = value as List;
      final lat = stationData[0] / 1000000.0;
      final lng = stationData[1] / 1000000.0;
      final name = stationData[2] as String;
      
      // Check if this station has train data
      bool hasTrainData = false;
      if (stationData.length > 3 && stationData[3] is Map) {
        final additionalData = stationData[3] as Map;
        hasTrainData = additionalData.containsKey('train');
      }

      _markers.add(
        Marker(
          markerId: MarkerId(key),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: name,
            snippet: hasTrainData 
                ? 'Залізнична зупинка (Натисніть, щоб обрати)'
                : '(Натисніть, щоб обрати)',
            onTap: () => Navigator.pop(context, key),
          ),
          icon: hasTrainData 
              ? (_trainStopIcon ?? BitmapDescriptor.defaultMarker) 
              : (_busStopIcon ?? BitmapDescriptor.defaultMarker),
          zIndex: 1.0,
        ),
      );
    });
    
    // College marker with custom icon (add at the end to ensure it's on top)
    _markers.add(
      Marker(
        markerId: const MarkerId('college'),
        position: const LatLng(49.58781059854736, 34.54295461180669),
        infoWindow: const InfoWindow(title: 'ПФКТ НТУ "ХПІ"'),
        icon: _collegeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        zIndex: 2.0,
      ),
    );
    
    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final brightness = MediaQuery.of(context).platformBrightness;
    final mapStyle = await MapStyleHelper.loadMapStyle(themeProvider.mapStyle, brightness);
    
    if (mapStyle != null) {
      await _mapController?.setMapStyle(mapStyle);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Виберіть зупинку'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        zoomControlsEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
          ),
        ),
      ),
    );
  }
}