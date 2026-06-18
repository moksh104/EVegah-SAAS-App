class NotificationService {
  // --- SINGLETON SETUP ---
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() {
    return _instance;
  }
  NotificationService._internal();

  // --- NOTIFICATION DATA ---
  // A list of maps simulating data from Firebase Push Notifications
  List<Map<String, dynamic>> notifications = [
    {
      "id": "1",
      "type": "payment",
      "title": "Wallet Recharge Successful",
      "message": "₹500 has been successfully added to your EVegah wallet.",
      "time": "10 mins ago",
      "isRead": false,
    },
    {
      "id": "2",
      "type": "ride",
      "title": "Ride Completed",
      "message": "Your trip to Cyber City was completed safely. You saved 2.5kg of CO₂!",
      "time": "2 hours ago",
      "isRead": false,
    },
    {
      "id": "3",
      "type": "promo",
      "title": "Weekend Offer! 🎉",
      "message": "Use code GREEN50 to get 50% off on your next 2 rides.",
      "time": "Yesterday",
      "isRead": true,
    },
    {
      "id": "4",
      "type": "system",
      "title": "App Update Available",
      "message": "Update EVegah to v2.0.0 for faster Bluetooth unlocking.",
      "time": "2 days ago",
      "isRead": true,
    },
  ];

  // --- METHODS ---
  
  // Simulates marking all notifications as read
  Future<void> markAllAsRead() async {
    // Fake a quick network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Loop through and update the status
    for (var notification in notifications) {
      notification['isRead'] = true;
    }
  }

  // Count how many unread notifications we have
  int get unreadCount {
    return notifications.where((n) => n['isRead'] == false).length;
  }
}