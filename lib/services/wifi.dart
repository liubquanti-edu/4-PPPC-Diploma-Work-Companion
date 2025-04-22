import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';

class WiFiService {
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
    ].request();
    return statuses[Permission.location]!.isGranted;
  }

  Future<bool> connectToWiFi(String ssid, String password) async {
    try {
      if (!(await requestPermissions())) {
        return false;
      }
      
      // Check if WiFi is enabled
      if (!(await WiFiForIoTPlugin.isEnabled())) {
        await WiFiForIoTPlugin.setEnabled(true);
      }
      
      // Connect to WiFi
      return await WiFiForIoTPlugin.connect(
        ssid, 
        password: password,
        security: NetworkSecurity.WPA,
      );
    } catch (e) {
      print('Error connecting to WiFi: $e');
      return false;
    }
  }

  Future<bool> disconnectFromWiFi() async {
    try {
      return await WiFiForIoTPlugin.disconnect();
    } catch (e) {
      print('Error disconnecting from WiFi: $e');
      return false;
    }
  }

  Future<String?> getCurrentWiFiSSID() async {
    try {
      if (!(await requestPermissions())) {
        return null;
      }
      return await WiFiForIoTPlugin.getSSID();
    } catch (e) {
      print('Error getting current WiFi SSID: $e');
      return null;
    }
  }
}