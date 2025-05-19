//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

class WiFiNetwork {
  final String id;
  final String ssid;
  final String password;

  WiFiNetwork({
    required this.id,
    required this.ssid,
    required this.password,
  });

  factory WiFiNetwork.fromMap(String id, Map<String, dynamic> data) {
    return WiFiNetwork(
      id: id,
      ssid: data['ssid'] ?? '',
      password: data['password'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ssid': ssid,
      'password': password,
    };
  }
}