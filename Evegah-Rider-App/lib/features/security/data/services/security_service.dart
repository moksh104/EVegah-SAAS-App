import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class SecurityService {
  // --- SINGLETON SETUP ---
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() {
    return _instance;
  }
  SecurityService._internal();

  // --- METHODS ---
  
  /// Fetches the real hardware name of the user's phone
  Future<Map<String, dynamic>> getCurrentDevice() async {
    String deviceName = "Unknown Device";
    
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        // Capitalize brand and add model (e.g., "Samsung SM-S918B")
        deviceName = "${androidInfo.brand[0].toUpperCase()}${androidInfo.brand.substring(1)} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }
    } catch (e) {
      deviceName = Platform.isAndroid ? "Android Device" : "iOS Device";
    }

    return {
      "name": deviceName,
      "location": "Active Now", 
      "status": "Current Device",
      "icon": Platform.isIOS ? "tablet" : "phone", 
    };
  }

  Future<bool> logoutCurrentDevice() async {
    // TODO: Later, wire this to your backend's /logOutUser API and clear SharedPreferences
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}