import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 🚨 ADDED for Navigation
import '../../../unlock/presentation/screens/scan_qr_screen.dart'; // 🚨 ADDED for Scanner
import '../../data/services/dashboard_service.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/services/session_service.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String vehicleId; 

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final DashboardService _dashboardService = DashboardService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _vehicleData;
  double _walletBalance = 0.0; // 🚨 ADDED state for Wallet
  int _sliderIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchLiveVehicleDetails();
  }

  Future<void> _fetchLiveVehicleDetails() async {
    try {
      // 🚨 ASK THE CHEF for both the Vehicle AND the Wallet Balance!
      final data = await _dashboardService.fetchLiveVehicleDetails(widget.vehicleId);
      final balance = await _dashboardService.fetchWalletBalance();
      
      if (mounted) {
        setState(() {
          _vehicleData = data;
          _walletBalance = balance; // Save the wallet balance
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching vehicle details: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  // 🚨 ADDED: Navigation Engine specifically for this bike
  Future<void> _launchDirections(double lat, double lng) async {
    // This creates a direct route to the bike's exact GPS coordinates
    final String googleMapsUrl = "http://maps.google.com/maps?daddr=$lat,$lng";
    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not open maps application.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF1E1452))),
      );
    }

    if (_errorMessage != null || _vehicleData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        ),
        body: Center(child: Text(_errorMessage ?? "Something went wrong.", style: const TextStyle(color: Colors.red, fontSize: 16))),
      );
    }

    final String model = _vehicleData!['modelName']?.toString() ?? "Unknown";
    final int range = int.tryParse(_vehicleData!['maxRangeOn100PercentageBatteryKM']?.toString() ?? '0') ?? 0;
    
    final String modelLower = model.toLowerCase();
    final List<String> vehicleImages = modelLower.contains("mink")
        ? ["assets/mink.png", "assets/v1.webp", "assets/v2.webp"]
        : modelLower.contains("fly")
            ? ["assets/v2.webp", "assets/v1.webp", "assets/mink.png"]
            : ["assets/v1.webp", "assets/mink.png", "assets/v2.webp"];
    
    int battery = 0;
    double bikeLat = 0.0;
    double bikeLng = 0.0;

    // Pulling the live telemetry data (Battery + GPS)
    if (_vehicleData!['lockDetails'] != null && _vehicleData!['lockDetails'].isNotEmpty) {
       battery = int.tryParse(_vehicleData!['lockDetails'][0]['battery']?.toString() ?? '0') ?? 0;
       
       // 🚨 Extracting the bike's exact coordinates for the Navigate button
       bikeLat = double.tryParse(_vehicleData!['lockDetails'][0]['latitude']?.toString() ?? '0') ?? 0.0;
       bikeLng = double.tryParse(_vehicleData!['lockDetails'][0]['longitude']?.toString() ?? '0') ?? 0.0;
    }

    // Fallback if the GPS is stored in the main vehicle object instead of the lock details
    if (bikeLat == 0.0) {
       bikeLat = double.tryParse(_vehicleData!['latitude']?.toString() ?? '0') ?? 0.0;
       bikeLng = double.tryParse(_vehicleData!['longitude']?.toString() ?? '0') ?? 0.0;
    }

    double fare = 0.0;
    int minHire = 0;
    if (_vehicleData!['farePlanData'] != null && _vehicleData!['farePlanData'].isNotEmpty) {
       fare = double.tryParse(_vehicleData!['farePlanData'][0]['todaysRate']?.toString() ?? '0') ?? 0.0;
       minHire = int.tryParse(_vehicleData!['farePlanData'][0]['minimumHireMinuts']?.toString() ?? '0') ?? 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context), 
        ),
        title: const Text("Vehicle Details", style: TextStyle(color: Color(0xFF1E1452), fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(height: 8, width: 8, decoration: BoxDecoration(color: Colors.green.shade400, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text("Live", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- VEHICLE IMAGE SLIDER ---
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4313B8).withValues(alpha: 0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              PageView.builder(
                                onPageChanged: (index) {
                                  setState(() {
                                    _sliderIndex = index;
                                  });
                                },
                                itemCount: vehicleImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Image.asset(
                                      vehicleImages[index],
                                      fit: BoxFit.contain,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Dots Indicator
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              vehicleImages.length,
                              (idx) => Container(
                                width: _sliderIndex == idx ? 16 : 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: _sliderIndex == idx ? const Color(0xFF4313B8) : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.fingerprint, color: Colors.purple.shade300, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("VEHICLE IDENTITY", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(widget.vehicleId, style: const TextStyle(color: Color(0xFF1E1452), fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2, 
                    children: [
                      _buildInfoCard(Icons.pedal_bike, Colors.blue, "MODEL", model),
                      _buildInfoCard(Icons.battery_charging_full, Colors.green, "ENERGY", "$battery%"),
                      _buildInfoCard(Icons.map_outlined, Colors.orange, "MAX RANGE", "$range km"),
                      _buildInfoCard(Icons.bolt, Colors.red, "FARE/MIN", "₹$fare"),
                      _buildInfoCard(Icons.hourglass_bottom, Colors.purple, "MIN HIRE", "$minHire Min"),
                      // 🚨 DYNAMIC WALLET DISPLAY
                      _buildInfoCard(Icons.account_balance_wallet, Colors.pink, "WALLET", "₹${_walletBalance.toStringAsFixed(2)}"), 
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    // 🚨 WIRED UP: NAVIGATE BUTTON
                    onPressed: () {
                      if (bikeLat != 0.0 && bikeLng != 0.0) {
                        _launchDirections(bikeLat, bikeLng);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Exact vehicle location is currently unavailable.")),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: Colors.blue.shade600, width: 2), 
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_walk, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 6),
                        Text("Navigate", style: TextStyle(color: Colors.blue.shade700, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1, 
                  child: ElevatedButton(
                    // 🚨 WIRED UP: START RIDE BUTTON
                    onPressed: () async { 
                      final loggedIn = await SessionService().isLoggedIn();
                      if (!context.mounted) return;
                      if (loggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScanQrScreen()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: const Color(0xFF1E1452),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Start Ride", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.qr_code_scanner, color: Colors.white, size: 20), 
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, MaterialColor color, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color.shade400, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }
}