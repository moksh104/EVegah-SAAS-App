import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 🚨 Added to fetch the saved token
import 'package:evegah_rider_app/core/constants/app_constants.dart';

class SupportService {
  // --- SINGLETON SETUP ---
  static final SupportService _instance = SupportService._internal();
  factory SupportService() {
    return _instance;
  }
  SupportService._internal();

  final String baseUrl = AppConstants.apiBaseUrl;

  // --- STATIC CONTACT DATA ---
  final String supportEmail = "support@evegah.com";
  final String supportPhone = "+91 98765 43210";
  final String operatingHours = "Mon - Sun, 8:00 AM to 10:00 PM";

  // --- LIVE API METHOD ---
  Future<List<Map<String, String>>> fetchFaqs() async {
    try {
      // 1. Fetch the saved token
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token'); // 🚨 Ensure this matches the key you used to save it!

      // 2. Attach the token to the URL as a query parameter
      // Your backend expects: /getAllSectionFAQDetail?access_token=eyJhb...
      final url = Uri.parse('$baseUrl/getAllSectionFAQDetail?access_token=$token');
      print("🌐 Calling API: $url"); 
      
      final response = await http.get(url);

      print("📡 Server Status Code: ${response.statusCode}");

      // 3. Check if the server responded successfully
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        
        List<dynamic> rawFaqs = decodedData['data'] ?? decodedData; 

        return rawFaqs.map((item) => {
          "question": item['question']?.toString() ?? "Unknown Question",
          "answer": item['answer']?.toString() ?? "No answer provided.",
        }).toList();
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ API Error: $e. Falling back to local data.");
      return [
        {
          "question": "How do I unlock an EVegah scooter?",
          "answer": "Simply open the app, tap 'Scan to Ride' on the home screen, and point your camera at the QR code."
        },
        {
          "question": "What happens if my battery dies mid-ride?",
          "answer": "If your scooter drops below 10% battery, it will gradually slow down. Please park it safely."
        },
      ];
    }
  }
}