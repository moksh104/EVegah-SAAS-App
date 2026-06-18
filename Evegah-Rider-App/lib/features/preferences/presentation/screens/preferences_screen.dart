import 'package:flutter/material.dart';
import '../../data/services/preferences_service.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final PreferencesService _prefService = PreferencesService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Preferences", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // --- 1. NOTIFICATIONS SETTINGS ---
            const Text("Notifications", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildToggle(
                    title: "Push Notifications",
                    subtitle: "Ride updates, low battery alerts",
                    icon: Icons.notifications_active_rounded,
                    value: _prefService.pushNotifications,
                    onChanged: (val) async {
                      await _prefService.toggleSetting('push', val);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                    _buildToggle(
                    title: "Email Offers & Promos",
                    subtitle: "Weekly summaries and discounts",
                    icon: Icons.email_rounded,
                    value: _prefService.emailPromos,
                    onChanged: (val) async {
                      await _prefService.toggleSetting('email', val);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- 2. LANGUAGE SETTINGS ---
            const Text("Language", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: _prefService.availableLanguages.map((lang) {
                  bool isSelected = lang == _prefService.selectedLanguage;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        title: Text(
                          lang, 
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.green.shade700 : Colors.black87
                          )
                        ),
                        trailing: isSelected 
                            ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                            : const SizedBox.shrink(),
                        onTap: () async {
                          await _prefService.changeLanguage(lang);
                          setState(() {});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Language updated to $lang"), backgroundColor: Colors.black),
                            );
                          }
                        },
                      ),
                      if (lang != _prefService.availableLanguages.last)
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: Toggle Switch Row ---
  Widget _buildToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      secondary: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF1E1452), size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      activeThumbColor: Colors.green,
      value: value,
      onChanged: onChanged,
    );
  }
}