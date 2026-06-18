class AppConstants {
  // Network Configurations
  static const String apiBaseUrl = 'https://admin.evegah.com/api'; // Change as per environment
  static const String websocketUrl = 'wss://api.evegah.com/ws';
  // Vehicle & Map API Endpoints
  static String get getLiveZones => '$apiBaseUrl/v1/getzoneDetailWithBikeCountList';
  static String get decryptQr => '$apiBaseUrl/qrDecrypted';
  static String get getVehicleModel => '$apiBaseUrl/v1/getVehicleModel';

  // Secure Storage & Shared Preference Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserProfile = 'user_profile';

  // Assets Paths
  static const String logoImg = 'assets/Evegah_login_page_logo.png';
  static const String loginBgImg = 'assets/login_page_b.jpeg';
}
