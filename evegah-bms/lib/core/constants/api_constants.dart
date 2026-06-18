class ApiConstants {
  static String hostIp = '127.0.0.1'; // default IP address
  
  static String get baseUrl => 'http://$hostIp:5000/api';
  
  static const String batteriesEndpoint = '/batteries';
}
