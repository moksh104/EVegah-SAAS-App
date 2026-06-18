import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evegah_rider_app/core/constants/app_constants.dart';

class UnlockService {
  final String baseUrl = AppConstants.apiBaseUrl;

  // 🚨 REPLACES HARDCODED MAP: Fetches live vehicle location from backend
  Future<Map<String, double>?> fetchVehicleLocation(String vehicleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');
      
      // We assume an endpoint exists to get specific vehicle details by ID
      final url = Uri.parse('$baseUrl/getVehicleDetails?vehicleId=$vehicleId&access_token=$token');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Ensure you adjust the keys (e.g., 'latitude', 'longitude') 
        // to match your backend's exact response JSON
        final data = decoded['data'] is List ? decoded['data'][0] : decoded['data'];
        
        return {
          "lat": double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0,
          "lng": double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0,
        };
      }
      return null;
    } catch (e) {
      print("❌ Error fetching vehicle location: $e");
      return null;
    }
  }

  // 🚨 UPGRADED: Now returns the rideBookingId (int) instead of a bool
  Future<int?> unlockVehicle(String vehicleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');
      // final int? userId = prefs.getInt('user_id'); // Add this if your backend needs the userId here too!
      
      final url = Uri.parse('$baseUrl/unlockVehicle?access_token=$token');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"vehicleId": vehicleId}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // 🚨 IMPORTANT: Replace 'rideBookingId' with whatever exact key your backend developer uses in the JSON response!
        // Example: { "status": "success", "data": { "rideBookingId": 9021 } }
        if (decoded['data'] != null && decoded['data']['rideBookingId'] != null) {
          return int.tryParse(decoded['data']['rideBookingId'].toString());
        }
        
        // If the backend doesn't send an ID yet, we return a fallback so the app doesn't crash during testing.
        print("⚠️ Warning: Backend didn't return a rideBookingId. Using fallback 999.");
        return 999; 
      }
      return null; // Null means the unlock failed
    } catch (e) {
      print("❌ Unlock API Error: $e");
      return null;
    }
  }
}