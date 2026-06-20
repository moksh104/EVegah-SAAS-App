import 'package:flutter/material.dart';
import '../../../unlock/presentation/screens/scan_qr_screen.dart';
import 'vehicle_list_screen.dart';
import 'vehicle_details_screen.dart';
import '../../../offers/presentation/screens/offer_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/services/session_service.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';
import '../widgets/bluetooth_scan_dialog.dart';
import '../../../../core/services/ble_battery_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _carouselIndex = 0;
  bool hasActiveRide = false; // Set to true to view the live active ride card mockup!

  final List<Map<String, dynamic>> _carouselSlides = [
    {
      "title": "Ride Electric.\nLive Better.",
      "subtitle": "Zero emissions. Maximum freedom.",
      "button": "Book EV in minutes",
      "image": "assets/mink.png",
      "gradientStart": 0xFFF5F3FF,
      "gradientEnd": 0xFFEEF2FF,
    },
    {
      "title": "Daman & Aatapi\nSpecial Packages",
      "subtitle": "Rent for hours or days at discounted rates.",
      "button": "View Packages",
      "image": "assets/v1.webp",
      "gradientStart": 0xFFEBF3FF,
      "gradientEnd": 0xFFD6E4FF,
    },
    {
      "title": "Eco Friendly\nCommutes.",
      "subtitle": "Save the environment, save money.",
      "button": "Explore Models",
      "image": "assets/v2.webp",
      "gradientStart": 0xFFFDF2F8,
      "gradientEnd": 0xFFFCE7F3,
    }
  ];

  final List<Map<String, dynamic>> _evModels = [
    {
      "name": "Mink",
      "price": "₹29/hr",
      "image": "assets/mink.png",
      "badge": "Best for Daily Commute",
      "badgeBg": 0xFFF5F3FF,
      "badgeText": 0xFF4313B8,
      "id": "MINK001"
    },
    {
      "name": "City",
      "price": "₹39/hr",
      "image": "assets/black_scooter_city.png", // Make sure you have this asset or change it
      "badge": "Most Popular",
      "badgeBg": 0xFFECFDF5,
      "badgeText": 0xFF059669,
      "id": "CITY002"
    },
    {
      "name": "Fly",
      "price": "₹49/hr",
      "image": "assets/kick_scooter_fly.png", // Make sure you have this asset or change it
      "badge": "Best for Long Rides",
      "badgeBg": 0xFFEFF6FF,
      "badgeText": 0xFF2563EB,
      "id": "FLY003"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFE),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. TOP HEADER (Location & Bell) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Location selector
                    GestureDetector(
                      onTap: () {
                        // Location selection dialog
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.location_on_rounded, color: Color(0xFF4313B8), size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Koramangala, Bengaluru",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 16),
                        ],
                      ),
                    ),
                    
                    // 🚨 WIRED UP: Notification bell icon with red dot badge
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationScreen()),
                        );
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 20),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // --- 2. HERO CAROUSEL / ACTIVE RIDE ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: hasActiveRide ? _buildActiveRideCard() : _buildHeroCarousel(),
              ),

              const SizedBox(height: 16),

              // --- 3. STATUS CARDS (Live Battery & Wallet Balance) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Battery status card
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final loggedIn = await SessionService().isLoggedIn();
                          if (!mounted) return;
                          if (!loggedIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          } else {
                            showDialog(
                              context: context,
                              builder: (context) => const BluetoothScanDialog(),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ValueListenableBuilder<BleBatteryState>(
                            valueListenable: BleBatteryService.instance.connectionState,
                            builder: (context, connState, _) {
                              final bool isConnected = connState == BleBatteryState.connected;
                              final IconData icon = isConnected
                                  ? Icons.bluetooth_connected_rounded
                                  : (connState == BleBatteryState.scanning || connState == BleBatteryState.connecting
                                      ? Icons.bluetooth_searching_rounded
                                      : Icons.bluetooth_disabled_rounded);
                              final Color iconColor = isConnected
                                  ? Colors.blue
                                  : (connState == BleBatteryState.scanning || connState == BleBatteryState.connecting
                                      ? Colors.orange
                                      : Colors.grey);
                              
                              final String statusText = isConnected
                                  ? "Connected"
                                  : (connState == BleBatteryState.scanning
                                      ? "Scanning..."
                                      : (connState == BleBatteryState.connecting ? "Connecting..." : "Disconnected"));
                              
                              final Color dotColor = isConnected
                                  ? Colors.green
                                  : (connState == BleBatteryState.scanning || connState == BleBatteryState.connecting
                                      ? Colors.orange
                                      : Colors.red);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(icon, color: iconColor, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Live Battery",
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.circle, color: dotColor, size: 4),
                                                const SizedBox(width: 3),
                                                Text(
                                                  statusText,
                                                  style: TextStyle(fontSize: 8, color: dotColor, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ValueListenableBuilder<double>(
                                    valueListenable: BleBatteryService.instance.batteryPercentage,
                                    builder: (context, percentage, _) {
                                      final double displayPct = isConnected ? percentage : 0.0;
                                      final String pctText = isConnected ? "${percentage.toStringAsFixed(0)}%" : "--%";
                                      final String rangeText = isConnected
                                          ? "Range ~ ${(percentage * 0.8).toStringAsFixed(0)} km"
                                          : "Range ~ -- km";

                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pctText,
                                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF4313B8)),
                                              ),
                                              Text(
                                                rangeText,
                                                style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                CircularProgressIndicator(
                                                  value: displayPct / 100.0,
                                                  strokeWidth: 4,
                                                  backgroundColor: Colors.grey.shade100,
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4313B8)),
                                                ),
                                                const Icon(Icons.bolt, color: Color(0xFF4313B8), size: 18),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            "Battery Health",
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            isConnected ? "Good" : "--",
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isConnected ? Colors.green : Colors.grey),
                                          ),
                                          const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.green, size: 12),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Wallet Balance card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4313B8).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF4313B8), size: 12),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      "Wallet Balance",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey, size: 14),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "₹250",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFDDD6FE)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, color: Color(0xFF4313B8), size: 10),
                                        SizedBox(width: 2),
                                        Text(
                                          "Add Money",
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF4313B8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.list_alt_rounded, color: Colors.grey, size: 10),
                                        SizedBox(width: 2),
                                        Text(
                                          "Transactions",
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      "Evegah Coins",
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: const [
                                    Text(
                                      "120",
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                    Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey, size: 12),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- 4. KYC BANNER ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4313B8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Complete your KYC",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "To book rides and unlock all features",
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Complete KYC action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4313B8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text("Complete KYC", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- 5. SERVICES ROW ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _buildServiceItem(Icons.flash_on_rounded, "100% Electric", "Zero emissions", Colors.blue),
                    _buildServiceItem(Icons.calendar_today_rounded, "Easy Booking", "Book in 2 taps", Colors.purple),
                    _buildServiceItem(Icons.sell_rounded, "Flexible Pricing", "Mins or hours", Colors.orange),
                    _buildServiceItem(Icons.security_rounded, "Safe & Secure", "Verified rides", Colors.green),
                    _buildServiceItem(Icons.local_offer_rounded, "Offers", "Exciting deals", Colors.red),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 6. OUR EVs SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Our EVs",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VehicleListScreen()),
                        );
                      },
                      child: const Text(
                        "View all",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4313B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _evModels.length,
                  itemBuilder: (context, index) {
                    final ev = _evModels[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehicleDetailsScreen(vehicleId: ev["id"]!),
                          ),
                        );
                      },
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Center(
                                child: Image.asset(ev["image"]!, fit: BoxFit.contain),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ev["name"]!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "From ${ev["price"]}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF5F3FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.keyboard_arrow_right_rounded, color: Color(0xFF4313B8), size: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Color(ev["badgeBg"]!),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ev["badge"]!,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(ev["badgeText"]!),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // --- 7. REFER & RIDE MORE CARDS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Refer & Earn
                    Expanded(
                      child: Container(
                        height: 130,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD1FAE5)),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Refer & Earn",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF047857),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Refer friends and\nearn exciting rewards",
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // Refer now action
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF047857),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "Refer Now →",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: -8,
                              bottom: -8,
                              child: Opacity(
                                opacity: 0.9,
                                child: Image.asset(
                                  "assets/gift_box_refer.png", // Make sure this image exists
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Ride More, Save More
                    Expanded(
                      child: Container(
                        height: 130,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDDD6FE)),
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      "Ride More, Save More",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4313B8),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Unlock exclusive offers\nand ride benefits",
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF8B5CF6),
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const OfferScreen()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4313B8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "View Offers →",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: Opacity(
                                opacity: 0.15,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4313B8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- 8. MORE GRID SECTION ---
              const Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "More",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                  children: [
                    _buildMoreGridItem(Icons.electric_scooter_rounded, "My Rides", () {}),
                    _buildMoreGridItem(Icons.payment_rounded, "Payments", () {}),
                    _buildMoreGridItem(Icons.confirmation_number_rounded, "Coupons", () {}),
                    _buildMoreGridItem(Icons.workspace_premium_rounded, "Evegah Pass", () {}),
                    _buildMoreGridItem(Icons.ev_station_rounded, "Recharge", () {}),
                    _buildMoreGridItem(Icons.help_outline_rounded, "Help Center", () {}),
                    _buildMoreGridItem(Icons.settings_rounded, "Settings", () {}),
                    _buildMoreGridItem(Icons.notifications_active_rounded, "Alerts", () {}),
                    _buildMoreGridItem(Icons.people_alt_rounded, "Invite & Earn", () {}),
                    _buildMoreGridItem(Icons.info_outline_rounded, "About Us", () {}),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build service chips
  Widget _buildServiceItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Helper to build more grid items
  Widget _buildMoreGridItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF4313B8), size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
      ),
    );
  }

  // --- CAROUSEL RENDERER ---
  Widget _buildHeroCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            onPageChanged: (index) {
              setState(() {
                _carouselIndex = index;
              });
            },
            itemCount: _carouselSlides.length,
            itemBuilder: (context, index) {
              final slide = _carouselSlides[index];
              final startColor = Color(slide["gradientStart"]!);
              final endColor = Color(slide["gradientEnd"]!);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [startColor, endColor],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSlideTitle(slide["title"]!),
                              const SizedBox(height: 6),
                              Text(
                                slide["subtitle"]!,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
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
                              backgroundColor: const Color(0xFF4313B8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  slide["button"]!,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, size: 10, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Image.asset(slide["image"]!, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _carouselSlides.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _carouselIndex == idx ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _carouselIndex == idx ? const Color(0xFF4313B8) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideTitle(String title) {
    if (title.contains("Electric")) {
      return const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: "Ride ", style: TextStyle(color: Color(0xFF0F172A))),
            TextSpan(text: "Electric.\n", style: TextStyle(color: Color(0xFF4313B8), fontWeight: FontWeight.w900)),
            TextSpan(text: "Live Better.", style: TextStyle(color: Color(0xFF0F172A))),
          ],
        ),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2),
      );
    } else {
      return Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.2),
      );
    }
  }

  // --- ACTIVE RIDE RENDERER ---
  Widget _buildActiveRideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1452),
            Color(0xFF0F0933),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1452).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.electric_bike, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Ride in Progress",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.circle, color: Colors.greenAccent, size: 8),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActiveRideStat("14:02", "Duration"),
              ValueListenableBuilder<BleBatteryState>(
                valueListenable: BleBatteryService.instance.connectionState,
                builder: (context, connState, _) {
                  if (connState == BleBatteryState.connected) {
                    return ValueListenableBuilder<double>(
                      valueListenable: BleBatteryService.instance.batteryPercentage,
                      builder: (context, percentage, _) {
                        return _buildActiveRideStat("${percentage.toStringAsFixed(0)}%", "Battery");
                      },
                    );
                  }
                  return _buildActiveRideStat("--%", "Battery");
                },
              ),
              _buildActiveRideStat("2.4km", "Distance"),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to active ride
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "View Live Ride",
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActiveRideStat(String val, String lbl) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(lbl, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}