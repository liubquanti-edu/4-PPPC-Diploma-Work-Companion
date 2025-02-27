import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class StopSelectorScreen extends StatefulWidget {
  const StopSelectorScreen({Key? key}) : super(key: key);

  @override
  _StopSelectorScreenState createState() => _StopSelectorScreenState();
}

class _StopSelectorScreenState extends State<StopSelectorScreen> {
  Map<String, dynamic> _stations = {};
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    final String response = await rootBundle.loadString('assets/json/stations.json');
    setState(() {
      _stations = json.decode(response);
    });
  }

  Widget _darkModeTileBuilder(
      BuildContext context,
      Widget tileWidget,
      TileImage tile,
      ) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -0.2126, -0.7152, -0.0722, 0, 255, // Red channel
        -0.2126, -0.7152, -0.0722, 0, 255, // Green channel
        -0.2126, -0.7152, -0.0722, 0, 255, // Blue channel
        0,       0,       0,       1, 0,   // Alpha channel
      ]),
      child: tileWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Виберіть зупинку'),
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: LatLng(49.589633, 34.551417),
          zoom: 13,
          minZoom: 4,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            tileBuilder: Theme.of(context).brightness == Brightness.dark ? _darkModeTileBuilder : null,
            userAgentPackageName: 'com.example.app',
          ),
          // Додаємо маркер коледжу
          MarkerLayer(
            markers: [
                Marker(
                point: LatLng(49.58781059854736, 34.54295461180669),
                width: 40,
                height: 40,
                rotate: true,
                builder: (context) => Container(
                  decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                  Icons.school_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                  ),
                ),
              ),
            ],
          ),
          // Кластеризовані маркери зупинок
            MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 70,
              size: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              markers: _stations.entries.map((station) {
                final stationData = station.value as List;
                final lat = stationData[0] / 1000000.0;
                final lng = stationData[1] / 1000000.0;
                final name = stationData[2] as String;
                
                return Marker(
                  rotate: true,
                  point: LatLng(lat, lng),
                  width: 30,
                  height: 30,
                  builder: (context) => Tooltip(
                    message: name,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context, station.key);
                      },
                        child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Icon(
                          Icons.signpost_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Center(
                    child: Text(
                      markers.length.toString(),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}