import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evegah_maintenance/core/constants/api_constants.dart';
import 'package:evegah_maintenance/core/services/storage_service.dart';
import '../../../../app/routes.dart';
import 'tabs/battery_home_tab.dart';
import 'tabs/battery_scan_tab.dart';
import 'tabs/battery_live_tab.dart';
import 'tabs/battery_monitoring_tab.dart';

class BatteryManagementScreen extends ConsumerStatefulWidget {
  const BatteryManagementScreen({super.key});

  @override
  ConsumerState<BatteryManagementScreen> createState() =>
      _BatteryManagementScreenState();
}

class _BatteryManagementScreenState
    extends ConsumerState<BatteryManagementScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          IgnorePointer(
            ignoring: _currentIndex != 0,
            child: BatteryHomeTab(
              isVisible: _currentIndex == 0,
              onScanNavigate: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
              onLiveNavigate: () {
                setState(() {
                  _currentIndex = 2;
                });
              },
              onAlertsNavigate: () {
                setState(() {
                  _currentIndex = 3;
                });
              },
            ),
          ),
          IgnorePointer(
            ignoring: _currentIndex != 1,
            child: BatteryScanTab(isVisible: _currentIndex == 1),
          ),
          IgnorePointer(
            ignoring: _currentIndex != 2,
            child: BatteryLiveTab(isVisible: _currentIndex == 2),
          ),
          IgnorePointer(
            ignoring: _currentIndex != 3,
            child: BatteryMonitoringTab(isVisible: _currentIndex == 3),
          ),
          IgnorePointer(
            ignoring: _currentIndex != 4,
            child: Scaffold(
              backgroundColor: const Color(0xFFF8F9FD),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Operator Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF151833),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Specialist Profile Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E1C9F), Color(0xFF160E58)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E1C9F).withOpacity(0.20),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned(
                              right: -15,
                              bottom: -20,
                              child: Opacity(
                                opacity: 0.08,
                                child: const Icon(Icons.person_pin_rounded, size: 140, color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Avatar initials with neon lime border
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFCCFF00), width: 2.0),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'HC',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Himanshu Chavda',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'EV Maintenance Specialist',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFFC0BDF2),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFCCFF00).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'Akota EV Zone',
                                                style: TextStyle(
                                                  color: Color(0xFFCCFF00),
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(color: Colors.white24, height: 1),
                                  const SizedBox(height: 16),
                                  
                                  // Stats Row inside Card
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildProfileStatColumn('Completed Swaps', '1,248'),
                                      _buildProfileStatColumn('BMS Managed', '42'),
                                      _buildProfileStatColumn('Service Hours', '280 hrs'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // System Settings Option Title
                      const Text(
                        'System Options',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF151833),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Settings Menu Options Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            _buildSettingsTile(Icons.person_outline_rounded, 'Account Profile', 'Manage profile credentials'),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            _buildSettingsTile(Icons.notifications_active_outlined, 'Notification Settings', 'Adjust alerts & updates'),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            _buildSettingsTile(
                              Icons.wifi_rounded,
                              'Server Connection',
                              'Configure backend API server IP',
                              onTap: () => _showServerIpDialog(context),
                            ),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            _buildSettingsTile(Icons.bluetooth_audio_rounded, 'BLE Device Diagnostic', 'Inspect raw BLE logs'),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            _buildSettingsTile(Icons.volume_up_outlined, 'Speech & TTS System', 'Configure voice alarms'),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF2F2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                              ),
                              title: const Text(
                                'Logout Account',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                              ),
                              subtitle: const Text(
                                'Exit current operation session',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF8C93A8)),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF8C93A8), size: 12),
                              onTap: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                                context.go(AppRoutes.login);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                Icons.home_outlined,
                'Home',
                _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _navItem(
                Icons.assignment_outlined,
                'Devices',
                _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _scanNavItem(),
              _navItem(
                Icons.account_balance_wallet_outlined,
                'Wallet',
                _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _navItem(
                Icons.person_outline_rounded,
                'Profile',
                _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scanNavItem() {
    final isSelected = _currentIndex == 2;
    return InkWell(
      onTap: () => setState(() => _currentIndex = 2),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFCCFF00), // Lime green/yellow circle
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF151833), // Dark color
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF151833) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool isSelected, {
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF151833); // Dark slate/indigo matching Evegah theme
    final inactiveColor = const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFFC0BDF2),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  void _showServerIpDialog(BuildContext context) {
    final controller = TextEditingController(text: ApiConstants.hostIp);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Server Connection',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the backend Express server IP address (e.g. 192.168.1.15):',
              style: TextStyle(fontSize: 11, color: Color(0xFF8C93A8)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g. 192.168.1.15',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8C93A8), fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                await StorageService.saveServerIp(ip);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backend Server IP updated to $ip'),
                      backgroundColor: const Color(0xFF2E1C9F),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E1C9F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Color(0xFFF1EEFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF2E1C9F), size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF8C93A8)),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF8C93A8), size: 12),
      onTap: onTap,
    );
  }
}
