import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/battery_model.dart';
import '../../providers/battery_provider.dart';
import '../../widgets/battery_details_dialog.dart';

class BatteryHomeTab extends ConsumerWidget {
  final bool isVisible;
  final VoidCallback onScanNavigate;
  final VoidCallback onLiveNavigate;
  final VoidCallback onAlertsNavigate;

  const BatteryHomeTab({
    super.key,
    required this.isVisible,
    required this.onScanNavigate,
    required this.onLiveNavigate,
    required this.onAlertsNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryState = ref.watch(batteryProvider);
    final connectedList = batteryState.connectedBatteries;

    // Calculate metrics dynamically based on actual connected batteries
    final int connectedCount = connectedList
        .where((b) => b.status == BatteryStatus.connected)
        .length;
    final int totalBatteriesCount = connectedList.length;
    final int availableCount = connectedList
        .where((b) => b.status == BatteryStatus.connected && b.current == 0)
        .length;
    final int inUseCount = connectedList
        .where((b) => b.status == BatteryStatus.connected && b.current < 0)
        .length;
    final int chargingCount = connectedList
        .where((b) => b.status == BatteryStatus.connected && b.current > 0)
        .length;

    final int lowBatteryCount = connectedList.where((b) => b.soc <= 75).length;
    final int faultsCount = connectedList
        .where((b) => b.status == BatteryStatus.faulty)
        .length;

    // Calculate Average SoC
    double avgSoc = 0.0;
    if (connectedList.isNotEmpty) {
      double totalSoc = connectedList.fold(0.0, (sum, b) => sum + b.soc);
      avgSoc = totalSoc / connectedList.length;
    }

    final String currentTime = DateFormat('hh:mm a').format(DateTime.now());
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Container(
      color: const Color(0xFFF8F9FD), // Light blue-grey backdrop
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Hi, Himanshu 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF151833),
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Akota EV Zone • Specialist',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8C93A8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // System Healthy Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2FDF2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'System Healthy',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Total Batteries Card & Active Connections Card (Responsive layout)
              if (isMobile) ...[
                _buildTotalBatteriesCard(
                  totalBatteriesCount,
                  availableCount,
                  inUseCount,
                  chargingCount,
                  faultsCount,
                  currentTime,
                  screenWidth,
                ),
                const SizedBox(height: 14),
                _buildActiveConnectionsCard(connectedList),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 12,
                      child: _buildTotalBatteriesCard(
                        totalBatteriesCount,
                        availableCount,
                        inUseCount,
                        chargingCount,
                        faultsCount,
                        currentTime,
                        screenWidth,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 11,
                      child: _buildActiveConnectionsCard(connectedList),
                    ),
                  ],
                ),
              const SizedBox(height: 14),

              // KPI Stats Grid
              _buildKpiGrid(
                connectedCount,
                availableCount,
                lowBatteryCount,
                faultsCount,
                screenWidth,
              ),
              const SizedBox(height: 14),

              // Average State of Charge & Recent Activity Layout
              if (isMobile) ...[
                _buildAverageSocCard(avgSoc, connectedList),
                const SizedBox(height: 14),
                _buildRecentActivityCard(batteryState.recentActivity),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 11,
                      child: _buildAverageSocCard(avgSoc, connectedList),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 12,
                      child: _buildRecentActivityCard(
                        batteryState.recentActivity,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),

              // Quick Actions Layout
              _buildQuickActionsCard(screenWidth, ref),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalBatteriesCard(
    int total,
    int available,
    int inUse,
    int charging,
    int faulty,
    String syncTime,
    double screenWidth,
  ) {
    final bool showImage = screenWidth >= 400;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1C9F), Color(0xFF160E58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E1C9F).withOpacity(0.20),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Faded shield check watermark
          Positioned(
            right: -15,
            bottom: -20,
            child: Opacity(
              opacity: 0.08,
              child: const Icon(
                Icons.verified_user_rounded,
                size: 140,
                color: Colors.white,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Left details count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total BMS Pack',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC0BDF2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Last Sync: $syncTime',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF908CBF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.autorenew_rounded,
                            size: 12,
                            color: Color(0xFFCCFF00),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Center Image Graphic
                if (showImage) ...[
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/battery_pack.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.battery_charging_full_rounded,
                          size: 44,
                          color: Color(0xFFCCFF00),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                ],

                // Right Breakdowns KPI stats
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTextKpiBadge(const Color(0xFFCCFF00), '$available', 'Available', Icons.flash_on_rounded),
                    const SizedBox(height: 6),
                    _buildTextKpiBadge(const Color(0xFF3B82F6), '$inUse', 'In Use', Icons.bolt_rounded),
                    const SizedBox(height: 6),
                    _buildTextKpiBadge(const Color(0xFFF59E0B), '$charging', 'Charging', Icons.power_rounded),
                    const SizedBox(height: 6),
                    _buildTextKpiBadge(const Color(0xFFEF4444), '$faulty', 'Faulty', Icons.warning_amber_rounded),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextKpiBadge(Color color, String val, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(
          val,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFC0BDF2), fontSize: 10, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(int connected, int available, int low, int faults, double screenWidth) {
    final bool isSmall = screenWidth < 450;

    if (isSmall) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: [
          _buildKpiCard('Connected', '$connected', Icons.bluetooth_rounded, const Color(0xFF22C55E)),
          _buildKpiCard('Available', '$available', Icons.swap_horiz_rounded, const Color(0xFF6366F1)),
          _buildKpiCard('Low BMS', '$low', Icons.battery_alert_rounded, const Color(0xFFF59E0B)),
          _buildKpiCard('Faults', '$faults', Icons.warning_amber_rounded, const Color(0xFFEF4444)),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildKpiCard('Connected', '$connected', Icons.bluetooth_rounded, const Color(0xFF22C55E))),
        const SizedBox(width: 8),
        Expanded(child: _buildKpiCard('Available', '$available', Icons.swap_horiz_rounded, const Color(0xFF6366F1))),
        const SizedBox(width: 8),
        Expanded(child: _buildKpiCard('Low BMS', '$low', Icons.battery_alert_rounded, const Color(0xFFF59E0B))),
        const SizedBox(width: 8),
        Expanded(child: _buildKpiCard('Faults', '$faults', Icons.warning_amber_rounded, const Color(0xFFEF4444))),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      height: 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 12),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF8C93A8)),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF151833)),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 3,
            width: double.infinity,
            color: color, // Matching highlight underline bar
          ),
        ],
      ),
    );
  }

  Widget _buildAverageSocCard(double socValue, List<BatteryModel> connectedList) {
    return Container(
      height: 230,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Average State of Charge',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151833),
                ),
              ),
              GestureDetector(
                onTap: onLiveNavigate,
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF8C93A8),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 105,
              height: 105,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 95,
                    height: 95,
                    child: CircularProgressIndicator(
                      value: socValue / 100,
                      strokeWidth: 10,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFCCFF00), // Neon Lime Green
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${socValue.toInt()}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF151833),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2FDF2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Healthy',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(const Color(0xFF22C55E), 'Healthy', '${connectedList.where((b) => b.soc >= 75).length}'),
              _buildLegendItem(const Color(0xFFF59E0B), 'Medium', '${connectedList.where((b) => b.soc < 75 && b.soc >= 30).length}'),
              _buildLegendItem(const Color(0xFFEF4444), 'Low', '${connectedList.where((b) => b.soc < 30).length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color dotColor, String label, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8C93A8)),
        ),
        const SizedBox(width: 3),
        Text(
          count,
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF151833)),
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard(List<String> recentActivity) {
    return Container(
      height: 230,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151833),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E1C9F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: recentActivity.isEmpty
                ? const Center(
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: Color(0xFF8C93A8), fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentActivity.length > 3 ? 3 : recentActivity.length,
                    itemBuilder: (context, index) {
                      final item = recentActivity[index];
                      final parts = item.split('|');
                      final message = parts[0];
                      final time = parts.length > 1 ? parts[1] : '';

                      Color bgIconColor = const Color(0xFFEFF6FF);
                      Color iconColor = const Color(0xFF3B82F6);
                      IconData icon = Icons.info_outline_rounded;

                      if (message.contains('connected')) {
                        bgIconColor = const Color(0xFFE2FDF2);
                        iconColor = const Color(0xFF22C55E);
                        icon = Icons.link_rounded;
                      } else if (message.contains('disconnected')) {
                        bgIconColor = const Color(0xFFFEF2F2);
                        iconColor = const Color(0xFFEF4444);
                        icon = Icons.link_off_rounded;
                      } else if (message.contains('Renamed')) {
                        bgIconColor = const Color(0xFFF5F3FF);
                        iconColor = const Color(0xFF8B5CF6);
                        icon = Icons.edit_rounded;
                      } else if (message.contains('alert') || message.contains('Low')) {
                        bgIconColor = const Color(0xFFFFF7ED);
                        iconColor = const Color(0xFFEA580C);
                        icon = Icons.warning_amber_rounded;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(color: bgIconColor, shape: BoxShape.circle),
                              child: Icon(icon, color: iconColor, size: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                message,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              time,
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF8C93A8), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConnectionsCard(List<BatteryModel> batteries) {
    final displayList = batteries.take(3).toList();

    return Container(
      height: 160,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Connections (${batteries.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF151833),
                ),
              ),
              GestureDetector(
                onTap: onLiveNavigate,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E1C9F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: displayList.isEmpty
                ? const Center(
                    child: Text(
                      'No connected BMS',
                      style: TextStyle(color: Color(0xFF8C93A8), fontSize: 11),
                    ),
                  )
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final b = displayList[index];
                      Color socColor = const Color(0xFF22C55E);
                      if (b.soc < 30) {
                        socColor = const Color(0xFFEF4444);
                      } else if (b.soc < 75) {
                        socColor = const Color(0xFFF59E0B);
                      }
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => BatteryDetailsDialog(battery: b),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.battery_std_rounded, color: socColor, size: 16),
                              const SizedBox(width: 8),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                b.name,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
                              ),
                              const Spacer(),
                              Text(
                                '${b.soc.toInt()}%',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${b.temperature.toInt()}°C',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8C93A8)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(double screenWidth, WidgetRef ref) {
    final bool isTablet = screenWidth > 600;
    final notifier = ref.read(batteryProvider.notifier);

    return Container(
      height: isTablet ? 130 : 250,
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
            'Quick Actions',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151833),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: isTablet ? 6 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isTablet ? 1.7 : 2.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActionBtn('Scan BLE', Icons.bluetooth_searching_rounded, const Color(0xFF6366F1), onScanNavigate),
                _buildActionBtn('BMS Swap', Icons.swap_horiz_rounded, const Color(0xFF22C55E), onLiveNavigate),
                _buildActionBtn('Voice Demo', Icons.volume_up_rounded, const Color(0xFFEC4899), () {
                  notifier.triggerDemoVoiceAlert();
                }),
                _buildActionBtn('Alert Center', Icons.notifications_active_outlined, const Color(0xFFEF4444), onAlertsNavigate),
                _buildActionBtn('Add BMS', Icons.add_circle_outline_rounded, const Color(0xFF3B82F6), () {}),
                _buildActionBtn('BMS Report', Icons.assignment_outlined, const Color(0xFFF59E0B), () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 6),
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
}
