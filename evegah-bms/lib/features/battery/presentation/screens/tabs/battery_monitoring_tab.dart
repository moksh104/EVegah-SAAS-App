import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/battery_provider.dart';
import '../../../data/models/battery_model.dart';

class BatteryMonitoringTab extends ConsumerStatefulWidget {
  final bool isVisible;
  const BatteryMonitoringTab({super.key, required this.isVisible});

  @override
  ConsumerState<BatteryMonitoringTab> createState() => _BatteryMonitoringTabState();
}

class _BatteryMonitoringTabState extends ConsumerState<BatteryMonitoringTab> {
  String? _selectedBatteryId;
  int _selectedSubTabIndex = 0; // 0: Live Data, 1: Alerts, 2: History, 3: Settings
  String _selectedVoltageMode = 'Total'; // Dropdown inside Voltage card

  // Default Mock Battery matching mockup screenshot
  static final BatteryModel _mockBattery = BatteryModel(
    id: 'mock_evg_00124',
    name: 'EVG-BMS-00124',
    soc: 80.0,
    temperature: 28.0,
    voltage: 51.2,
    current: -12.5,
    rssi: -50,
    status: BatteryStatus.connected,
    cycleCount: 128,
    health: 96,
    designCapacity: 100.0,
    remainingCapacity: 80.0,
    cellsInSeries: 13,
    cellVoltages: [3938, 3940, 3935, 3939, 3942, 3941, 3937, 3939, 3940, 3938, 3939, 3941, 3938],
    voltHistory: [50.8, 51.0, 50.9, 51.2, 51.1, 51.2],
    tempHistory: [27.0, 27.5, 28.0, 28.0, 28.0, 28.0],
    currentHistory: [-10.0, -12.0, -12.5, -12.5, -12.5, -12.5],
  );

