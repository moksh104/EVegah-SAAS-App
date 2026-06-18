import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/franchise_entity.dart';
import '../providers/franchise_provider.dart';

class CreateFranchiseScreen extends ConsumerStatefulWidget {
  final FranchiseEntity? franchiseToEdit;

  const CreateFranchiseScreen({super.key, this.franchiseToEdit});

  @override
  ConsumerState<CreateFranchiseScreen> createState() =>
      _CreateFranchiseScreenState();
}

class _CreateFranchiseScreenState extends ConsumerState<CreateFranchiseScreen> {
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.franchiseToEdit != null) {
      _nameController.text = widget.franchiseToEdit!.name;

      _ownerController.text = widget.franchiseToEdit!.ownerName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  void _saveFranchise() {
    if (_nameController.text.trim().isEmpty ||
        _ownerController.text.trim().isEmpty) {
      return;
    }

    final notifier = ref.read(franchiseProvider.notifier);

    if (widget.franchiseToEdit == null) {
      notifier.addFranchise(
        FranchiseEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          ownerName: _ownerController.text.trim(),
          zoneIds: [],
        ),
      );
    } else {
      notifier.updateFranchise(
        FranchiseEntity(
          id: widget.franchiseToEdit!.id,
          name: _nameController.text.trim(),
          ownerName: _ownerController.text.trim(),
          zoneIds: widget.franchiseToEdit!.zoneIds,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.franchiseToEdit == null
              ? 'Create Franchise'
              : 'Edit Franchise',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Franchise Name'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _ownerController,
              decoration: const InputDecoration(labelText: 'Owner Name'),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveFranchise,
                child: Text(
                  widget.franchiseToEdit == null
                      ? 'Create Franchise'
                      : 'Update Franchise',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
