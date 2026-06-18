import 'package:flutter/material.dart';

/// Quick action button widget for dashboard actions.
/// TODO: Extract quick action logic from dashboard_screen.dart into this widget.
class QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onPressed;

  const QuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon),
      label: Text(title),
    );
  }
}
