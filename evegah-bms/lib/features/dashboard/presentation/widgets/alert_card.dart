import 'package:flutter/material.dart';

/// Alert card widget for displaying system alerts on the dashboard.
/// TODO: Extract alerts section from dashboard_screen.dart into this widget.
class AlertCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const AlertCard({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
    );
  }
}
