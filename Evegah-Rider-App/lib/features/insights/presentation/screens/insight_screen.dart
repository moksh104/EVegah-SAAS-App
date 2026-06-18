import 'package:flutter/material.dart';
import '../../data/services/insight_service.dart';

class InsightScreen extends StatefulWidget {
  const InsightScreen({super.key});

  @override
  State<InsightScreen> createState() => _InsightScreenState();
}

class _InsightScreenState extends State<InsightScreen> {
  final InsightService _insightService = InsightService();
  
  bool _isLoading = true;
  String _selectedMonth = "";

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    await _insightService.fetchAllInsights();
    
    if (mounted) {
      setState(() {
        // Default to the current month dynamically
        _selectedMonth = _insightService.currentMonthName;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    // --- DYNAMIC MATH LOGIC ---
    int selectedIndex = _insightService.spendingData.indexWhere((data) => data['month'] == _selectedMonth);
    
    // Safety check just in case the list is empty
    if (selectedIndex == -1) selectedIndex = 0;
    
    Map<String, dynamic> currentMonthData = _insightService.spendingData.isNotEmpty 
        ? _insightService.spendingData[selectedIndex] 
        : {'month': 'Unknown', 'amount': 0.0};
    
    bool showTrend = selectedIndex > 0;
    bool isSpendingDown = true;
    String trendText = "";

    if (showTrend) {
      double currentAmt = currentMonthData['amount'].toDouble();
      double prevAmt = _insightService.spendingData[selectedIndex - 1]['amount'].toDouble();
      
      if (prevAmt == 0) {
        trendText = currentAmt > 0 ? "100% more" : "No change";
        isSpendingDown = false;
      } else if (currentAmt <= prevAmt) {
        isSpendingDown = true;
        trendText = "${(((prevAmt - currentAmt) / prevAmt) * 100).toStringAsFixed(0)}% less";
      } else {
        isSpendingDown = false;
        trendText = "${(((currentAmt - prevAmt) / prevAmt) * 100).toStringAsFixed(0)}% more";
      }
    }
    int treesPlanted = (_insightService.rawCarbonSaved / 18).floor();
    String treeText = "Keep riding to plant a tree 🌱";
    if (treesPlanted == 1) {
      treeText = "Equivalent to planting 1 tree 🌳";
    } else if (treesPlanted > 1) {
      treeText = "Equivalent to planting $treesPlanted trees 🌳";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Smart Insights", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // --- FEATURE 1: CARBON SAVED (Hero Card) ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  const Icon(Icons.eco_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  const Text("Total Carbon Saved", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    _insightService.totalCarbonSaved,
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                   child: Text(treeText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)), // 🚨 DYNAMIC TEXT!
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- FEATURE 2: RIDE STATS ---
            const Text("Ride Statistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard("Total Rides", _insightService.totalRides, Icons.electric_scooter_rounded, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard("Distance", _insightService.totalDistance, Icons.route_rounded, Colors.blue)),
              ],
            ),
            const SizedBox(height: 32),

            // --- FEATURE 3: INTERACTIVE FINANCIAL SUMMARY ---
            const Text("Financial Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.purple, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Spent ($_selectedMonth)", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("₹ ${currentMonthData['amount'].toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
                          ],
                        ),
                      ),
                      if (showTrend)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSpendingDown ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSpendingDown ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, 
                                color: isSpendingDown ? Colors.green : Colors.red, 
                                size: 14
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trendText,
                                style: TextStyle(
                                  color: isSpendingDown ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFF0F0F0), thickness: 1.5),
                  const SizedBox(height: 20),
                  const Text("6-Month Trend", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  
                  // The Interactive Graph
                  SizedBox(
                    height: 140, 
                    child: _insightService.spendingData.isEmpty 
                    ? const Center(child: Text("No data yet.", style: TextStyle(color: Colors.grey)))
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _insightService.spendingData.map((data) {
                        double fillPercentage = data['amount'] / _insightService.maxSpending;
                        bool isSelected = data['month'] == _selectedMonth; 
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMonth = data['month'];
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 32,
                                height: 100 * fillPercentage, 
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.purple : Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['month'], 
                                style: TextStyle(
                                  color: isSelected ? Colors.purple : Colors.grey.shade500, 
                                  fontSize: 12, 
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600
                                )
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          
      ],
      )
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }
}