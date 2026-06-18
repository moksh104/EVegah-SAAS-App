import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evegah_maintenance/app/routes.dart';

class SideNavigation extends StatelessWidget {
  const SideNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Text(
                "EVagah Employee",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _menu(context, Icons.dashboard, "Dashboard", AppRoutes.dashboard),
          _menu(context, Icons.people, "Employees", AppRoutes.employees),
          _menu(context, Icons.location_city, "Zones", AppRoutes.zones),
          _menu(context, Icons.store, "Franchise", AppRoutes.franchises),
          _menu(context, Icons.supervised_user_circle_outlined, "Users & Roles", AppRoutes.roles),
          _menu(context, Icons.electric_bike, "Rides", null),
          _menu(
            context,
            Icons.battery_charging_full,
            "BMS Swap",
            AppRoutes.batteryManagement,
          ),
          _menu(context, Icons.analytics, "Analytics", null),
          _menu(context, Icons.summarize, "Reports", null),
          const Spacer(),
          _menu(context, Icons.logout, "Logout", AppRoutes.login),
        ],
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String title,
    String? route,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        if (route != null) {
          context.go(route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title feature is coming soon!'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E293B),
            ),
          );
        }
      },
    );
  }
}
