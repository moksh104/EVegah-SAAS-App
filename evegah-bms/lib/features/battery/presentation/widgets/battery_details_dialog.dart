import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/battery_model.dart';
import '../providers/battery_provider.dart';

class BatteryDetailsDialog extends ConsumerStatefulWidget {
  final BatteryModel battery;
  const BatteryDetailsDialog({super.key, required this.battery});

  @override
  ConsumerState<BatteryDetailsDialog> createState() =>
      _BatteryDetailsDialogState();
}

class _BatteryDetailsDialogState extends ConsumerState<BatteryDetailsDialog>
    with SingleTickerProviderStateMixin {
  String _selectedChart = 'SoC';
  bool _showRawLog = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getBatteryColor(double soc) {
    if (soc >= 50) return const Color(0xFF22C55E);
    if (soc >= 20) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildChart(BatteryModel battery) {
    List<double> history = [];
    Color lineColor = Colors.green;
    String yLabel = '';

    switch (_selectedChart) {
      case 'SoC':
        history = battery.socHistory;
        lineColor = const Color(0xFF22C55E);
        yLabel = '%';
        break;
      case 'Temp':
        history = battery.tempHistory;
        lineColor = Colors.orange;
        yLabel = '°C';
        break;
      case 'Volt':
        history = battery.voltHistory;
        lineColor = Colors.blue;
        yLabel = 'V';
        break;
      case 'Current':
        history = battery.currentHistory;
        lineColor = Colors.purple;
        yLabel = 'A';
        break;
    }

    if (history.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Collecting telemetry history...',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i]));
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['SoC', 'Temp', 'Volt', 'Current'].map((type) {
            final isSelected = _selectedChart == type;
            Color typeColor = Colors.green;
            if (type == 'Temp') typeColor = Colors.orange;
            if (type == 'Volt') typeColor = Colors.blue;
            if (type == 'Current') typeColor = Colors.purple;

            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              selectedColor: typeColor.withOpacity(0.15),
              checkmarkColor: typeColor,
              labelStyle: TextStyle(
                color: isSelected ? typeColor : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedChart = type);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          height: 130,
          padding: const EdgeInsets.only(right: 16, left: 6, top: 8, bottom: 6),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 18,
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        't-${(history.length - 1 - value.toInt()) * 2}s',
                        style: const TextStyle(color: Colors.grey, fontSize: 8),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(0)}$yLabel',
                        style: const TextStyle(color: Colors.grey, fontSize: 8),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: history.length > 1 ? (history.length - 1).toDouble() : 5.0,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withOpacity(0.06),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Raw BLE data log panel
  Widget _buildRawLog(BatteryModel battery, BatteryState batteryState) {
    final logs = batteryState.rawDataLog[battery.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: logs.isNotEmpty
                        ? const Color(0xFF22C55E)
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  logs.isNotEmpty
                      ? 'Receiving data (${logs.length} packets)'
                      : 'No data received yet',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: logs.isNotEmpty
                        ? const Color(0xFF22C55E)
                        : Colors.orange,
                  ),
                ),
              ],
            ),
            if (logs.isNotEmpty)
              GestureDetector(
                onTap: () {
                  final all = logs.join('\n');
                  Clipboard.setData(ClipboardData(text: all));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Raw log copied to clipboard!'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF312E81).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 12, color: Color(0xFF312E81)),
                      SizedBox(width: 4),
                      Text(
                        'Copy All',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF312E81),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '⚠️  No BLE data received from BMS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'This means either:\n'
                  '1. Write characteristic is wrong (BMS not responding)\n'
                  '2. Notify characteristic was not enabled\n'
                  '3. BMS requires a different command to wake up\n\n'
                  'Check the ADB/flutter console for debug logs.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                ),
              ],
            ),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: logs.length,
              itemBuilder: (ctx, i) {
                final entry = logs[i];
                // Highlight D2 03 (valid Modbus response) in green
                final isModbus =
                    entry.contains('d203') || entry.contains('D203');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    entry,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: isModbus
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 8),
        // Hint
        const Text(
          '🟢 Green = valid Modbus response  ⚪ Grey = other/unknown data',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final batteryState = ref.watch(batteryProvider);
    final battery = batteryState.connectedBatteries.firstWhere(
      (b) => b.id == widget.battery.id,
      orElse: () => widget.battery,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFF8F9FD),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: MediaQuery.of(context).size.width * 0.98,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          battery.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF312E81),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          battery.id,
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ─────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                indicator: BoxDecoration(
                  color: const Color(0xFF312E81),
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: '📊  Live Data'),
                  Tab(text: '🔍  Raw BLE Log'),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ── Tab Content ─────────────────────────────────────────────────
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 1: Live Data ─────────────────────────────────────
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Telemetry grid
                        _buildTelemetryGrid(battery),
                        const SizedBox(height: 12),
                        _buildCycleAndSignalCard(battery),
                        const SizedBox(height: 12),
                        _buildBatteryInfoCard(battery),
                        const SizedBox(height: 16),
                        const Text(
                          'Live Telemetry Charts',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF312E81),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: _buildChart(battery),
                        ),
                        const SizedBox(height: 16),
                        // Disconnect button
                        ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(batteryProvider.notifier)
                                .disconnectDevice(battery.id);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Disconnect Battery',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Tab 2: Raw BLE Log ────────────────────────────────────
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: _buildRawLog(battery, batteryState),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryGrid(BatteryModel battery) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        _telemetryCard(
          icon: Icons.battery_charging_full,
          value: '${battery.soc.toStringAsFixed(1)}%',
          label: 'State of Charge',
          description: 'Remaining Capacity',
          color: _getBatteryColor(battery.soc),
        ),
        _telemetryCard(
          icon: Icons.thermostat,
          value: '${battery.temperature.toStringAsFixed(1)}°C',
          label: 'Temperature',
          description: 'BMS Core Temp',
          color: Colors.orange,
        ),
        _telemetryCard(
          icon: Icons.electric_bolt,
          value: '${battery.voltage.toStringAsFixed(1)} V',
          label: 'Voltage',
          description: 'Main Bus Voltage',
          color: Colors.blue,
        ),
        _telemetryCard(
          icon: Icons.flash_on,
          value:
              '${battery.current >= 0 ? "+" : ""}${battery.current.toStringAsFixed(1)} A',
          label: 'Current (Amps)',
          description: battery.current >= 0.05
              ? 'Charging Inflow'
              : (battery.current <= -0.05 ? 'Discharging' : 'Idle'),
          color: battery.current >= 0.05 ? Colors.teal : Colors.indigo,
        ),
      ],
    );
  }

  Widget _telemetryCard({
    required IconData icon,
    required String value,
    required String label,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            description,
            style: const TextStyle(
              fontSize: 8.5,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleAndSignalCard(BatteryModel battery) {
    final rssi = battery.rssi;
    final color = rssi >= -65
        ? Colors.green
        : (rssi >= -80 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoSubTile(
                Icons.loop,
                'Cycles',
                '${battery.cycleCount}',
                Colors.indigo,
              ),
              _infoSubTile(
                Icons.favorite_border,
                'SOH',
                '${battery.health}%',
                Colors.teal,
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Icon(Icons.signal_cellular_alt, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Signal Strength',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$rssi dBm',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                rssi >= -65 ? 'Excellent' : (rssi >= -80 ? 'Good' : 'Weak'),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoSubTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryInfoCard(BatteryModel battery) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF312E81), size: 18),
              SizedBox(width: 8),
              Text(
                'BMS Specifications',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF312E81),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _infoRow(
            'Hardware Model',
            battery.hardwareVersion.isNotEmpty
                ? battery.hardwareVersion
                : 'Detecting...',
          ),
          const SizedBox(height: 8),
          _infoRow(
            'Firmware Version',
            battery.firmwareVersion.isNotEmpty
                ? battery.firmwareVersion
                : 'Detecting...',
          ),
          const SizedBox(height: 8),
          _infoRow(
            'Manufacture Date',
            battery.manufactureDate.isNotEmpty
                ? battery.manufactureDate
                : 'Detecting...',
          ),
          const SizedBox(height: 8),
          _infoRow(
            'Cells in Series',
            battery.cellsInSeries > 0
                ? '${battery.cellsInSeries}S'
                : 'Detecting...',
          ),
          const SizedBox(height: 8),
          _infoRow(
            'Design Capacity',
            battery.designCapacity > 0
                ? '${battery.designCapacity} Ah'
                : 'Detecting...',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
