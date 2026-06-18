/// Lifecycle status of an employee in the system.
///
/// Real operations need more than active/inactive — suspensions,
/// soft deletes, and pending onboarding are common scenarios.
enum EmployeeStatus {
  active('Active'),
  inactive('Inactive'),
  suspended('Suspended'),
  deleted('Deleted');

  final String label;
  const EmployeeStatus(this.label);

  /// Whether the employee can perform operations in the system.
  bool get isOperational => this == EmployeeStatus.active;
}
