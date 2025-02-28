class MapStyle {
  final String name;
  final String assetPath;
  final String darkAssetPath; // Add dark theme variant path
  final String id;

  const MapStyle({
    required this.name,
    required this.assetPath,
    this.darkAssetPath = '', // Optional dark theme path
    required this.id,
  });
}

class MapStyles {
  static const List<MapStyle> available = [
    MapStyle(
      name: 'За замовчуванням',
      assetPath: '',
      darkAssetPath: 'assets/json/map/auberginemap.json',
      id: 'default'
    ),
    MapStyle(
      name: 'Білий монохром',
      assetPath: 'assets/json/map/silvermap.json',
      id: 'silver'
    ),
    MapStyle(
      name: 'Чорний монохром',
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