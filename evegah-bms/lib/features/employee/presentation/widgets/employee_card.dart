import 'package:flutter/material.dart';

class EmployeeCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final VoidCallback onTap;

  const EmployeeCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(
            name[0].toUpperCase(),
          ),
        ),
        title: Text(name),
        subtitle: Text('$role\n$email'),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.shade100
                : Colors.red.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isActive ? 'Active' : 'Inactive',
          ),
        ),
      ),
    );
  }
}
