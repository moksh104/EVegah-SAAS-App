import 'package:flutter/material.dart';

/// A premium, multi-select checkbox list for selecting employee permissions.
///
/// Fully generic, accepting a list of [availablePermissions] and a set of
/// [selectedPermissions], triggering [onChanged] on updates.
class PermissionSelector extends StatelessWidget {
  final List<String> availablePermissions;
  final List<String> selectedPermissions;
  final ValueChanged<List<String>> onChanged;
  final String title;

  const PermissionSelector({
    super.key,
    required this.availablePermissions,
    required this.selectedPermissions,
    required this.onChanged,
    this.title = 'Permissions',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedPermissions.length == availablePermissions.length) {
                      onChanged([]);
                    } else {
                      onChanged(List.from(availablePermissions));
                    }
                  },
                  child: Text(
                    selectedPermissions.length == availablePermissions.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availablePermissions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final permission = availablePermissions[index];
              final isChecked = selectedPermissions.contains(permission);

              // Prettify the permission key for display (e.g. "viewEmployees" -> "View Employees")
              final displayLabel = permission
                  .replaceAllMapped(
                    RegExp(r'(^[a-z]+)|[A-Z]'),
                    (match) => match.group(0)!.toUpperCase(),
                  )
                  .replaceAllMapped(
                    RegExp(r'[A-Z]'),
                    (match) => ' ${match.group(0)}',
                  )
                  .trim();

              return CheckboxListTile(
                value: isChecked,
                activeColor: theme.colorScheme.primary,
                title: Text(
                  displayLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onChanged: (bool? checked) {
                  final updated = List<String>.from(selectedPermissions);
                  if (checked == true) {
                    updated.add(permission);
                  } else {
                    updated.remove(permission);
                  }
                  onChanged(updated);
                },
                controlAffinity: ListTileControlAffinity.trailing,
              );
            },
          ),
        ],
      ),
    );
  }
}
