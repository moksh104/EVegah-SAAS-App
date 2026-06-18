import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:evegah_maintenance/core/constants/api_constants.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  
  static Future<void> saveServerIp(String ip) async {
    await _storage.write(key: 'server_ip', value: ip);
    ApiConstants.hostIp = ip;
  }
  
  static Future<String> loadServerIp() async {
    final ip = await _storage.read(key: 'server_ip');
    if (ip != null && ip.isNotEmpty) {
      ApiConstants.hostIp = ip;
      return ip;
    }
    return ApiConstants.hostIp;
  }
}
