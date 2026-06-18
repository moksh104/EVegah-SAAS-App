import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/constants/app_constants.dart';

class DashboardService {
  final SessionService _sessionService = SessionService();

  // --- 1. FETCH LIVE ZONES (Extracted from Map Screen) ---
  Future<List<Map<String, dynamic>>> fetchLiveZonesFromApi() async {
    try {
      String? savedToken = await _sessionService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        debugPrint("ERROR: No token found. User might not be logged in.");
        return [];
      }

      final queryParams = {
        'zoneId': '0',
        'mapCityId': '0',
        'mapCountryName': 'India',
        'mapStateName': 'Gujarat',
        'mapCityName': 'Vadodara',
        'dataFor': 'ForMapSearch',
        'access_token': savedToken,
      };

      final uri = Uri.parse(AppConstants.getLiveZones).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        List<dynamic> zonesList = decodedData['data'] ?? decodedData;
        List<Map<String, dynamic>> mappedZones = [];

        for (var item in zonesList) {
          double lat = double.tryParse(item['latitude']?.toString() ?? '0') ?? 0.0;
          double lng = double.tryParse(item['longitude']?.toString() ?? '0') ?? 0.0;
          
          if (lat != 0.0 && lng != 0.0) {
            mappedZones.add({
              'id': item['zoneId']?.toString() ?? DateTime.now().toString(),
              'center': LatLng(lat, lng),
              'zoneName': item['zoneName'],
              'zone_address': item['zone_address'],
              'bikeCount': item['bikeCount'],
             'vehicles': item['vehicles'] ?? item['avaialableBikeListData'] ?? [],
            });
          }
        }
        return mappedZones;
      } else {
        debugPrint("API Failed: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Network Error: $e");
      return [];
    }
  }

  // --- 2. FETCH VEHICLE DETAILS (Extracted from Vehicle Details Screen) ---
  Future<Map<String, dynamic>?> fetchLiveVehicleDetails(String vehicleId) async {
    try {
      String? savedToken = await _sessionService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        throw Exception("Authentication error. Please log in again.");
      }

      // CHAIN LINK 1: Get the Secret JSON Object
      final qrDecryptedUri = Uri.parse("${AppConstants.apiBaseUrl}/qrDecrypted?access_token=$savedToken");
      final qrResponse = await http.post(
        qrDecryptedUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "qrString": null,
          "userId": 0, 
          "lockNumber": vehicleId
        }),
      );

      if (qrResponse.statusCode != 200) {
        throw Exception("Failed to find vehicle on server.");
      }

      final qrDecoded = json.decode(qrResponse.body);
      if (qrDecoded['data'] == null || qrDecoded['data'].isEmpty) {
        throw Exception("Vehicle not found in database.");
      }

      final secretJsonObject = qrDecoded['data'][0];
      final String jsonStringifiedDetails = jsonEncode(secretJsonObject);

      // CHAIN LINK 2: Get the Full Vehicle Model
      final getModelParams = {
        'VehicleId': jsonStringifiedDetails,
        'statusEnumId': '1',
        'access_token': savedToken,
      };

      final getModelUri = Uri.parse(AppConstants.getVehicleModel).replace(queryParameters: getModelParams);
      final modelResponse = await http.get(getModelUri);

      if (modelResponse.statusCode != 200) {
        throw Exception("Failed to load vehicle details.");
      }

      final modelDecoded = json.decode(modelResponse.body);
      if (modelDecoded['data'] != null && modelDecoded['data'].isNotEmpty) {
        return modelDecoded['data'][0]; // Return the real data!
      } else {
        throw Exception("No model data returned.");
      }
    } catch (e) {
      debugPrint("API Chain Error: $e");
      throw Exception("Could not load live vehicle data.");
    }
  }
  // --- 3. FETCH WALLET BALANCE ---
  Future<double> fetchWalletBalance() async {
    try {
      String? savedToken = await _sessionService.getToken();
      if (savedToken == null || savedToken.isEmpty) return 0.0;

      // Hitting the getUser API to find the wallet balance
      final uri = Uri.parse("${AppConstants.apiBaseUrl}/getUser?access_token=$savedToken");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // Safety check depending on how the backend formats the user object
        if (decoded['data'] != null && decoded['data'].isNotEmpty) {
          if (decoded['data'] is List) {
             return double.tryParse(decoded['data'][0]['walletAmount']?.toString() ?? '0') ?? 0.0;
          } else {
             return double.tryParse(decoded['data']['walletAmount']?.toString() ?? '0') ?? 0.0;
          }
        }
      }
      return 0.0;
    } catch (e) {
      debugPrint("Wallet API Error: $e");
      return 0.0;
    }
  }
}