import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/franchise_entity.dart';
import '../providers/franchise_provider.dart';

class FranchiseDetailsScreen extends ConsumerWidget {
  final FranchiseEntity franchise;

  const FranchiseDetailsScreen({super.key, required this.franchise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(franchise.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      franchise.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text('Owner: ${franchise.ownerName}'),

                    const SizedBox(height: 8),

                    Text('Zones: ${franchise.zoneIds.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref
                      .read(franchiseProvider.notifier)
                      .deleteFranchise(franchise.id);

                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete Franchise'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
