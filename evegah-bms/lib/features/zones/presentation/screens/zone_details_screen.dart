import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../employee/presentation/providers/employee_provider.dart';
import '../../domain/entities/zone_entity.dart';
import '../providers/zone_provider.dart';

class ZoneDetailsScreen extends ConsumerStatefulWidget {
  final ZoneEntity zone;

  const ZoneDetailsScreen({super.key, required this.zone});

  @override
  ConsumerState<ZoneDetailsScreen> createState() => _ZoneDetailsScreenState();
}

class _ZoneDetailsScreenState extends ConsumerState<ZoneDetailsScreen> {
  late List<String> employees;

  @override
  void initState() {
    super.initState();
    employees = [...widget.zone.employeeIds];
  }

  void _showEmployeePicker() {
    final employeeState = ref.read(employeeListProvider);
    final availableEmployees = employeeState.employees;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: availableEmployees.length,
          itemBuilder: (context, index) {
            final employee = availableEmployees[index];
            final employeeName = employee['name'] as String? ?? 'Unknown';

            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(employeeName),
              subtitle: Text(employee['role'] as String? ?? ''),
              onTap: () {
                setState(() {
                  if (!employees.contains(employeeName)) {
                    employees.add(employeeName);
                  }
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$employeeName assigned successfully')),
                );
              },
            );
          },
        );
      },
    );
  }

  void _deleteZone() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Zone'),
          content: const Text('Are you sure you want to delete this zone?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(zoneProvider.notifier)
                    .deleteZone(widget.zone.id);

                context.pop();
                context.pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.zone.name)),
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
                      widget.zone.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text('City: ${widget.zone.city}'),

                    const SizedBox(height: 8),

                    Text('Total Employees: ${employees.length}'),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push(
                            '/zones/edit',
                            extra: widget.zone,
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Zone'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Zone Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text('Employees Assigned: ${employees.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEmployeePicker,
                icon: const Icon(Icons.person_add),
                label: const Text('Assign Employee'),
              ),
            ),

            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Assigned Employees',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: employees.isEmpty
                  ? const Center(child: Text('No Employees Assigned'))
                  : ListView.builder(
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(employees[index]),
                        );
                      },
                    ),
            ),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _deleteZone,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Zone'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
