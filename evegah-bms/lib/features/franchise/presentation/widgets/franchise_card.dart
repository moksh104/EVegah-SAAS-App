import 'package:flutter/material.dart';

class FranchiseCard extends StatelessWidget {
  final String name;
  final String ownerName;
  final int totalZones;
  final VoidCallback onTap;

  const FranchiseCard({
    super.key,
    required this.name,
    required this.ownerName,
    required this.totalZones,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.store)),
        title: Text(name),
        subtitle: Text('$ownerName • $totalZones Zones'),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
