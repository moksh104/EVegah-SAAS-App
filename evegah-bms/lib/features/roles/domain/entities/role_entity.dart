import '../../../../shared/enums/permission_enum.dart';

class RoleEntity {
  final String id;
  final String name;
  final List<Permission> permissions;

  const RoleEntity({
    required this.id,
    required this.name,
    required this.permissions,
  });
}