  @override
  Widget build(BuildContext context) {
    final batteryState = ref.watch(batteryProvider);
    
    // Fallback if no batteries are connected to guarantee the mockup layout is rendered
    final activeList = batteryState.connectedBatteries.isNotEmpty
        ? batteryState.connectedBatteries
        : [_mockBattery];

    // Determine currently selected battery
    final String selectedId = _selectedBatteryId ?? activeList.first.id;
    final selectedBattery = activeList.firstWhere(
      (b) => b.id == selectedId,
      orElse: () => activeList.first,
    );

    // Calculate Dynamic Values for selected battery
    final double soc = selectedBattery.soc;
    final double voltage = selectedBattery.voltage;
    final double current = selectedBattery.current;
    final double temp = selectedBattery.temperature;
    final double remainingCapacity = selectedBattery.remainingCapacity > 0
        ? selectedBattery.remainingCapacity
        : (selectedBattery.designCapacity * (soc / 100.0));

    // Estimated time calculation
    String estTime = '2h 35m'; // default mockup value
    if (selectedBattery.id != _mockBattery.id) {
      if (current < 0) {
        final double hours = remainingCapacity / current.abs();
        final int h = hours.toInt();
        final int m = ((hours - h) * 60).toInt();
        estTime = '${h}h ${m}m';
      } else if (current > 0) {
        final double emptyCap = selectedBattery.designCapacity - remainingCapacity;
        final double hours = emptyCap / current;
        final int h = hours.toInt();
        final int m = ((hours - h) * 60).toInt();
        estTime = '${h}h ${m}m';
      } else {
        estTime = '--';
      }
    }

    final String statusText = selectedBattery.status == BatteryStatus.faulty
        ? 'Faulty'
        : 'Normal';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER PANEL ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF151833), size: 20),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            // If embedded in tab bar, default action is going back to Home
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Use the bottom navigation to switch tabs'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Battery Monitoring',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF151833),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedId,
                                  isDense: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF8C93A8),
                                    size: 15,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  items: activeList.map((b) {
                                    return DropdownMenuItem<String>(
                                      value: b.id,
                                      child: Text(
                                        'Evegah Smart BMS • ${b.name}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF8C93A8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedBatteryId = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCCFF00), // Lime green connected dot
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Connected',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8CE300), // Lime green/yellow
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Bell Icon with yellow badge
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.notifications_none_rounded, color: Color(0xFF151833), size: 20),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFCCFF00), // Yellow-green badge
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Three Dots Button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        ),
                        child: const Icon(Icons.more_horiz_rounded, color: Color(0xFF151833), size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── SCROLLABLE BODY ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ── TOP GRADIENT SOC CARD ──────────────────────────────────
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E1C9F), Color(0xFF160E58)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E1C9F).withOpacity(0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Shield Watermark
                          Positioned(
                            right: -10,
                            bottom: -15,
                            child: Opacity(
                              opacity: 0.08,
                              child: const Icon(
                                Icons.verified_user_rounded,
                                size: 130,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                // Left Details
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'State of Charge',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFC0BDF2),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '${soc.toInt()}',
                                            style: const TextStyle(
                                              fontSize: 42,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Text(
                                            '%',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCCFF00).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'Charging',
                                              style: TextStyle(
                                                color: Color(0xFFCCFF00),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.flash_on_rounded,
                                              color: Color(0xFFCCFF00),
                                              size: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Center Circular Gauge
                                Expanded(
                                  flex: 4,
                                  child: Center(
                                    child: SizedBox(
                                      width: 85,
                                      height: 85,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CustomPaint(
                                            size: const Size(85, 85),
                                            painter: CircularSocPainter(
                                              soc: soc,
                                              progressColor: const Color(0xFFCCFF00),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.flash_on_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Right Details
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Remaining Capacity',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFC0BDF2),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            remainingCapacity.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Text(
                                            'Ah',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Estimated Time',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFC0BDF2),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        estTime,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 4 MINI KPI CARDS ROW ──────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniKpiCard(
                            label: 'SOC',
                            value: '${soc.toInt()}%',
                            icon: Icons.flash_on_rounded,
                            hasUnderline: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniKpiCard(
                            label: 'Total Voltage',
                            value: '${voltage.toStringAsFixed(1)}v',
                            icon: Icons.electric_bolt_rounded,
                            hasUnderline: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniKpiCard(
                            label: 'Temperature',
                            value: '${temp.toInt()}°c',
                            icon: Icons.thermostat_rounded,
                            hasUnderline: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMiniKpiCard(
                            label: 'Status',
                            value: statusText,
                            icon: Icons.verified_user_rounded,
                            hasUnderline: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── 2X2 TELEMETRY GRID ────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (SOC and Current)
                        Expanded(
                          child: Column(
                            children: [
                              // 1. State of Charge (SOC) Card
                              _buildTelemetryCard(
                                title: 'State of Charge (SOC)',
                                value: '${soc.toInt()}%',
                                content: SizedBox(
                                  height: 100,
                                  width: double.infinity,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(100, 100),
                                        painter: SemiCircularSocPainter(
                                          soc: soc,
                                          progressColor: const Color(0xFFCCFF00),
                                        ),
                                      ),
                                      Positioned(
                                        top: 24,
                                        child: Column(
                                          children: [
                                            const Icon(Icons.flash_on_rounded, color: Color(0xFFCCFF00), size: 24),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'SOC',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF8C93A8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                footer: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCFF00).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'Charging',
                                        style: TextStyle(
                                          color: Color(0xFF8CE300),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.flash_on_rounded, color: Color(0xFF8CE300), size: 10),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 2. Current Card
                              _buildTelemetryCard(
                                title: 'Current',
                                value: '${current.toStringAsFixed(1)}A',
                                subtitle: current < 0 ? 'Discharging' : (current > 0 ? 'Charging' : 'Idle'),
                                content: SizedBox(
                                  height: 80,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    size: const Size(100, 80),
                                    painter: CurrentDialPainter(current: current),
                                  ),
                                ),
                                footer: const Opacity(
                                  opacity: 0.15,
                                  child: Icon(Icons.flash_on_rounded, color: Color(0xFF151833), size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right Column (Voltage and Temperature)
                        Expanded(
                          child: Column(
                            children: [
                              // 3. Voltage Card
                              _buildTelemetryCard(
                                title: 'Voltage',
                                customHeaderRight: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedVoltageMode,
                                      isDense: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF231B69), size: 12),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Total',
                                          child: Text('Total', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF231B69))),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Cells',
                                          child: Text('Cells', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF231B69))),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedVoltageMode = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                value: '${voltage.toStringAsFixed(1)}v',
                                subtitle: 'Total Voltage',
                                content: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildVoltageChart(selectedBattery),
                                    Positioned(
                                      top: 4,
                                      left: 55,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF231B69),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${voltage.toStringAsFixed(1)}v',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                footer: InkWell(
                                  onTap: () {
                                    // Open cell voltages list
                                    _showCellVoltagesSheet(context, selectedBattery);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1EEFF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          'View Cell Voltages',
                                          style: TextStyle(
                                            color: Color(0xFF231B69),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF231B69), size: 7.5),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 4. Temperature Card
                              _buildTelemetryCard(
                                title: 'Temperature',
                                value: '${temp.toInt()}°c',
                                subtitle: 'BMS Temp',
                                content: SizedBox(
                                  height: 100,
                                  width: double.infinity,
                                  child: Row(
                                    children: [
                                      // Thermometer Visual
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: CustomPaint(
                                                size: const Size(45, 75),
                                                painter: ThermometerPainter(temp: temp),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE2FDF2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Text(
                                                    'Good',
                                                    style: TextStyle(
                                                      color: Color(0xFF15803D),
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(width: 2),
                                                  Icon(Icons.check, color: Color(0xFF15803D), size: 8),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // Stats Card
                                      Expanded(
                                        flex: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1EEFF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildTempStatRow('Min', '${(temp - 6).toInt()}°c'),
                                              _buildTempStatRow('Max', '${(temp + 4).toInt()}°c'),
                                              _buildTempStatRow('Average', '${(temp - 1).toInt()}°c'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── SECONDARY TAB BAR ─────────────────────────────────────
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSubTabItem(0, 'Live Data', Icons.analytics_outlined),
                          _buildSubTabItem(1, 'Alerts', Icons.notifications_active_outlined, badgeCount: 2),
                          _buildSubTabItem(2, 'History', Icons.history_rounded),
                          _buildSubTabItem(3, 'Settings', Icons.settings_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── SUB-TAB DYNAMIC VIEW CONTENT ──────────────────────────
                    _buildSubTabViewContent(selectedBattery, batteryState),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build mini-card summary indicators
  Widget _buildMiniKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required bool hasUnderline,
  }) {
    return Container(
      height: 72,
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
                  // Icon inside circle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFFFCA), // Light lime green
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: const Color(0xFF8CE300), size: 10),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8C93A8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF151833),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (hasUnderline)
            Container(
              height: 3,
              width: double.infinity,
              color: const Color(0xFF8CE300), // Lime green bar indicator
            ),
        ],
      ),
    );
  }

  // Helper to build main telemetry cards
  Widget _buildTelemetryCard({
    required String title,
    Widget? customHeaderRight,
    required String value,
    String? subtitle,
    required Widget content,
    Widget? footer,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF151833),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              customHeaderRight ??
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF8C93A8), size: 9),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF151833),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: Color(0xFF8C93A8),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          content,
          if (footer != null) ...[
            const SizedBox(height: 12),
            Center(child: footer),
          ],
        ],
      ),
    );
  }

  Widget _buildTempStatRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, color: Color(0xFF8C93A8), fontWeight: FontWeight.w500),
        ),
        Text(
          val,
          style: const TextStyle(fontSize: 9.5, color: Color(0xFF231B69), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Voltage FlChart Builder
  Widget _buildVoltageChart(BatteryModel battery) {
    final List<FlSpot> spots = [
      const FlSpot(0, 49.0),
      const FlSpot(4, 50.2),
      const FlSpot(8, 49.6),
      const FlSpot(12, 51.2), // peak
      const FlSpot(16, 50.1),
      const FlSpot(20, 50.7),
      const FlSpot(24, 50.4),
    ];

    return SizedBox(
      height: 70,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 24,
          minY: 46,
          maxY: 54,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('00:00', style: TextStyle(fontSize: 7.5, color: Color(0xFF8C93A8)));
                  if (value == 6) return const Text('06:00', style: TextStyle(fontSize: 7.5, color: Color(0xFF8C93A8)));
                  if (value == 12) return const Text('12:00', style: TextStyle(fontSize: 7.5, color: Color(0xFF8C93A8)));
                  if (value == 18) return const Text('18:00', style: TextStyle(fontSize: 7.5, color: Color(0xFF8C93A8)));
                  if (value == 24) return const Text('24:00', style: TextStyle(fontSize: 7.5, color: Color(0xFF8C93A8)));
                  return const Text('');
                },
                reservedSize: 14,
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF8CE300), // Yellow-green
              barWidth: 1.8,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (spot.y == 51.2) {
                    return FlDotCirclePainter(
                      radius: 3.5,
                      color: const Color(0xFF8CE300),
                      strokeColor: Colors.white,
                      strokeWidth: 1.5,
                    );
                  }
                  return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8CE300).withOpacity(0.20),
                    const Color(0xFF8CE300).withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Secondary sub-tab row buttons builder
  Widget _buildSubTabItem(int index, String label, IconData icon, {int? badgeCount}) {
    final bool isSelected = _selectedSubTabIndex == index;
    final Color activeColor = const Color(0xFF8CE300); // Lime yellow/green accent
    final Color inactiveColor = const Color(0xFF8C93A8);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSubTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(bottom: BorderSide(color: activeColor, width: 2))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF151833) : inactiveColor,
              ),
            ),
            if ((badgeCount ?? 0) > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E1C9F), // Dark purple badge
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Dynamic builder for sub-tab contents
  Widget _buildSubTabViewContent(BatteryModel selectedBattery, BatteryState batteryState) {
    if (_selectedSubTabIndex == 0) {
      // ── LIVE DATA SUB-TAB CONTENT ───────────────────────────────────
      return Column(
        children: [
          // Battery Health List Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE2FDF2), // Light green circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: Color(0xFF15803D), size: 18),
              ),
              title: const Text(
                'Battery Health',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
              ),
              subtitle: Text(
                'SOH: ${selectedBattery.health}%  •  Cycle Count: ${selectedBattery.cycleCount}',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF8C93A8), fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF8C93A8), size: 12),
              onTap: () {
                _showCellVoltagesSheet(context, selectedBattery);
              },
            ),
          ),
          const SizedBox(height: 10),

          // Alerts List Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF7ED), // Light orange circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFEA580C), size: 18),
              ),
              title: const Text(
                'Alerts (1)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SizedBox(height: 2),
                  Text(
                    'High Cell Temperature',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Cell 07 temperature is above threshold.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF8C93A8)),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '10:30 AM',
                    style: TextStyle(fontSize: 9.5, color: Color(0xFF8C93A8), fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF8C93A8), size: 12),
                ],
              ),
              onTap: () {
                setState(() => _selectedSubTabIndex = 1); // switch to Alerts tab
              },
            ),
          ),
        ],
      );
    } else if (_selectedSubTabIndex == 1) {
      // ── ALERTS SUB-TAB CONTENT ───────────────────────────────────────
      // Compile active alerts dynamically from Riverpod states
      final List<BmsAlert> alerts = [];
      
      // Compile critical thresholds from selected battery
      if (selectedBattery.temperature >= 45.0) {
        alerts.add(BmsAlert(
          title: 'High Core Temperature',
          message: 'BMS temperature is ${selectedBattery.temperature}°C. Limit swap/charge.',
          isCritical: true,
          time: 'Just now',
        ));
      }
      if (selectedBattery.soc <= 20.0) {
        alerts.add(BmsAlert(
          title: 'Low State of Charge',
          message: 'BMS capacity drops to ${selectedBattery.soc}%. Recharge immediately.',
          isCritical: true,
          time: 'Just now',
        ));
      }
      
      // Default mock alerts if no critical thresholds met, matching screenshot SOH
      if (alerts.isEmpty) {
        alerts.addAll([
          BmsAlert(
            title: 'High Cell Temperature',
            message: 'Cell 07 temperature is above threshold (44.5°C). Monitor active load.',
            isCritical: false,
            time: '10:30 AM',
          ),
          BmsAlert(
            title: 'Voltage Balance Deviation',
            message: 'Cell 04 and Cell 09 voltage delta exceeded 120mV.',
            isCritical: false,
            time: 'Yesterday',
          ),
        ]);
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final a = alerts[index];
          final Color iconBg = a.isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED);
          final Color iconColor = a.isCritical ? const Color(0xFFEF4444) : const Color(0xFFEA580C);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: iconColor, size: 18),
              ),
              title: Text(
                a.title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
              ),
              subtitle: Text(
                a.message,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
              trailing: Text(
                a.time,
                style: const TextStyle(fontSize: 9, color: Color(0xFF8C93A8), fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      );
    } else if (_selectedSubTabIndex == 2) {
      // ── HISTORY SUB-TAB CONTENT ──────────────────────────────────────
      final logs = batteryState.recentActivity.isNotEmpty
          ? batteryState.recentActivity
          : ['BMS connected successfully|10:30 AM', 'Charging initialized|10:15 AM', 'Temperature spike log cell 7|09:44 AM'];

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final parts = logs[index].split('|');
          final msg = parts[0];
          final time = parts.length > 1 ? parts[1] : '';
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              children: [
                const Icon(Icons.circle, color: Color(0xFFCCFF00), size: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    msg,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF151833), fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF8C93A8), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // ── SETTINGS SUB-TAB CONTENT ─────────────────────────────────────
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          children: [
            ListTile(
              title: const Text('BMS Rename', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              subtitle: const Text('Change local display name', style: TextStyle(fontSize: 10.5)),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () {
                _showRenameDialog(context, selectedBattery);
              },
            ),
            const Divider(color: Color(0xFFF1F5F9)),
            ListTile(
              title: const Text('Hardware Config Details', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              subtitle: Text(
                'FW: ${selectedBattery.firmwareVersion.isNotEmpty ? selectedBattery.firmwareVersion : 'v1.02'}  •  HW: ${selectedBattery.hardwareVersion.isNotEmpty ? selectedBattery.hardwareVersion : 'Daly-BMS-V4'}',
                style: const TextStyle(fontSize: 10.5),
              ),
              trailing: const Icon(Icons.info_outline, size: 18),
            ),
          ],
        ),
      );
    }
  }

  // Dialog to rename selected battery
  void _showRenameDialog(BuildContext context, BatteryModel battery) {
    final controller = TextEditingController(text: battery.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename BMS Device'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(batteryProvider.notifier).renameBattery(battery.id, controller.text);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('BMS renamed to ${controller.text}')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Bottom Sheet modal for cell voltages detail (mockup feature)
  void _showCellVoltagesSheet(BuildContext context, BatteryModel battery) {
    final cells = battery.cellVoltages.isNotEmpty
        ? battery.cellVoltages
        : [3938, 3940, 3935, 3939, 3942, 3941, 3937, 3939, 3940, 3938, 3939, 3941, 3938, 3940, 3936, 3939];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cell Voltages (${cells.length} Cells)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: cells.length,
                  itemBuilder: (context, index) {
                    final mv = cells[index];
                    final voltStr = (mv / 1000.0).toStringAsFixed(3);
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FD),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Cell ${index + 1}',
                            style: const TextStyle(fontSize: 9, color: Color(0xFF8C93A8), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${voltStr}v',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF151833)),
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
      },
    );
  }
}

// ── CUSTOM PAINTERS ────────────────────────────────────────────────────────

// Circular Progress Ring for Top Card
class CircularSocPainter extends CustomPainter {
  final double soc;
  final Color progressColor;
  CircularSocPainter({required this.soc, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    const strokeWidth = 8.0;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Active arc
    final activePaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * (soc / 100.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircularSocPainter oldDelegate) =>
      oldDelegate.soc != soc || oldDelegate.progressColor != progressColor;
}

// 270-degree arc gauge for SOC Card
class SemiCircularSocPainter extends CustomPainter {
  final double soc;
  final Color progressColor;
  SemiCircularSocPainter({required this.soc, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final radius = min(size.width, size.height) / 2 - 10;
    const strokeWidth = 10.0;

    const startAngle = 135 * pi / 180;
    const sweepAngle = 270 * pi / 180;

    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final activePaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * (soc / 100.0),
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant SemiCircularSocPainter oldDelegate) =>
      oldDelegate.soc != soc || oldDelegate.progressColor != progressColor;
}

// Dial Gauge for Current (-100 to 100)
class CurrentDialPainter extends CustomPainter {
  final double current;
  CurrentDialPainter({required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 18);
    final radius = size.width / 2 - 14;

    // Draw the background arc
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // Draw ticks
    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.8;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final List<double> ticks = [-100, -50, 0, 50, 100];
    for (var t in ticks) {
      final ratio = (t + 100) / 200.0;
      final angle = pi + ratio * pi;

      final outerPt = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final innerPt = Offset(
        center.dx + (radius - 6) * cos(angle),
        center.dy + (radius - 6) * sin(angle),
      );
      canvas.drawLine(outerPt, innerPt, tickPaint);

      // Draw tick labels
      textPainter.text = TextSpan(
        text: '${t.toInt()}',
        style: const TextStyle(
          color: Color(0xFF8C93A8),
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();

      final textRadius = radius - 15;
      final textPt = Offset(
        center.dx + textRadius * cos(angle) - textPainter.width / 2,
        center.dy + textRadius * sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, textPt);
    }

    // Draw needle
    final clampedCurrent = current.clamp(-100.0, 100.0);
    final currentRatio = (clampedCurrent + 100) / 200.0;
    final needleAngle = pi + currentRatio * pi;

    final needlePaint = Paint()
      ..color = const Color(0xFF2E1C9F)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final needleLength = radius - 10;
    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );
    canvas.drawLine(center, needleEnd, needlePaint);

    // Hub
    final hubPaint = Paint()..color = const Color(0xFF2E1C9F);
    canvas.drawCircle(center, 5.0, hubPaint);
    final hubInnerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 2.0, hubInnerPaint);
  }

  @override
  bool shouldRepaint(covariant CurrentDialPainter oldDelegate) =>
      oldDelegate.current != current;
}

// Thermometer visual indicator
class ThermometerPainter extends CustomPainter {
  final double temp;
  ThermometerPainter({required this.temp});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double cx = width / 2;

    const double bulbRadius = 8.0;
    final Offset bulbCenter = Offset(cx, height - bulbRadius - 2);

    const double stemTop = 8.0;
    final double stemBottom = bulbCenter.dy - bulbRadius + 2;
    const double stemWidth = 6.0;
    const double rx = stemWidth / 2;

    // Stem & bulb background
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - rx, stemTop, cx + rx, stemBottom),
        const Radius.circular(rx),
      ),
      bgPaint,
    );
    canvas.drawCircle(bulbCenter, bulbRadius, bgPaint);

    // Fill fluid level
    final double clampedTemp = temp.clamp(0.0, 60.0);
    final double tempRatio = clampedTemp / 60.0;
    final double fluidTop = stemBottom - (stemBottom - stemTop - rx) * tempRatio;

    final fluidPaint = Paint()
      ..color = const Color(0xFF8CE300) // Lime-green fluid
      ..style = PaintingStyle.fill;

    if (fluidTop < stemBottom) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(cx - rx + 1.0, fluidTop, cx + rx - 1.0, stemBottom),
          const Radius.circular(rx - 1.0),
        ),
        fluidPaint,
      );
    }
    canvas.drawCircle(bulbCenter, bulbRadius - 1.0, fluidPaint);

    // Draw scale ticks on the right side
    final tickPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final List<double> ticks = [0, 20, 40, 60];
    for (var t in ticks) {
      final ratio = t / 60.0;
      final y = stemBottom - (stemBottom - stemTop - rx) * ratio;

      canvas.drawLine(Offset(cx + rx + 2, y), Offset(cx + rx + 6, y), tickPaint);

      textPainter.text = TextSpan(
        text: '${t.toInt()}°',
        style: const TextStyle(
          color: Color(0xFF8C93A8),
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx + rx + 8, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant ThermometerPainter oldDelegate) =>
      oldDelegate.temp != temp;
}

// Mini Class helper for BmsAlert listings
class BmsAlert {
  final String title;
  final String message;
  final bool isCritical;
  final String time;

  BmsAlert({
    required this.title,
    required this.message,
    required this.isCritical,
    required this.time,
  });
}
