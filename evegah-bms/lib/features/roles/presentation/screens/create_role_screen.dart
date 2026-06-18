import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/enums/permission_enum.dart';
import '../../domain/entities/role_entity.dart';
import '../providers/role_provider.dart';

class CreateRoleScreen extends ConsumerStatefulWidget {
  final RoleEntity? roleToEdit;

  const CreateRoleScreen({
    super.key,
    this.roleToEdit,
  });

  @override
  ConsumerState<CreateRoleScreen> createState() => _CreateRoleScreenState();
}

class _CreateRoleScreenState extends ConsumerState<CreateRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController();
  List<Permission> selectedPermissions = [];

  bool get isEditMode => widget.roleToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _roleController.text = widget.roleToEdit!.name;
      selectedPermissions = List.from(widget.roleToEdit!.permissions);
    }
  }

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  void _saveRole() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one permission.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final trimmedName = _roleController.text.trim();

    if (isEditMode) {
      final updatedRole = RoleEntity(
        id: widget.roleToEdit!.id,
        name: trimmedName,
        permissions: selectedPermissions,
      );
      ref.read(roleProvider.notifier).updateRole(updatedRole);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final newRole = RoleEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: trimmedName,
        permissions: selectedPermissions,
      );
      ref.read(roleProvider.notifier).addRole(newRole);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Role created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Role' : 'Create Role'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Role Name Field
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Role Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Role name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Role name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Permissions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Permissions *',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (selectedPermissions.length == Permission.values.length) {
                          selectedPermissions.clear();
                        } else {
                          selectedPermissions = List.from(Permission.values);
                        }
                      });
                    },
                    icon: Icon(
                      selectedPermissions.length == Permission.values.length
                          ? Icons.deselect
                          : Icons.select_all,
                      size: 18,
                    ),
                    label: Text(
                      selectedPermissions.length == Permission.values.length
                          ? 'Deselect All'
                          : 'Select All',
                    ),
                  ),
                ],
              ),
              Text(
                'Select the specific capabilities allowed for this role.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),

              // Dynamic Permissions List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    itemCount: Permission.values.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final permission = Permission.values[index];
                      final isSelected = selectedPermissions.contains(permission);

                      return CheckboxListTile(
                        title: Text(
                          permission.label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        value: isSelected,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedPermissions.add(permission);
                            } else {
                              selectedPermissions.remove(permission);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveRole,
                  child: Text(
                    isEditMode ? 'Save Changes' : 'Create Role',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
