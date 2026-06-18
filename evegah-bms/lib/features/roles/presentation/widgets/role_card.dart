import 'package:flutter/material.dart';

class RoleCard extends StatelessWidget {
  final String roleName;
  final int permissionCount;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.roleName,
    required this.permissionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.security)),
        title: Text(roleName),
        subtitle: Text('$permissionCount permissions'),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
