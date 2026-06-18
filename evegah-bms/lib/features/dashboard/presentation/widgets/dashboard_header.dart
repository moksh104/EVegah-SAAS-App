import 'package:flutter/material.dart';

/// Dashboard header widget displaying welcome message and summary info.
/// TODO: Extract header section from dashboard_screen.dart into this widget.
class DashboardHeader extends StatelessWidget {
  final String userName;

  const DashboardHeader({
    super.key,
    this.userName = 'User',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back 👋",
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Monitor rides, vehicles, employees and revenue.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
