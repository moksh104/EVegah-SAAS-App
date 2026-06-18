import 'package:flutter/material.dart';
import '../../data/services/security_service.dart';
// 🚨 Import your login screen so we can route the user there when they log out!
import '../../../../features/auth/presentation/screens/login_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final SecurityService _securityService = SecurityService();
  bool _isLoadingLogoutCurrent = false;
  Map<String, dynamic>? _currentDevice;

  @override
  void initState() {
    super.initState();
    _loadRealDevice();
  }

  Future<void> _loadRealDevice() async {
    final device = await _securityService.getCurrentDevice();
    if (mounted) {
      setState(() {
        _currentDevice = device;
      });
    }
  }

  Future<void> _handleLogoutCurrentDevice() async {
    setState(() => _isLoadingLogoutCurrent = true);
    await _securityService.logoutCurrentDevice();
    setState(() => _isLoadingLogoutCurrent = false);

    if (mounted) {
      // 🚨 This clears the entire app navigation history and pushes the user back to the Login Screen!
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Device Security", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // --- 1. CURRENT DEVICE ---
            const Text("Logged-in Device", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: _currentDevice == null
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: Colors.green)),
                    )
                  : ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _currentDevice!['icon'] == 'phone' ? Icons.smartphone_rounded : Icons.tablet_mac_rounded,
                          color: Colors.green,
                        ),
                      ),
                      title: Text(_currentDevice!['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(_currentDevice!['location'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            _currentDevice!['status'],
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 32),

            // --- 2. ACCOUNT ACTIONS (DANGER ZONE) ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoadingLogoutCurrent ? null : _handleLogoutCurrentDevice,
                icon: _isLoadingLogoutCurrent 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}