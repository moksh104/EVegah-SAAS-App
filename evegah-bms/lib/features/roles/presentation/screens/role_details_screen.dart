import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/enums/permission_enum.dart';
import '../../domain/entities/role_entity.dart';
import '../providers/role_provider.dart';

class RoleDetailsScreen extends ConsumerWidget {
  final RoleEntity role;

  const RoleDetailsScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reactively watch the roles provider for any updates to this specific role.
    final rolesList = ref.watch(roleProvider);
    final currentRole = rolesList.firstWhere(
      (r) => r.id == role.id,
      orElse: () => role,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(currentRole.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Role',
            onPressed: () {
              context.push('/roles/edit', extra: currentRole);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  Theme.of(context).primaryColor.withValues(alpha: 0.02),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 38,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentRole.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currentRole.permissions.length} of ${Permission.values.length} Permissions Active',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Permissions section title
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Text(
              'ROLE CAPABILITIES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.grey[600],
              ),
            ),
          ),

          // Dynamic Permissions Checklist (Active vs Inactive)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: Permission.values.length,
              itemBuilder: (context, index) {
                final permission = Permission.values[index];
                final isGranted = currentRole.permissions.contains(permission);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isGranted ? Colors.green.withValues(alpha: 0.03) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isGranted
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    dense: true,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isGranted
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.grey[200],
                      child: Icon(
                        isGranted ? Icons.check : Icons.lock_outline,
                        size: 14,
                        color: isGranted ? Colors.green : Colors.grey[500],
                      ),
                    ),
                    title: Text(
                      permission.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isGranted ? FontWeight.w600 : FontWeight.normal,
                        color: isGranted ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                    trailing: Text(
                      isGranted ? 'Granted' : 'Blocked',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isGranted ? Colors.green[700] : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Delete Action Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, ref, currentRole),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Role'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, RoleEntity currentRole) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Role'),
          content: Text(
            'Are you sure you want to delete the role "${currentRole.name}"? '
            'This action cannot be undone and may affect employees assigned to this role.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Delete from provider
                ref.read(roleProvider.notifier).deleteRole(currentRole.id);
                // Close dialog
                Navigator.of(dialogContext).pop();
                // Close details screen
                context.pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Role "${currentRole.name}" deleted successfully.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
