import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/map_config.dart';

class MapStyleHelper {
  static const List<Map<String, dynamic>> _hideTransitStations = [
    {
      "featureType": "transit.station",
      "stylers": [{ "visibility": "off" }]
    },
    {
      "featureType": "transit.station.bus",
      "stylers": [{ "visibility": "off" }]
    },
    {
      "featureType": "transit.station.rail", 
      "stylers": [{ "visibility": "off" }]
    }
  ];

  static Future<String?> loadMapStyle(String styleId, Brightness brightness) async {
    final style = MapStyles.available.firstWhere(
      (style) => style.id == styleId,
      orElse: () => MapStyles.available.first
    );

    String? mapStyle;

    if (style.id == 'default') {
      final isDark = brightness == Brightness.dark;
      if (isDark && style.darkAssetPath.isNotEmpty) {
        mapStyle = await rootBundle.loadString(style.darkAssetPath);
      }
    } else if (style.assetPath.isNotEmpty) {
      try {
        mapStyle = await rootBundle.loadString(style.assetPath);
      } catch (e) {
        print('Error loading map style: $e');
        return null;
      }
    }

    if (mapStyle != null) {
      final List<dynamic> baseStyle = json.decode(mapStyle);
      final List<dynamic> combinedStyle = [
        ...baseStyle,
        ..._hideTransitStations
      ];
      return json.encode(combinedStyle);
    } else if (style.id == 'default') {
      return json.encode(_hideTransitStations);
    }

    return null;
  }
}