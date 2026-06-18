import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evegah_maintenance/app/routes.dart';

import '../widgets/activity_card.dart';
import '../widgets/dashboard_kpi_card.dart';
import '../widgets/side_navigation.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Light blue-grey backdrop
      drawer: const SideNavigation(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'evegah operations',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF151833),
            letterSpacing: -0.3,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF151833)),
        actions: [
          // Custom Notification Bell with Lime Dot
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF151833), size: 18),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCCFF00), // Lime green badge dot
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // User Avatar Button
          GestureDetector(
            onTap: () {
              // Quick navigate to profile
              context.push(AppRoutes.batteryManagement);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2E1C9F),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCCFF00), width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'HC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcomes Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome Back 👋",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF151833),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Monitor rides, vehicles, employees and revenue.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8C93A8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // KPI Grid
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isMobile ? 1.55 : 2.0,
              children: const [
                DashboardCard(
                  title: "Today's Rides",
                  value: "156",
                  icon: Icons.electric_bike_rounded,
                ),
                DashboardCard(
                  title: "Active Vehicles",
                  value: "84",
                  icon: Icons.directions_car_rounded,
                ),
                DashboardCard(
                  title: "Employees",
                  value: "42",
                  icon: Icons.people_rounded,
                ),
                DashboardCard(
                  title: "Revenue",
                  value: "₹1.24L",
                  icon: Icons.currency_rupee_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Actions Section
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF151833),
              ),
            ),
            const SizedBox(height: 10),

            // Redesigned horizontal action pills
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isMobile ? 2.5 : 3.0,
              children: [
                _buildActionBtn(
                  context,
                  "Create Employee",
                  Icons.person_add_alt_1_rounded,
                  const Color(0xFF6366F1),
                  route: AppRoutes.employeeCreate,
                ),
                _buildActionBtn(
                  context,
                  "Create Ride",
                  Icons.add_road_rounded,
                  const Color(0xFF22C55E),
                ),
                _buildActionBtn(
                  context,
                  "Battery Swap",
                  Icons.battery_charging_full_rounded,
                  const Color(0xFFEA580C),
                  route: AppRoutes.batteryManagement,
                ),
                _buildActionBtn(
                  context,
                  "Analytics",
                  Icons.analytics_rounded,
                  const Color(0xFF3B82F6),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Activity & Alerts cards in Columns
            if (isMobile) ...[
              _activitySection(),
              const SizedBox(height: 12),
              _alertsSection(),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _activitySection()),
                  const SizedBox(width: 12),
                  Expanded(child: _alertsSection()),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Redesigned action button builder matching the BMS home tab action design
  Widget _buildActionBtn(
    BuildContext context,
    String label,
    IconData icon,
    Color color, {
    String? route,
  }) {
    return InkWell(
      onTap: () {
        if (route != null) {
          context.push(route);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151833),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activitySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Recent Activities",
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151833),
            ),
          ),
          SizedBox(height: 14),
          ActivityTile(
            title: "New Ride Created",
            subtitle: "GJ05AB1234 assigned",
          ),
          Divider(color: Color(0xFFF1F5F9), height: 16),
          ActivityTile(
            title: "Battery Swap Completed",
            subtitle: "Vehicle GJ05CD5678 completed swap",
          ),
          Divider(color: Color(0xFFF1F5F9), height: 16),
          ActivityTile(
            title: "Employee Added",
            subtitle: "Zone Manager created successfully",
          ),
        ],
      ),
    );
  }

  Widget _alertsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Alerts & Notifications",
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151833),
            ),
          ),
          const SizedBox(height: 10),
          _buildAlertRow(
            Icons.warning_amber_rounded,
            Colors.orange,
            const Color(0xFFFFFBEB),
            "Low Battery Alert",
            "Vehicle GJ05CD5678 requires immediate swap.",
          ),
          const SizedBox(height: 8),
          _buildAlertRow(
            Icons.location_off_rounded,
            Colors.red,
            const Color(0xFFFEF2F2),
            "GPS Device Offline",
            "GJ05AB1234 transmission signal lost.",
          ),
          const SizedBox(height: 8),
          _buildAlertRow(
            Icons.access_time_filled_rounded,
            Colors.blue,
            const Color(0xFFEFF6FF),
            "Ride Delayed",
            "Employee Himanshu shift ride delayed by 15m.",
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRow(
    IconData icon,
    Color iconColor,
    Color bgIconColor,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgIconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF151833),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8C93A8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
