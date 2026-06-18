import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/battery/presentation/screens/battery_management_screen.dart';
import '../features/roles/presentation/screens/role_list_screen.dart';
import '../features/roles/presentation/screens/create_role_screen.dart';
import '../features/roles/presentation/screens/role_details_screen.dart';
import '../features/roles/domain/entities/role_entity.dart';
import 'routes.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/rider_dashboard_screen.dart';
import '../features/employee/presentation/screens/employee_list_screen.dart';
import '../features/employee/presentation/screens/create_employee_screen.dart';
import '../features/employee/presentation/screens/employee_details_screen.dart';
import '../features/zones/presentation/screens/zone_list_screen.dart';
import '../features/zones/presentation/screens/create_zone_screen.dart';
import '../features/zones/domain/entities/zone_entity.dart';
import '../features/zones/presentation/screens/zone_details_screen.dart';
import '../features/franchise/presentation/screens/franchise_list_screen.dart';
import '../features/franchise/presentation/screens/create_franchise_screen.dart';
import '../features/franchise/presentation/screens/franchise_details_screen.dart';
import '../features/franchise/domain/entities/franchise_entity.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      // ──── Auth ────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) => const OtpScreen(),
      ),

      // ──── Dashboard ────
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.riderDashboard,
        builder: (context, state) => const RiderDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.batteryManagement,
        builder: (context, state) => const BatteryManagementScreen(),
      ),

      // ──── Employee ────
      GoRoute(
        path: AppRoutes.employees,
        builder: (context, state) => const EmployeeListScreen(),
      ),
      GoRoute(
        path: AppRoutes.employeeCreate,
        builder: (context, state) => const CreateEmployeeScreen(),
      ),
      GoRoute(
        path: AppRoutes.employeeDetails,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EmployeeDetailsScreen(employeeId: id);
        },
      ),

      // ──── Roles ────
      GoRoute(
        path: AppRoutes.roles,
        builder: (context, state) => const RoleListScreen(),
      ),
      GoRoute(
        path: '/roles/create',
        builder: (context, state) => const CreateRoleScreen(),
      ),
      GoRoute(
        path: '/roles/details',
        builder: (context, state) {
          final role = state.extra as RoleEntity;
          return RoleDetailsScreen(role: role);
        },
      ),
      GoRoute(
        path: '/roles/edit',
        builder: (context, state) {
          final role = state.extra as RoleEntity;
          return CreateRoleScreen(roleToEdit: role);
        },
      ),
      // ──── Zones ────
      GoRoute(
        path: AppRoutes.zones,
        builder: (context, state) => const ZoneListScreen(),
      ),
      GoRoute(
        path: '/zones/details',
        builder: (context, state) {
          final zone = state.extra;

          if (zone == null || zone is! ZoneEntity) {
            return const Scaffold(
              body: Center(child: Text('Zone data not found')),
            );
          }

          return ZoneDetailsScreen(zone: zone);
        },
      ),
      GoRoute(
        path: '/zones/create',
        builder: (context, state) => const CreateZoneScreen(),
      ),
      GoRoute(
        path: '/zones/edit',
        builder: (context, state) {
          final zone = state.extra as ZoneEntity;
          return CreateZoneScreen(zoneToEdit: zone);
        },
      ),

      // ──── Franchises ────
      GoRoute(
        path: AppRoutes.franchises,
        builder: (context, state) => const FranchiseListScreen(),
      ),

      GoRoute(
        path: '/franchise/create',
        builder: (context, state) => const CreateFranchiseScreen(),
      ),

      GoRoute(
        path: '/franchise/details',
        builder: (context, state) {
          final franchise = state.extra as FranchiseEntity;

          return FranchiseDetailsScreen(franchise: franchise);
        },
      ),
    ],
  );
}
