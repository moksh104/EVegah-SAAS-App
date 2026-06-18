import 'package:flutter/material.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../rides/presentation/screen/ride_history_screen.dart'; 
import '../../../support/presentation/screens/help_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/services/session_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // This variable remembers which tab is currently selected (Starts at 0: Home)
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const RideHistoryScreen(), // Maps to Bookings/Rides
    const WalletScreen(),
    const HelpScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body changes based on which tab is tapped
      body: _screens[_currentIndex],
      
      // The actual Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) async {
            // Bookings (1), Wallet (2), and Profile (4) require user to be logged in
            if (index == 1 || index == 2 || index == 4) {
              final loggedIn = await SessionService().isLoggedIn();
              if (!context.mounted) return;
              if (!loggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                return;
              }
            }
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed, // Forces all 5 icons to stay visible
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4313B8), // Brand Purple
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled, size: 22), 
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month, size: 22), 
              label: "Bookings",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded, size: 22), 
              label: "Wallet",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.headset_mic_rounded, size: 22), 
              label: "Help",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 22), 
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}