import 'package:flutter/material.dart';
import 'map_discovery_screen.dart';
import '../../../unlock/presentation/screens/scan_qr_screen.dart';
import 'vehicle_list_screen.dart';
import 'vehicle_details_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/services/session_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _carouselIndex = 0;
  bool hasActiveRide = false; // Set to true to view the live active ride card mockup!

  final List<Map<String, String>> _carouselSlides = [
    {
      "title": "Ride Electric.\nLive Better.",
      "subtitle": "Zero emissions. Maximum freedom.",
      "button": "Book EV in minutes",
      "image": "assets/mink.png",
      "gradientStart": "0xFFF4F0FF",
      "gradientEnd": "0xFFE8E3FA",
    },
    {
      "title": "Daman & Aatapi\nSpecial Packages",
      "subtitle": "Rent for hours or days at discounted rates.",
      "button": "View Packages",
      "image": "assets/v1.webp",
      "gradientStart": "0xFFEBF3FF",
      "gradientEnd": "0xFFD6E4FF",
    },
    {
      "title": "Eco Friendly\nCommutes.",
      "subtitle": "Save the environment, save money.",
      "button": "Explore Models",
      "image": "assets/v2.webp",
      "gradientStart": "0xFFFDF2F8",
      "gradientEnd": "0xFFFCE7F3",
    }
  ];

  final List<Map<String, String>> _evModels = [
    {
      "name": "Mink",
      "price": "₹29/hr",
      "image": "assets/mink.png",
    },
    {
      "name": "City",
      "price": "₹39/hr",
      "image": "assets/v1.webp",
    },
    {
      "name": "Fly",
      "price": "₹49/hr",
      "image": "assets/v2.webp",
    },
    {
      "name": "Pro",
      "price": "₹59/hr",
      "image": "assets/v1.webp",
    },
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. NOTIFICATION BELL ROW (Logo removed) ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.black, size: 20),
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
                  ],
                ),
              ),

              // --- 2. TOP SELECTOR BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Location Dropdown Selector
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.location_on, color: Color(0xFF4313B8), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Koramangala, Bengaluru",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Wallet Status Card
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4313B8).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_wallet, color: Color(0xFF4313B8), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "₹250",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    "Evegah Wallet",
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // --- 3. DYNAMIC HERO SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: hasActiveRide ? _buildActiveRideCard() : _buildHeroCarousel(),
              ),

              const SizedBox(height: 24),

              // --- 4. OUR EVs SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Our EVs",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VehicleListScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "View all",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4313B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // EV models scroll list
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _evModels.length,
                  itemBuilder: (context, index) {
                    final ev = _evModels[index];
                    return GestureDetector(
                      onTap: () {
                        final String name = ev["name"]!;
                        String mockId = "MINK001";
                        if (name.contains("City")) mockId = "CITY002";
                        if (name.contains("Fly")) mockId = "FLY003";
                        if (name.contains("Pro")) mockId = "PRO004";
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehicleDetailsScreen(
                              vehicleId: mockId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Center(
                                child: Image.asset(
                                  ev["image"]!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ev["name"]!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "From ${ev["price"]}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // --- 5. FEATURES BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFeatureItem(Icons.bolt, "100% Electric"),
                      _buildFeatureItem(Icons.calendar_today_outlined, "Easy Booking"),
                      _buildFeatureItem(Icons.sell_outlined, "Flexible Pricing"),
                      _buildFeatureItem(Icons.headset_mic_outlined, "24/7 Support"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- 6. PROMOS GRID ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Refer & Earn
                    Expanded(
                      child: Container(
                        height: 140,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9), // Light Green
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
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
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Refer friends and\nearn exciting rewards",
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  "Refer Now →",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: Opacity(
                                opacity: 0.8,
                                child: Image.asset(
                                  "assets/gift_box_refer.png",
                                  width: 65,
                                  height: 65,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Host & Earn
                    Expanded(
                      child: Container(
                        height: 140,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E5F5), // Light Purple
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE1BEE7)),
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
                                      "Host & Earn",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF6A1B9A),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Earn from your vehicle\nwhen not in use",
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF9C27B0),
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  "Know More →",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6A1B9A),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: -14,
                              bottom: -8,
                              child: Opacity(
                                opacity: 0.8,
                                child: Image.asset(
                                  "assets/purple_car_host.png",
                                  width: 80,
                                  height: 60,
                                  fit: BoxFit.contain,
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

              const SizedBox(height: 20),

              // --- 7. NEARBY PARKING ZONES BANNER ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Nearby Parking Zones",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Pick up your EV from convenient parking zones",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mini Map graphic
                      Container(
                        width: 70,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: CustomPaint(
                          painter: _MockMapPainter(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MapDiscoveryScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4313B8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- 8. WHY CHOOSE EVEGAH SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Why choose EVegah?",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: [
                        _buildWhyChooseItem(Icons.verified_user_outlined, "Safe & Secure", "Your safety is our priority", Colors.blue),
                        _buildWhyChooseItem(Icons.eco_outlined, "Eco Friendly", "Zero emissions better tomorrow", Colors.green),
                        _buildWhyChooseItem(Icons.currency_rupee, "Best Value", "Affordable rides great experience", Colors.amber),
                        _buildWhyChooseItem(Icons.people_outline, "Trusted by 10K+", "Riders across Bangalore", Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Bottom navigation clearance spacer
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideTitle(String title) {
    if (title.contains("Electric")) {
      return const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: "Ride ", style: TextStyle(color: Color(0xFF0F172A))),
            TextSpan(text: "Electric.\n", style: TextStyle(color: Color(0xFF4313B8))),
            TextSpan(text: "Live Better.", style: TextStyle(color: Color(0xFF0F172A))),
          ],
        ),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
      );
    } else if (title.contains("Daman")) {
      return const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: "Daman & Aatapi\n", style: TextStyle(color: Color(0xFF4313B8))),
            TextSpan(text: "Special Packages", style: TextStyle(color: Color(0xFF0F172A))),
          ],
        ),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
      );
    } else {
      return const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: "Eco Friendly\n", style: TextStyle(color: Color(0xFF4313B8))),
            TextSpan(text: "Commutes.", style: TextStyle(color: Color(0xFF0F172A))),
          ],
        ),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
      );
    }
  }

  // --- CAROUSEL RENDERER ---
  Widget _buildHeroCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            onPageChanged: (index) {
              setState(() {
                _carouselIndex = index;
              });
            },
            itemCount: _carouselSlides.length,
            itemBuilder: (context, index) {
              final slide = _carouselSlides[index];
              final startColor = Color(int.parse(slide["gradientStart"]!));
              final endColor = Color(int.parse(slide["gradientEnd"]!));

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
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
                                  MaterialPageRoute(
                                    builder: (context) => const ScanQrScreen(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4313B8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  slide["button"]!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward, size: 12, color: Colors.white),
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
                        child: Image.asset(
                          slide["image"]!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _carouselSlides.length,
            (idx) => Container(
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

  // --- ACTIVE RIDE RENDERER ---
  Widget _buildActiveRideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1452), // Deep Brand Indigo
            Color(0xFF0F0933),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1452).withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.electric_bike, color: Colors.white, size: 36),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  "Ride in Progress",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.circle, color: Colors.greenAccent, size: 10),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActiveRideStat("14:02", "Duration"),
              _buildActiveRideStat("87%", "Battery"),
              _buildActiveRideStat("2.4km", "Distance"),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to the live Ride Screen map
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "View Live Ride",
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
        Text(
          val,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          lbl,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // --- FEATURES ITEM BUILDER ---
  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF4313B8).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF4313B8), size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // --- WHY CHOOSE ITEM BUILDER ---
  Widget _buildWhyChooseItem(IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter to draw a mock road network
class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 10), Offset(size.width, 25), paint);
    canvas.drawLine(const Offset(30, 0), Offset(15, size.height), paint);
    canvas.drawLine(const Offset(45, 0), Offset(55, size.height), paint);

    // Parking dots
    final pPaint = Paint()
      ..color = const Color(0xFF4313B8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(20, 15), 3, pPaint);
    canvas.drawCircle(const Offset(45, 30), 3, pPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}