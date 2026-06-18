import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evegah_rider_app/core/constants/app_constants.dart';

class RideService {
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal();

  final String baseUrl = AppConstants.apiBaseUrl;

  // Helper to get real user ID
  Future<int> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // Adjust 'user_id' based on what key you used when the user logged in!
    return prefs.getInt('user_id') ?? 0; 
  }

  // --- 1. FETCH RIDE HISTORY ---
  Future<List<Map<String, dynamic>>> fetchRideHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');

      final url = Uri.parse('$baseUrl/v1/getRideHistory?access_token=$token');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> rawRides = decodedData['data'] ?? []; 

        return rawRides.map((item) => {
          "rideId": item['rideBookingId']?.toString() ?? item['id']?.toString() ?? "UNKNOWN",
          "date": item['rideDate']?.toString() ?? item['createdAt']?.toString() ?? "Unknown Date",
          "vehicleId": item['lockNumber']?.toString() ?? item['vehicleId']?.toString() ?? "Unknown EV",
          "distance": "${item['distance'] ?? 0} km",
          "time": "${item['duration'] ?? 0} mins",
          "cost": "₹ ${item['fare'] ?? item['amount'] ?? 0}"
        }).toList();
      }
      throw Exception("Server Error");
    } catch (e) {
      print("❌ History API Error: $e");
      // Keep your dummy data fallback for testing!
      return [{"rideId": "RIDE-9021", "date": "May 26, 2026", "vehicleId": "EVM1025029", "distance": "2.4 km", "time": "14 mins", "cost": "₹ 45"}];
    }
  }

  // --- 2. POLL LIVE RIDE DETAILS ---
  Future<Map<String, dynamic>> getLiveRideDetails(String vehicleId, int rideBookingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');
      final int userId = await _getUserId(); // 🚨 Real User ID

      // NOTE: If speed/battery always return 0, ask your backend dev if you should use:
      // /v1/iot/device/$vehicleId/snapshot instead!
      final url = Uri.parse('$baseUrl/v1/getLastRideBookingDetails?rideBookingId=$rideBookingId&statusEnumId=1&id=$userId&access_token=$token');
      
      final response = await http.get(url).timeout(const Duration(seconds: 4)); // Prevent hanging

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("Status: ${response.statusCode}");
    } catch (e) {
      print("⚠️ Polling Error (Ignored to prevent crash): $e");
      return {"batteryPercentage": 0, "speed": 0}; 
    }
  }

  // --- 3. END THE RIDE ---
  Future<bool> endRide(int rideBookingId, double endLat, double endLng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');
      final int userId = await _getUserId(); // 🚨 Real User ID

      final url = Uri.parse('$baseUrl/v1/updateDetailsRideEnds?access_token=$token');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rideBookingId": rideBookingId,
          "id": userId, // 🚨 Real User ID
          "rideEndLatitude": endLat,
          "rideEndLongitude": endLng,
          "remarks": "Ride ended by user",
          "endRideUserId": userId // 🚨 Real User ID
        }),
      ).timeout(const Duration(seconds: 10)); // Crucial timeout for End Ride

      return response.statusCode == 200;
    } catch (e) {
      print("❌ End Ride API Error: $e");
      return false;
    }
  }

  // --- 4. SUBMIT FEEDBACK ---
  Future<bool> submitFeedback({
    required String vehicleId,
    required int rideBookingId,
    required int rating,
    required List<String> issues,
    required String comment,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');
      final int userId = await _getUserId(); // 🚨 Real User ID

      final url = Uri.parse('$baseUrl/addRideBookingRating?access_token=$token');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "rideBookingId": rideBookingId,
          "vehicleId": vehicleId, 
          "rating": rating,
          "issues": issues.join(", "), 
          "comment": comment,
          "userId": userId // 🚨 Real User ID
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("❌ Feedback API Error: $e");
      return false;
    }
  }
}