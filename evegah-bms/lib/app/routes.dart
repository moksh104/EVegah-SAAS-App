/// Centralized route path constants for the entire application.
///
/// Usage: `AppRoutes.login` instead of hardcoding '/login'.
/// This prevents typos and makes route refactoring safe.
abstract class AppRoutes {
  // ──── Auth ────
  static const String login = '/login';
  static const String otp = '/otp';

  // ──── Dashboard ────
  static const String dashboard = '/dashboard';
  // Rider dashboard (mobile)
  static const String riderDashboard = '/rider';
  // Battery Management & Connection
  static const String batteryManagement = '/battery-management';

  // ──── Employee ────
  static const String employees = '/employees';
  static const String employeeCreate = '/employees/create';
  static const String employeeDetails = '/employees/:id';

  // ──── Roles ────
  static const String roles = '/roles';

  // ──── Zone ────
  static const String zones = '/zones';

  // ──── Franchise ────
  static const String franchises = '/franchises';

  /// Helper to generate employee detail path with a specific ID.
  static String employeeById(String id) => '/employees/$id';
}
