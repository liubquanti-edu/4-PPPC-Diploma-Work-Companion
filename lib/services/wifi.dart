//-----------------------------------------
//-  Copyright (c) 2025. Liubchenko Oleh  -
//-----------------------------------------

import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class WiFiService {
  Future<bool> requestPermissions() async {
    List<Permission> permissions = [Permission.location];
    
    // Для Android 13+ додаємо дозвіл на NEARBY_WIFI_DEVICES
    if (await _isAndroid13OrAbove()) {
      permissions.add(Permission.nearbyWifiDevices);
    }
    
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    // Перевіряємо, чи всі дозволи надані
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
      
<<<<<<< HEAD
      print("Attempting to connect to $ssid");
      bool result = false;
      
      // Стратегія для різних версій Android
      if (await _isAndroid13OrAbove()) {
        // Для Android 13+
        print("Connecting on Android 13+");
        // Спочатку спробуємо зареєструвати мережу в системі
        try {
          result = await WiFiForIoTPlugin.registerWifiNetwork(
            ssid,
            password: password,
            security: NetworkSecurity.WPA,
          );
          print("Register network result: $result");
          
          // Якщо реєстрація успішна, намагаємось підключитись
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
            // Якщо реєстрація не вдалась, пробуємо звичайне підключення
            result = await WiFiForIoTPlugin.connect(
              ssid, 
              password: password,
              withInternet: true,
              isHidden: false,
              security: NetworkSecurity.WPA,
            );
            print("Direct connect result: $result");
          }
          
          // Не використовуємо forceWifiUsage на Android 13+, оскільки це викликає проблеми
        } catch (e) {
          print("Error during connect on Android 13+: $e");
          return false;
        }
      } else if (await _isAndroid10OrAbove()) {
        // Для Android 10-12
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
              // Продовжуємо роботу, навіть якщо forceWifiUsage не спрацював
            }
          }
        } catch (e) {
          print("Error during connect on Android 10-12: $e");
          return false;
        }
      } else {
        // Для Android 9 і нижче
        print("Connecting on Android 9 or below");
        result = await WiFiForIoTPlugin.connect(
          ssid, 
          password: password,
          security: NetworkSecurity.WPA,
        );
      }
      
      return result;
=======
      return await WiFiForIoTPlugin.connect(
        ssid, 
        password: password,
        security: NetworkSecurity.WPA,
      );
>>>>>>> 8941e543a71c05006d22d29c04b01fcfb8be5274
    } catch (e) {
      print('Error connecting to WiFi: $e');
      return false;
    }
  }

  Future<bool> disconnectFromWiFi() async {
    try {
      // Для Android 10+ потрібно використати removeWifiNetwork для мереж,
      // які були додані з withInternet: true
      if (await _isAndroid10OrAbove()) {
        String? currentSSID = await getCurrentWiFiSSID();
        if (currentSSID != null) {
          await WiFiForIoTPlugin.forceWifiUsage(false); // Вимикаємо маршрутизацію через WiFi
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

  // Функція для реєстрації мережі в системі (постійне збереження)
  Future<bool> registerPermanentNetwork(String ssid, String password) async {
    try {
      if (!(await requestPermissions())) {
        return false;
      }

      // На Android 10+ використовуємо registerWifiNetwork для постійного збереження
      if (await _isAndroid10OrAbove()) {
        return await WiFiForIoTPlugin.registerWifiNetwork(
          ssid,
          password: password,
          security: NetworkSecurity.WPA,
        );
      } else {
        // На старих версіях просто підключаємось, мережа зазвичай зберігається
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

  // Перевірка версії Android
  Future<bool> _isAndroid10OrAbove() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      print('Android SDK version: ${androidInfo.version.sdkInt}');
      return androidInfo.version.sdkInt >= 29; // Android 10 = API 29
    } catch (e) {
      print('Error checking Android version: $e');
      return false;
    }
  }

  // Перевірка версії Android 13+
  Future<bool> _isAndroid13OrAbove() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 = API 33
    } catch (e) {
      print('Error checking Android version: $e');
      return false;
    }
  }
}