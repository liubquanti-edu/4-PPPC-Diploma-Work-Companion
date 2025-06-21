//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class WiFiService {
  Future<bool> requestPermissions() async {
    List<Permission> permissions = [Permission.location];
    
    if (await _isAndroid13OrAbove()) {
      permissions.add(Permission.nearbyWifiDevices);
    }
    
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> connectToWiFi(String ssid, String password) async {
    try {
      if (!(await requestPermissions())) {
        print("Permission denied");
        return false;
      }
      
      if (!(await WiFiForIoTPlugin.isEnabled())) {
        await WiFiForIoTPlugin.setEnabled(true, shouldOpenSettings: true);
        return false;
      }
      
      print("Attempting to connect to $ssid");
      bool result = false;
      
      if (await _isAndroid13OrAbove()) {
        print("Connecting on Android 13+");
        try {
          result = await WiFiForIoTPlugin.registerWifiNetwork(
            ssid,
            password: password,
            security: NetworkSecurity.WPA,
          );
          print("Register network result: $result");
          
          if (result) {
            await Future.delayed(const Duration(seconds: 1));
            result = await WiFiForIoTPlugin.connect(
              ssid, 
              password: password,
              isHidden: false,
              security: NetworkSecurity.WPA,
            );
            print("Connect after register result: $result");
          } else {
            result = await WiFiForIoTPlugin.connect(
              ssid, 
              password: password,
              withInternet: true,
              isHidden: false,
              security: NetworkSecurity.WPA,
            );
            print("Direct connect result: $result");
          }
          
        } catch (e) {
          print("Error during connect on Android 13+: $e");
          return false;
        }
      } else if (await _isAndroid10OrAbove()) {
        print("Connecting on Android 10-12");
        try {
          result = await WiFiForIoTPlugin.connect(
            ssid, 
            password: password,
            withInternet: true,
            security: NetworkSecurity.WPA,
          );
          
          if (result) {
            await Future.delayed(const Duration(seconds: 1));
            try {
              await WiFiForIoTPlugin.forceWifiUsage(true);
              print("Force WiFi usage successful on Android 10-12");
            } catch (e) {
              print("Warning: forceWifiUsage failed on Android 10-12: $e");
            }
          }
        } catch (e) {
          print("Error during connect on Android 10-12: $e");
          return false;
        }
      } else {
        print("Connecting on Android 9 or below");
        result = await WiFiForIoTPlugin.connect(
          ssid, 
          password: password,
          security: NetworkSecurity.WPA,
        );
      }
      
      return result;
    } catch (e) {
      print('Error connecting to WiFi: $e');
      return false;
    }
  }

  Future<bool> disconnectFromWiFi() async {
    try {
      if (await _isAndroid10OrAbove()) {
        String? currentSSID = await getCurrentWiFiSSID();
        if (currentSSID != null) {
          await WiFiForIoTPlugin.forceWifiUsage(false);
          return await WiFiForIoTPlugin.removeWifiNetwork(currentSSID);
        }
      }
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

  Future<bool> registerPermanentNetwork(String ssid, String password) async {
    try {
      if (!(await requestPermissions())) {
        return false;
      }

      if (await _isAndroid10OrAbove()) {
        return await WiFiForIoTPlugin.registerWifiNetwork(
          ssid,
          password: password,
          security: NetworkSecurity.WPA,
        );
      } else {
        return await WiFiForIoTPlugin.connect(
          ssid,
          password: password,
          security: NetworkSecurity.WPA,
        );
      }
    } catch (e) {
      print('Error registering WiFi network: $e');
      return false;
    }
  }

  Future<bool> _isAndroid10OrAbove() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      print('Android SDK version: ${androidInfo.version.sdkInt}');
      return androidInfo.version.sdkInt >= 29;
    } catch (e) {
      print('Error checking Android version: $e');
      return false;
    }
  }

  Future<bool> _isAndroid13OrAbove() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33;
    } catch (e) {
      print('Error checking Android version: $e');
      return false;
    }
  }
}