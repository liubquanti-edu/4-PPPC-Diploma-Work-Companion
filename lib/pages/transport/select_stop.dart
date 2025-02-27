import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
// Імпортуємо бібліотеку з префіксом для уникнення конфліктів
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart' as cluster_manager;

// Клас для зберігання даних про зупинку
class StopPlace with cluster_manager.ClusterItem {
  final String id;
  final String name;
  final LatLng latLng;
  final bool isCollege;

  StopPlace({
    required this.id,
    required this.name,
    required this.latLng,
    this.isCollege = false,
  });

  @override
  LatLng get location => latLng;
}

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
  BitmapDescriptor? _clusterIcon;
  late cluster_manager.ClusterManager<StopPlace> _clusterManager;
  final List<StopPlace> _items = [];

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(49.589633, 34.551417), // Полтава center
    zoom: 12.0, // Зменшуємо початковий зум для кращої кластеризації
  );

  @override
  void initState() {
    super.initState();
    _clusterManager = _initClusterManager();
    _loadResources();
  }

  cluster_manager.ClusterManager<StopPlace> _initClusterManager() {
    return cluster_manager.ClusterManager<StopPlace>(
      [],
      _updateMarkers,
      markerBuilder: (cluster) async {
        return _buildClusterMarker(cluster as cluster_manager.Cluster<StopPlace>);
      },
      // Оптимізуємо рівні кластеризації для нашої карти
      levels: [1, 3, 5, 7, 9, 11, 13, 15, 17],
      extraPercent: 0.3, // Збільшуємо відсоток для кращої кластеризації
    );
  }

  // Синхронізуємо завантаження ресурсів
  Future<void> _loadResources() async {
    // Завантажуємо іконки паралельно
    await Future.wait([
      _createBusStopIcon(),
      _createCollegeIcon(),
      _createClusterIcon(),
    ]);
    
    // Завантажуємо станції
    await _loadStations();
  }

  // Метод для створення іконки кластера
  Future<void> _createClusterIcon() async {
    final recorder = ui.PictureRecorder();
    const size = 100.0; // Збільшуємо розмір для кращої видимості
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    
    // Малюємо коло з фоном
    final Paint circlePaint = Paint()
      ..color = const Color(0xFF5389F5) // Синій колір
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.5,
      circlePaint,
    );
    
    // Малюємо білу рамку
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.5,
      borderPaint,
    );
    
    // Конвертуємо canvas в зображення
    final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final Uint8List uint8List = byteData.buffer.asUint8List();
      setState(() {
        _clusterIcon = BitmapDescriptor.fromBytes(uint8List);
      });
    }
  }

  // Оновлена функція створення маркера для кластера
  Future<Marker> _buildClusterMarker(cluster_manager.Cluster<StopPlace> cluster) async {
    // Додаємо логування для відстеження
    print('Створюємо маркер для кластера з ${cluster.items.length} елементами');
    
    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      onTap: () {
        // Якщо це одиночний маркер і це зупинка, показуємо інфо-вікно
        if (!cluster.isMultiple) {
          StopPlace item = cluster.items.first;
          // Якщо це не коледж, відкриваємо інфо-вікно для вибору зупинки
          if (!item.isCollege) {
            Navigator.pop(context, item.id);
          }
        } else {
          // Якщо це кластер, наближаємо камеру
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              cluster.location,
              15.0, // Фіксоване значення зуму
            ),
          );
        }
      },
      icon: await _getClusterMarker(cluster),
      infoWindow: cluster.isMultiple
        ? InfoWindow(title: "Група зупинок (${cluster.items.length})") 
        : InfoWindow(
            title: cluster.items.first.name,
            snippet: cluster.items.first.isCollege 
                ? null 
                : '(Натисніть, щоб обрати)',
          ),
      zIndex: cluster.items.any((item) => item.isCollege) ? 2.0 : 1.0,
    );
  }

  // Вибір правильної іконки для маркера або кластера
  Future<BitmapDescriptor> _getClusterMarker(cluster_manager.Cluster<StopPlace> cluster) async {
    if (cluster.isMultiple) {
      return _clusterIcon ?? BitmapDescriptor.defaultMarker;
    }
    
    StopPlace item = cluster.items.first;
    if (item.isCollege) {
      return _collegeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } else {
      return _busStopIcon ?? BitmapDescriptor.defaultMarker;
    }
  }

  void _updateMarkers(Set<Marker> markers) {
    print('Оновлюємо маркери: ${markers.length}');
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
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

  Future<void> _loadStations() async {
    final String response = await rootBundle.loadString('assets/json/stations.json');
    final stationsData = json.decode(response);
    
    setState(() {
      _stations = stationsData;
      _items.clear(); // Очищаємо список перед додаванням
      
      // Додаємо коледж
      _items.add(
        StopPlace(
          id: 'college',
          name: 'ПФКТ НТУ "ХПІ"',
          latLng: const LatLng(49.58781059854736, 34.54295461180669),
          isCollege: true,
        ),
      );
      
      // Додаємо зупинки (обмежуємо кількість для тестування)
      int count = 0;
      stationsData.forEach((key, value) {
        if (count < 200) { // Обмежуємо для тестування
          final stationData = value as List;
          final lat = stationData[0] / 1000000.0;
          final lng = stationData[1] / 1000000.0;
          final name = stationData[2] as String;
          
          _items.add(
            StopPlace(
              id: key,
              name: name,
              latLng: LatLng(lat, lng),
              isCollege: false,
            ),
          );
          count++;
        }
      });
      
      print('Завантажено ${_items.length} елементів');
      // Оновлюємо кластерний менеджер з новими елементами
      _clusterManager.setItems(_items);
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final brightness = MediaQuery.of(context).platformBrightness;
    _setMapStyle(brightness == Brightness.dark);
    _clusterManager.setMapId(controller.mapId);
    
    // Форсуємо оновлення карти
    _clusterManager.updateMap();
    print('Карту створено, оновлюємо кластери');
  }

  void _onCameraMove(CameraPosition position) {
    print('Камера рухається: ${position.target}, зум: ${position.zoom}');
    _clusterManager.onCameraMove(position);
  }

  void _onCameraIdle() {
    print('Камера зупинилась, оновлюємо кластери');
    _clusterManager.updateMap();
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
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: _initialPosition,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
            ),
          ),
          // Додаємо кнопку для тестування кластеризації
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                // Демонструємо віддаленний вид карти для перевірки кластеризації
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    _initialPosition.target,
                    10.0, // Менший зум для групування
                  ),
                );
              },
              child: const Text('Показати всі маркери'),
            ),
          ),
        ],
      ),
    );
  }
}