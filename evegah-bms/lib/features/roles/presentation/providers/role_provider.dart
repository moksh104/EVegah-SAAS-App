import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/enums/permission_enum.dart';
import '../../domain/entities/role_entity.dart';

final roleProvider =
    StateNotifierProvider<RoleNotifier, List<RoleEntity>>(
  (ref) => RoleNotifier(),
);

class RoleNotifier extends StateNotifier<List<RoleEntity>> {
  RoleNotifier()
      : super([
          RoleEntity(
            id: '1',
            name: 'Zone Admin',
            permissions: Permission.values,
          ),
          RoleEntity(
            id: '2',
            name: 'Operations Manager',
            permissions: [
              Permission.viewEmployees,
              Permission.viewReports,
            ],
          ),
          RoleEntity(
            id: '3',
            name: 'Franchise Manager',
            permissions: [
              Permission.viewEmployees,
              Permission.createRide,
            ],
          ),
          RoleEntity(
            id: '4',
            name: 'Battery Technician',
            permissions: [
              Permission.createRide,
              Permission.extendRide,
              Permission.returnRide,
            ],
          ),
          RoleEntity(
            id: '5',
            name: 'Support Executive',
            permissions: [
              Permission.batterySwap,
            ],
          ),
        ]);

  void addRole(RoleEntity role) {
    state = [...state, role];
  }

  void updateRole(RoleEntity updatedRole) {
    state = state.map((role) {
      return role.id == updatedRole.id ? updatedRole : role;
    }).toList();
  }

  void deleteRole(String id) {
    state = state.where((role) => role.id != id).toList();
  }
}