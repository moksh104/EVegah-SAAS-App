import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:evegah_rider_app/core/constants/app_constants.dart';

class AuthService {
  static String get baseUrl => '${AppConstants.apiBaseUrl}/';

  // GENERATED OTP
  String generatedOtp = "";

  // ACCESS TOKEN
  String accessToken = "";

  // CHECK MOBILE NUMBER
 // CHECK MOBILE NUMBER
  Future<bool> checkMobileNumber(String mobileNumber) async {
    final url = Uri.parse("${baseUrl}CheckCustomerMobileNumber");

    print("🚀 CALLING CHECK MOBILE API...");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mobileNumber": mobileNumber}),
    );

    print("🚀 CHECK MOBILE STATUS: ${response.statusCode}");
    print("🚀 CHECK MOBILE RESPONSE: ${response.body}"); // <-- This will show us the truth!

    if (response.statusCode == 200) {
      final decodedResponse = jsonDecode(response.body);

      String token = "";

      // We check if "data" exists, and if it's a List, we grab the first item [0]
      if (decodedResponse["data"] != null && decodedResponse["data"] is List && decodedResponse["data"].isNotEmpty) {
         token = decodedResponse["data"][0]["access_token"] ?? "";
      } 
      // Fallback just in case the server changes format later
      else if (decodedResponse["access_token"] != null) {
         token = decodedResponse["access_token"];
      }

      accessToken = token;
      print("🚀 EXTRACTED TOKEN: '$accessToken'");

      return true;
    }

    return false;
  }

  // GENERATE OTP
  String generateOtp() {
    final random = Random();

    generatedOtp = (1000 + random.nextInt(9000)).toString();

    return generatedOtp;
  }

  // SEND OTP USING 2FACTOR
  Future<bool> sendOtp(String mobileNumber) async {
    generateOtp();

    final url = Uri.parse(
      "https://2factor.in/API/V1/7d84d134-26fe-11ed-9c12-0200cd936042/SMS/$mobileNumber/$generatedOtp/eVegah+SMS",
    );

    final response = await http.get(url);

    return response.statusCode == 200;
  }

  // VERIFY OTP
  bool verifyOtp(String otp) {
    return otp == generatedOtp;
  }
}
