import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/zone_provider.dart';
import '../widgets/zone_card.dart';

class ZoneListScreen extends ConsumerWidget {
  const ZoneListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(zoneProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Zones')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/zones/create');
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: zones.length,
        itemBuilder: (context, index) {
          final zone = zones[index];

          return ZoneCard(
            zoneName: zone.name,
            city: zone.city,
            totalEmployees: zone.employeeIds.length,
            onTap: () {
              context.push('/zones/details', extra: zone,);
            },
          );
        },
      ),
    );
  }
}
