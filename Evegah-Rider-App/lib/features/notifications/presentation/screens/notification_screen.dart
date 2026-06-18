import 'package:flutter/material.dart';
import '../../data/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  Future<void> _markAllRead() async {
    if (_notificationService.unreadCount == 0) return;
    
    setState(() => _isLoading = true);
    await _notificationService.markAllAsRead();
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All alerts marked as read ✔️")),
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
        title: const Text("Alerts", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: Colors.black)),
        centerTitle: false,
        actions: [
          if (_notificationService.unreadCount > 0)
            TextButton.icon(
              onPressed: _isLoading ? null : _markAllRead,
              icon: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.done_all_rounded, color: Colors.blue),
              label: const Text("Mark all read", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _notificationService.notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
              itemCount: _notificationService.notifications.length,
              itemBuilder: (context, index) {
                final notification = _notificationService.notifications[index];
                return _buildNotificationTile(notification);
              },
            ),
    );
  }

  // --- HELPER: Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No new alerts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text("You're all caught up!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- HELPER: Notification Tile ---
  Widget _buildNotificationTile(Map<String, dynamic> data) {
    bool isRead = data['isRead'];
    
    // Dynamic styling based on notification type
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (data['type']) {
      case 'payment':
        icon = Icons.account_balance_wallet_rounded;
        iconColor = Colors.purple;
        iconBg = Colors.purple.shade50;
        break;
      case 'ride':
        icon = Icons.electric_scooter_rounded; // Or Icons.moped
        iconColor = Colors.green;
        iconBg = Colors.green.shade50;
        break;
      case 'promo':
        icon = Icons.local_offer_rounded;
        iconColor = Colors.orange;
        iconBg = Colors.orange.shade50;
        break;
      default:
        icon = Icons.info_rounded;
        iconColor = Colors.blue;
        iconBg = Colors.blue.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: isRead ? Border.all(color: Colors.transparent) : Border.all(color: Colors.blue.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          data['title'],
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(data['time'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['message'],
                    style: TextStyle(
                      color: isRead ? Colors.grey.shade600 : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}