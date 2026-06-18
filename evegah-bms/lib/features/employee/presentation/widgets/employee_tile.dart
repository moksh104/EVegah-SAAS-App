import 'package:flutter/material.dart';

/// A compact list tile for displaying an employee.
///
/// Simplified version — will be enhanced when the full
/// employee entity with enums is reintroduced.
class EmployeeTile extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback? onTap;
  final Widget? trailing;

  const EmployeeTile({
    super.key,
    required this.name,
    required this.role,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'E',
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(role),
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
          ),
      onTap: onTap,
    );
  }
}
