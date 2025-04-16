import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '/models/weather.dart';
import '/providers/theme_provider.dart';
import '/helpers/map_loading_helper.dart';

class WeatherDetailsScreen extends StatefulWidget {
  final Weather weather;

  const WeatherDetailsScreen({Key? key, required this.weather}) : super(key: key);

  @override
  State<WeatherDetailsScreen> createState() => _WeatherDetailsScreenState();
}

class _WeatherDetailsScreenState extends State<WeatherDetailsScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _weatherMarkerIcon;
  bool _screenOpen = true; // Track if screen is open

  @override
  void initState() {
    super.initState();
    _screenOpen = true; // Ensure map is visible on init
    _initializeMapRenderer();
    _createWeatherMarkerIcon();
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

  void _initializeMapRenderer() {
    final GoogleMapsFlutterPlatform mapsImplementation = 
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
  }

  Future<void> _createWeatherMarkerIcon() async {
    final recorder = ui.PictureRecorder();
    const size = 150.0;
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    
    const padding = 30.0;
    const squareSize = 90.0;
    
    final bgPaint = Paint()
      ..color = const Color.fromARGB(255, 61, 61, 61)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, squareSize, squareSize),
        const Radius.circular(14),
      ),
      bgPaint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF9FE3FE)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(padding, padding, squareSize, squareSize),
        const Radius.circular(20),
      ),
      borderPaint,
    );
    
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );
    
    IconData weatherIcon = Icons.cloud;
    if (widget.weather.weatherMain?.toLowerCase() == 'clear') {
      weatherIcon = Icons.wb_sunny_rounded;
    } else if (widget.weather.weatherMain?.toLowerCase() == 'rain') {
      weatherIcon = Icons.water_drop;
    } else if (widget.weather.weatherMain?.toLowerCase() == 'snow') {
      weatherIcon = Icons.ac_unit;
    }
    
    textPainter.text = TextSpan(
      text: String.fromCharCode(weatherIcon.codePoint),
      style: TextStyle(
        fontSize: 60,
        color: Colors.white,
        fontFamily: weatherIcon.fontFamily,
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
      if (mounted) {
        setState(() {
          _weatherMarkerIcon = BitmapDescriptor.fromBytes(uint8List);
          _createMarkers();
        });
      }
    }
  }

  void _createMarkers() {
    if (widget.weather.lat == null || widget.weather.lon == null) return;
    
    final Set<Marker> markers = {};
    
    markers.add(
      Marker(
        markerId: const MarkerId('weather_location'),
        position: LatLng(widget.weather.lat!, widget.weather.lon!),
        infoWindow: const InfoWindow(title: 'Метеостанція'),
        anchor: const Offset(0.5, 0.5),
        icon: _weatherMarkerIcon ?? BitmapDescriptor.defaultMarker,
      ),
    );
    
    setState(() {
      _markers = markers;
    });
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
    return WillPopScope(
      onWillPop: () async {
        // Hide map before popping
        setState(() {
          _screenOpen = false;
        });
        // Add a small delay to ensure the map is hidden before navigation
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Деталі погоди'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Hide map before popping using back button
              setState(() {
                _screenOpen = false;
              });
              Future.delayed(const Duration(milliseconds: 100), () {
                Navigator.of(context).pop();
              });
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.weather.temperature?.celsius?.round()}°C',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        widget.weather.weatherDescription?.replaceFirst(
                              widget.weather.weatherDescription![0],
                              widget.weather.weatherDescription![0].toUpperCase(),
                            ) ??
                            '',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildWeatherBlock(
                          context,
                          title: 'Вологість',
                          content: '${widget.weather.humidity?.round() ?? 0}%',
                          icon: Icons.water_drop_rounded,
                        ),
                        _buildWeatherBlock(
                          context,
                          title: 'Вітер',
                          content: '${widget.weather.windSpeed?.round() ?? 0} м/с',
                          icon: Icons.navigation_rounded,
                          rotationAngle: widget.weather.windDegree?.toDouble() ?? 0.0,
                        ),
                        _buildWeatherBlock(
                          context,
                          title: 'Відчувається як',
                          content: '${widget.weather.tempFeelsLike?.celsius?.round()}°C',
                          icon: Icons.thermostat_auto_rounded,
                        ),
                        _buildWeatherBlock(
                          context,
                          title: 'Тиск',
                          content: '${widget.weather.pressure?.round() ?? 0} hPa',
                          icon: Icons.arrow_downward_rounded,
                        ),
                        _buildWeatherBlock(
                          context,
                          title: 'Схід сонця',
                          content: _formatTime(widget.weather.sunrise),
                          icon: Icons.wb_sunny_rounded,
                        ),
                        _buildWeatherBlock(
                          context,
                          title: 'Захід сонця',
                          content: _formatTime(widget.weather.sunset),
                          icon: Icons.nights_stay_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSecondary,
                        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
                      ),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: SizedBox(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: _screenOpen 
                            ? GoogleMap(
                                onMapCreated: _onMapCreated,
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(widget.weather.lat ?? 0.0, widget.weather.lon ?? 0.0),
                                  zoom: 12,
                                ),
                                markers: _markers,
                                mapType: MapType.normal,
                                zoomControlsEnabled: false,
                                compassEnabled: false,
                                mapToolbarEnabled: false,
                                myLocationButtonEnabled: false,
                                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<OneSequenceGestureRecognizer>(
                                    () => EagerGestureRecognizer(),
                                  ),
                                },
                              )
                            : Container(
                                height: 200,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                        ),
                      ),
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

  Widget _buildWeatherBlock(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    double rotationAngle = 0.0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSecondary,
        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
        border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: rotationAngle * (3.14159265359 / 180 + 180),
              child: Icon(
                icon,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Невідомо';
    return DateFormat('HH:mm').format(time);
  }
}