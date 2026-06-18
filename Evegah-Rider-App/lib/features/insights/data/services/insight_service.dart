import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:evegah_rider_app/core/constants/app_constants.dart';

class InsightService {
  final String baseUrl = AppConstants.apiBaseUrl;

  // Public variables that the UI will read
  String totalCarbonSaved = "0.0 kg";
  String totalRides = "0";
  double rawCarbonSaved = 0.0;
  String totalDistance = "0.0 km";
  List<Map<String, dynamic>> spendingData = [];
  double maxSpending = 1.0; 
  String currentMonthName = "";

  // The master function that fetches and calculates EVERYTHING
  Future<void> fetchAllInsights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');
      if (token == null || token.isEmpty) return;

      // 1. Fetch both endpoints simultaneously for max speed
      final rideFuture = http.get(Uri.parse('$baseUrl/v1/getRideHistory?access_token=$token'));
      final txFuture = http.get(Uri.parse('$baseUrl/getLatestTransactionList?access_token=$token'));

      final responses = await Future.wait([rideFuture, txFuture]);
      final rideRes = responses[0];
      final txRes = responses[1];

      // 2. Parse Rides & Distance & Carbon
      int ridesCount = 0;
      double distanceSum = 0.0;
      
      if (rideRes.statusCode == 200) {
        final decoded = jsonDecode(rideRes.body);
        List<dynamic> rides = _extractData(decoded);
        ridesCount = rides.length;
        
        for (var r in rides) {
          // Adjust 'distance' if your backend uses a different key (e.g., 'distanceKm')
          distanceSum += double.tryParse(r['distance']?.toString() ?? '0') ?? 0.0;
        }
      }

      totalRides = ridesCount.toString();
      totalDistance = "${distanceSum.toStringAsFixed(1)} km";
      // The Magic Math: 0.12kg of CO2 saved per km
      
      rawCarbonSaved = distanceSum * 0.12; 
      totalCarbonSaved = "${rawCarbonSaved.toStringAsFixed(1)} kg";

      // 3. Parse Transactions for the 6-Month Chart
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      Map<String, double> monthlyTotals = {};
      DateTime now = DateTime.now();
      List<String> monthLabels = [];

      // Build the last 6 months dynamically (e.g., [Jun, Jul, Aug, Sep, Oct, Nov])
      for (int i = 5; i >= 0; i--) {
        int targetMonth = now.month - i;
       
        if (targetMonth <= 0) {
          targetMonth += 12;
         
        }
        String mName = monthNames[targetMonth - 1];
        monthLabels.add(mName);
        monthlyTotals[mName] = 0.0;
      }
      
      currentMonthName = monthLabels.last; // Default to the current month

      if (txRes.statusCode == 200) {
        final decoded = jsonDecode(txRes.body);
        List<dynamic> txs = _extractData(decoded);

        for (var tx in txs) {
          String typeEnum = tx['transactionTypeEnumId']?.toString() ?? '0';
          bool isCredit = typeEnum == '1' || (tx['transactionType']?.toString().toLowerCase().contains('recharge') ?? false);
          
          // Only count Debits (Rides) towards spending!
          if (!isCredit) {
            String dateStr = tx['createdDate']?.toString() ?? '';
            DateTime? txDate = DateTime.tryParse(dateStr);
            if (txDate != null) {
              String mName = monthNames[txDate.month - 1];
              if (monthlyTotals.containsKey(mName)) {
                monthlyTotals[mName] = monthlyTotals[mName]! + (double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0);
              }
            }
          }
        }
      }

      // Convert Map to the List format the UI expects
      spendingData = monthLabels.map((m) => {'month': m, 'amount': monthlyTotals[m]!}).toList();
      
      // Calculate max spending to scale the bar chart properly
      double maxVal = 0;
      for (var item in spendingData) {
        if (item['amount'] > maxVal) maxVal = item['amount'];
      }
      maxSpending = maxVal > 0 ? maxVal : 1.0;

    } catch (e) {
      debugPrint("❌ Insights Error: $e");
    }
  }

  // Helper to bulletproof JSON parsing
  List<dynamic> _extractData(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) return decoded['data'];
    return [];
  }
}