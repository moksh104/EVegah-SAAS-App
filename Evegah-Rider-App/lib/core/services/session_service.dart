import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // SAVE TOKEN
  Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString("access_token", token);

    await prefs.setInt("login_time", DateTime.now().millisecondsSinceEpoch);
  }

  // GET TOKEN
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString("access_token");
  }

  // CHECK SESSION
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString("access_token");

    int? loginTime = prefs.getInt("login_time");

    if (token == null || loginTime == null) {
      return false;
    }

    DateTime loginDate = DateTime.fromMillisecondsSinceEpoch(loginTime);

    Duration difference = DateTime.now().difference(loginDate);

    // 7 DAYS SESSION
    return difference.inDays < 7;
  }

  // LOGOUT
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}
