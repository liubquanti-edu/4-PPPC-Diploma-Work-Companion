//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

class MapStyle {
  final String name;
  final String assetPath;
  final String darkAssetPath;
  final String id;

  const MapStyle({
    required this.name,
    required this.assetPath,
    this.darkAssetPath = '',
    required this.id,
  });
}

class MapStyles {
  static const List<MapStyle> available = [
    MapStyle(
      name: 'Стандарт',
      assetPath: '',
      darkAssetPath: 'assets/json/map/auberginemap.json',
      id: 'default'
    ),
    MapStyle(
      name: 'Монохром',
      assetPath: 'assets/json/map/silvermap.json',
      id: 'silver'
    ),
    MapStyle(
      name: 'Дедінсайд',
      assetPath: 'assets/json/map/darkmap.json',
      id: 'dark'
    ),
    MapStyle(
      name: 'Ретро',
      assetPath: 'assets/json/map/retromap.json',
      id: 'retro'
    ),
    MapStyle(
      name: 'Нічна',
      assetPath: 'assets/json/map/nightmap.json',
      id: 'night'
    ),
  ];

  static MapStyle getStyleById(String id) {
    return available.firstWhere(
      (style) => style.id == id,
      orElse: () => available.first
    );
  }
}