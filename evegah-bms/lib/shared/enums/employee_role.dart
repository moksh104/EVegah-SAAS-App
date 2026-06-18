/// All employee roles in the EVagah system.
///
/// Used as constants to prevent typo bugs.
/// Ordered by hierarchy level (highest privilege first).
enum EmployeeRole {
  tenantAdmin('Tenant Admin'),
  franchiseOwner('Franchise Owner'),
  zoneManager('Zone Manager'),
  bookingAgent('Booking Agent'),
  maintenanceStaff('Maintenance Staff');

  final String label;
  const EmployeeRole(this.label);

  /// Returns the hierarchy level (lower number = higher privilege).
  int get hierarchyLevel => index;

  /// Whether this role has higher or equal privilege than [other].
  bool outranks(EmployeeRole other) => hierarchyLevel <= other.hierarchyLevel;
}
