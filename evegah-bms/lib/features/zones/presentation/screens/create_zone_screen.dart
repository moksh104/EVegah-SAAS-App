import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/zone_entity.dart';
import '../providers/zone_provider.dart';

class CreateZoneScreen extends ConsumerStatefulWidget {
  final ZoneEntity? zoneToEdit;

  const CreateZoneScreen({
    super.key,
    this.zoneToEdit,
  });

  @override
  ConsumerState<CreateZoneScreen> createState() => _CreateZoneScreenState();
}

class _CreateZoneScreenState extends ConsumerState<CreateZoneScreen> {
  final _zoneController = TextEditingController();

  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.zoneToEdit != null) {
      _zoneController.text = widget.zoneToEdit!.name;
      _cityController.text = widget.zoneToEdit!.city;
    }
  }

  @override
  void dispose() {
    _zoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _saveZone() {
    if (_zoneController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty) {
      return;
    }

    if (widget.zoneToEdit == null) {
      ref
          .read(zoneProvider.notifier)
          .addZone(
            ZoneEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _zoneController.text.trim(),
              city: _cityController.text.trim(),
              employeeIds: [],
            ),
          );
    } else {
      ref
          .read(zoneProvider.notifier)
          .updateZone(
            ZoneEntity(
              id: widget.zoneToEdit!.id,
              name: _zoneController.text.trim(),
              city: _cityController.text.trim(),
              employeeIds: widget.zoneToEdit!.employeeIds,
              zoneManagerId: widget.zoneToEdit!.zoneManagerId,
            ),
          );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.zoneToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Zone' : 'Create Zone'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _zoneController,
              decoration: const InputDecoration(labelText: 'Zone Name'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveZone,
                child: Text(isEditing ? 'Update Zone' : 'Create Zone'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
