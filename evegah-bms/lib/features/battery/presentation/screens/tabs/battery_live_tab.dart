import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../../../data/models/battery_model.dart';
import '../../providers/battery_provider.dart';

class BatteryLiveTab extends ConsumerStatefulWidget {
  final bool isVisible;
  const BatteryLiveTab({super.key, required this.isVisible});

  @override
  ConsumerState<BatteryLiveTab> createState() => _BatteryLiveTabState();
}

class _BatteryLiveTabState extends ConsumerState<BatteryLiveTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _secondsUntilUpdate = 2;
  Timer? _countdownTimer;
  String? _selectedBatteryId; // Track user selected battery

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isVisible) {
      _pulseController.repeat(reverse: true);
      _startCountdownTimer();
    }
  }

  @override
  void didUpdateWidget(covariant BatteryLiveTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _pulseController.repeat(reverse: true);
        _startCountdownTimer();
      } else {
        _pulseController.stop();
        _countdownTimer?.cancel();
      }
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!widget.isVisible) return; // Prevent tick when hidden
      setState(() {
        if (_secondsUntilUpdate <= 1) {
          _secondsUntilUpdate = 2;
        } else {
          _secondsUntilUpdate--;
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batteryState = ref.watch(batteryProvider);
    final allConnected = batteryState.connectedBatteries
        .where((b) => b.status == BatteryStatus.connected)
        .toList();

    // Map to BGS names for consistency with mockup screenshots
    final displayConnected = allConnected.map((b) {
      return b.copyWith(name: b.name.replaceAll('BOS', 'BGS'));
    }).toList();

    // Fallbacks if no batteries are connected - empty list by default
    final List<BatteryModel> activeList = displayConnected;

    // Determine currently selected battery
    final String selectedId =
        _selectedBatteryId ??
        (activeList.isNotEmpty ? activeList.first.id : '');
    final selectedBattery = activeList.isNotEmpty
        ? activeList.firstWhere(
            (b) => b.id == selectedId,
            orElse: () => activeList.first,
          )
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: Column(
          children: [
            // Header panel matching Screenshot 3
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu, color: Color(0xFF151833), size: 24),
                  Image.asset(
                    'assets/logo.png',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'evegah',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF231B69),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: const [
                      Icon(Icons.bluetooth, color: Color(0xFF151833), size: 22),
                      SizedBox(width: 14),
                      Icon(Icons.more_vert, color: Color(0xFF151833), size: 22),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Dropdown selector row matching mockup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Battery Analytics',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF151833),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Deep insights and diagnostics',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8C93A8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Dark styled Dropdown Selector matching mockup
                        if (activeList.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1A47),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedId,
                                dropdownColor: const Color(0xFF1E1A47),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                items: activeList.map((b) {
                                  return DropdownMenuItem<String>(
                                    value: b.id,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.shield_outlined,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(b.name),
                                      ],
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
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (selectedBattery != null) ...[
                      // State of Charge Card
                      _buildStateOfChargeCard(selectedBattery),
                      const SizedBox(height: 16),

                      // Telemetry Row (Voltage, Current, Temp)
                      _buildTelemetryRow(selectedBattery),
                      const SizedBox(height: 16),

                      // Soh & Range Row
                      _buildSohAndRangeRow(selectedBattery),
                      const SizedBox(height: 16),

                      // Live Trends Chart
                      _buildLiveTrendsCard(selectedBattery),
                      const SizedBox(height: 16),

                      // Bottom Diagnostics row
                      _buildDiagnosticsRow(),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildEmptyState(context),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Update bar with blinking green indicator
            _buildFooterUpdateBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateOfChargeCard(BatteryModel battery) {
    Color fillStatusColor = const Color(0xFF22C55E);
    if (battery.soc < 30) {
      fillStatusColor = const Color(0xFFEF4444);
    } else if (battery.soc < 75) {
      fillStatusColor = const Color(0xFFF59E0B);
    }

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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Battery Cylinder Graphic
          Container(
            width: 50,
            height: 80,
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 32,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Positioned(
                  top: 5,
                  child: Container(
                    width: 12,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF94A3B8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(2),
                        topRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 13,
                  child: Container(
                    width: 24,
                    height: 42 * (battery.soc / 100),
                    decoration: BoxDecoration(
                      color: fillStatusColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // SOC Text details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${battery.soc.toStringAsFixed(battery.soc % 1 == 0 ? 0 : 1)}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Text(
                  'State of Charge',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8C93A8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2FDF2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Healthy',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right indicators
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2FDF2),
                  borderRadius: BorderRadius.circular(8),
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
                      'Connected',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.show_chart, color: Color(0xFF22C55E), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Last updated just now',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF8C93A8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(BatteryModel battery) {
    final voltData = battery.voltHistory.isNotEmpty
        ? battery.voltHistory
        : [52.0, 52.1, 52.0, 52.2, 52.1, 52.0];
    final currentData = battery.currentHistory.isNotEmpty
        ? battery.currentHistory
        : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final tempData = battery.tempHistory.isNotEmpty
        ? battery.tempHistory
        : [25.0, 25.0, 25.1, 25.0, 25.0, 25.0];

    return Row(
      children: [
        Expanded(
          child: _buildMiniMetricCard(
            title: 'Voltage',
            value: '${battery.voltage.toStringAsFixed(1)} V',
            icon: Icons.flash_on,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            chartColor: const Color(0xFF8B5CF6),
            history: voltData,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniMetricCard(
            title: 'Current',
            value: '${battery.current.toStringAsFixed(1)} A',
            icon: Icons.adjust,
            iconColor: const Color(0xFF22C55E),
            bgColor: const Color(0xFFF0FDF4),
            chartColor: const Color(0xFF22C55E),
            history: currentData,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniMetricCard(
            title: 'Temperature',
            value: '${battery.temperature.toInt()} °C',
            icon: Icons.thermostat,
            iconColor: const Color(0xFF6366F1),
            bgColor: const Color(0xFFEEF2FF),
            chartColor: const Color(0xFF6366F1),
            history: tempData,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color chartColor,
    required List<double> history,
  }) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i]));
    }
    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 12),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF8C93A8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 25,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 5.0,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 1.8,
                    color: chartColor,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSohAndRangeRow(BatteryModel battery) {
    final int estimatedRange = (battery.soc * 0.5).toInt();

    return Row(
      children: [
        // Health Score Card
        Expanded(
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFF22C55E),
                        size: 12,
                      ),
                    ),
                    const Text(
                      'Health Score',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF8C93A8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${battery.health}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Text(
                      ' /100',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8C93A8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: battery.health / 100.0,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF22C55E),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2FDF2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Excellent',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Estimated Range Card
        Expanded(
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            ),
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Opacity(
                    opacity: 0.05,
                    child: const Icon(
                      Icons.directions_bike,
                      size: 60,
                      color: Colors.black,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF6366F1),
                            size: 12,
                          ),
                        ),
                        const Text(
                          'Estimated Range',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF8C93A8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$estimatedRange km',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Eco Mode',
                        style: TextStyle(
                          fontSize: 8.5,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveTrendsCard(BatteryModel battery) {
    final voltData = battery.voltHistory.isNotEmpty
        ? battery.voltHistory
        : [52.0, 52.1, 52.0, 52.2, 52.1, 52.0];
    final tempData = battery.tempHistory.isNotEmpty
        ? battery.tempHistory
        : [25.0, 25.0, 25.1, 25.0, 25.0, 25.0];

    final List<FlSpot> voltSpots = [];
    final List<FlSpot> tempSpots = [];

    for (int i = 0; i < voltData.length; i++) {
      voltSpots.add(FlSpot(i.toDouble(), voltData[i]));
    }
    if (voltSpots.isEmpty) voltSpots.add(const FlSpot(0, 52));

    for (int i = 0; i < tempData.length; i++) {
      // Normalize Temp (10 to 40) onto Volt scale (44 to 56)
      final double norm = ((tempData[i] - 10.0) / 30.0) * 12.0 + 44.0;
      tempSpots.add(FlSpot(i.toDouble(), norm));
    }
    if (tempSpots.isEmpty) tempSpots.add(const FlSpot(0, 50));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Trends (Last 60 Seconds)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: const [
                        Text(
                          '60 Seconds',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.fullscreen,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Legends
          Row(
            children: [
              _chartLegendItem(const Color(0xFF6366F1), 'Voltage (V)'),
              const SizedBox(width: 14),
              _chartLegendItem(const Color(0xFF22C55E), 'Temperature (°C)'),
            ],
          ),
          const SizedBox(height: 16),
          // Dual Axis Chart
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: voltData.length > 1
                    ? (voltData.length - 1).toDouble()
                    : 5.0,
                minY: 44,
                maxY: 56,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (value, meta) {
                        final int val = value.toInt();
                        if (val == 0)
                          return const Text(
                            '-60s',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xFF94A3B8),
                            ),
                          );
                        if (val == (voltData.length ~/ 4))
                          return const Text(
                            '-45s',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xFF94A3B8),
                            ),
                          );
                        if (val == (voltData.length ~/ 2))
                          return const Text(
                            '-30s',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xFF94A3B8),
                            ),
                          );
                        if (val == (voltData.length * 3 ~/ 4))
                          return const Text(
                            '-15s',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xFF94A3B8),
                            ),
                          );
                        if (val == (voltData.length - 1))
                          return const Text(
                            'Now',
                            style: TextStyle(
                              fontSize: 8,
                              color: Color(0xFF94A3B8),
                            ),
                          );
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xFF94A3B8),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final double tempVal =
                            ((value - 44.0) / 12.0) * 30.0 + 10.0;
                        return Text(
                          tempVal.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 8,
                            color: Color(0xFF94A3B8),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: voltSpots,
                    isCurved: true,
                    barWidth: 2,
                    color: const Color(0xFF6366F1),
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: tempSpots,
                    isCurved: true,
                    barWidth: 2,
                    color: const Color(0xFF22C55E),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildDiagnosticItem(
            icon: Icons.verified_user,
            iconColor: const Color(0xFF22C55E),
            title: 'No critical alerts',
            subtitle: 'All systems normal',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildDiagnosticItem(
            icon: Icons.autorenew,
            iconColor: const Color(0xFF6366F1),
            title: 'Auto refresh',
            subtitle: 'every 2s',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildDiagnosticItem(
            icon: Icons.battery_charging_full,
            iconColor: const Color(0xFF22C55E),
            title: 'Battery healthy',
            subtitle: 'Keep it up!',
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 8, color: Color(0xFF8C93A8)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterUpdateBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 14, color: Color(0xFF231B69)),
              SizedBox(width: 6),
              Text(
                'Data is updated every 2 seconds',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF231B69),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Next update in ${_secondsUntilUpdate}s',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pulseController.value,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF231B69).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth_disabled,
              size: 48,
              color: Color(0xFF231B69),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Batteries Connected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151833),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect to a smart battery in the Scanner tab to begin live monitoring.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8C93A8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
