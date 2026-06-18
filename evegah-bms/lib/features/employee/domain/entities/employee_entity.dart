class EmployeeEntity {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String role;
  final bool isActive;

  const EmployeeEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    required this.isActive,
  });
}
