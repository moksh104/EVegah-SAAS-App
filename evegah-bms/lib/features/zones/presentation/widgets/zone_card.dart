import 'package:flutter/material.dart';

class ZoneCard extends StatelessWidget {
  final String zoneName;
  final String city;
  final int totalEmployees;
  final VoidCallback onTap;

  const ZoneCard({
    super.key,
    required this.zoneName,
    required this.city,
    required this.totalEmployees,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.location_city)),
        title: Text(zoneName),
        subtitle: Text('$city • $totalEmployees Employees'),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
