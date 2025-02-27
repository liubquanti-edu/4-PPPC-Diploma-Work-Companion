import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

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

  // Синхронізуємо завантаження ресурсів
  Future<void> _loadResources() async {
    // Завантажуємо обидві іконки паралельно
    await Future.wait([
      _createBusStopIcon(),
      _createCollegeIcon(),
    ]);
    
    // Завантажуємо станції тільки після готовності іконок
    await _loadStations();
    
    // Створюємо маркери
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
      ..color = const Color(0xFFFFFFFF)
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

  void _createMarkers() {
    // Очищуємо існуючі маркери перед додаванням нових
    _markers.clear();
    
    // Markers зупинок з кастомною іконкою
    _stations.forEach((key, value) {
      final stationData = value as List;
      final lat = stationData[0] / 1000000.0;
      final lng = stationData[1] / 1000000.0;
      final name = stationData[2] as String;

      _markers.add(
        Marker(
          markerId: MarkerId(key),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: name,
            snippet: '(Натисніть, щоб обрати)',
            onTap: () => Navigator.pop(context, key),
          ),
          icon: _busStopIcon ?? BitmapDescriptor.defaultMarker,
          zIndex: 1.0, // Звичайний z-index для зупинок
        ),
      );
    });
    
    // Marker коледжу з кастомною іконкою (додаємо в кінці, щоб гарантовано був зверху)
    _markers.add(
      Marker(
        markerId: const MarkerId('college'),
        position: const LatLng(49.58781059854736, 34.54295461180669),
        infoWindow: const InfoWindow(title: 'ПФКТ НТУ "ХПІ"'),
        icon: _collegeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        zIndex: 2.0, // Високий z-index, щоб завжди бути зверху
      ),
    );
    
    // Оновлюємо стан, щоб відобразити маркери
    setState(() {});
  }

  Future<void> _setMapStyle(bool isDark) async {
    if (_mapController == null) return;

    // Базовий стиль для приховування зупинок транспорту
    final String baseStyle = '''
    [
      {
        "featureType": "transit.station.bus",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
    ''';

    if (isDark) {
      // Завантажуємо темний стиль і комбінуємо з базовим
      final String darkStyle = 
          await rootBundle.loadString('assets/json/darkmap.json');
      
      // Конвертуємо у JSON, щоб об'єднати стилі
      List<dynamic> darkStyleJson = json.decode(darkStyle);
      List<dynamic> baseStyleJson = json.decode(baseStyle);
      
      // Об'єднуємо стилі
      darkStyleJson.addAll(baseStyleJson);
      
      // Застосовуємо комбінований стиль
      await _mapController!.setMapStyle(json.encode(darkStyleJson));
    } else {
      // Для світлої теми застосовуємо тільки базовий стиль
      await _mapController!.setMapStyle(baseStyle);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final brightness = MediaQuery.of(context).platformBrightness;
    _setMapStyle(brightness == Brightness.dark);
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
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _initialPosition,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        zoomControlsEnabled: true,
        compassEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }
}