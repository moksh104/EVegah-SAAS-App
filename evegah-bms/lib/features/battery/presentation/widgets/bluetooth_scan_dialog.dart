import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/battery_provider.dart';

class BluetoothScanDialog extends ConsumerStatefulWidget {
  const BluetoothScanDialog({super.key});

  @override
  ConsumerState<BluetoothScanDialog> createState() =>
      _BluetoothScanDialogState();
}

class _BluetoothScanDialogState extends ConsumerState<BluetoothScanDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  final Set<String> _selectedDeviceIds = {};

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start scanning on opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(batteryProvider.notifier).startScan();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    // Stop scanning on close
    ref.read(batteryProvider.notifier).stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batteryState = ref.watch(batteryProvider);
    final notifier = ref.read(batteryProvider.notifier);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan Batteries',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F4C81),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            // Radar Animation / Scanning Status
            if (batteryState.isScanning) ...[
              const SizedBox(height: 12),
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: RadarRipplePainter(_radarController.value),
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F4C81),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bluetooth_searching,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Searching for nearby smart batteries...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => notifier.startScan(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Error Message Banner
            if (batteryState.errorMessage.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        batteryState.errorMessage,
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: () => notifier.clearErrorMessage(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Discovered Devices Section
            const Text(
              'Discovered Devices',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: batteryState.scannedDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_disabled,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            batteryState.isScanning
                                ? 'No smart batteries found yet.'
                                : 'Scanning stopped. Start scan to search.',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: batteryState.scannedDevices.length,
                      itemBuilder: (context, index) {
                        final result = batteryState.scannedDevices[index];
                        final device = result.device;
                        final name = device.platformName.isNotEmpty
                            ? device.platformName
                            : 'Unknown Device';
                        final id = device.remoteId.str;
                        final isSelected = _selectedDeviceIds.contains(id);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: CheckboxListTile(
                            activeColor: const Color(0xFF0F4C81),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              id,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                            secondary: Icon(
                              Icons.battery_std,
                              color: _getSignalColor(result.rssi),
                            ),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedDeviceIds.add(id);
                                } else {
                                  _selectedDeviceIds.remove(id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                // Add Simulated Option for Testing
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showAddSimulatedDialog(context, notifier);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00A896),
                      side: const BorderSide(color: Color(0xFF00A896)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Simulate Battery',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedDeviceIds.isEmpty
                        ? null
                        : () async {
                            final selectedDevices = batteryState.scannedDevices
                                .where(
                                  (r) => _selectedDeviceIds.contains(
                                    r.device.remoteId.str,
                                  ),
                                )
                                .map((r) => r.device)
                                .toList();

                            Navigator.of(context).pop();

                            // Trigger connections sequentially
                            for (var device in selectedDevices) {
                              await notifier.connectToDevice(device);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _selectedDeviceIds.isEmpty
                          ? 'Select Devices'
                          : 'Connect (${_selectedDeviceIds.length})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -60) return Colors.green;
    if (rssi >= -75) return Colors.orange;
    return Colors.red;
  }

  void _showAddSimulatedDialog(BuildContext context, BatteryNotifier notifier) {
    String batteryName =
        'BOS00${ref.read(batteryProvider).connectedBatteries.length + 1}';
    int soc = 75;
    double temp = 30.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Simulated Battery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Battery Name'),
                controller: TextEditingController(text: batteryName),
                onChanged: (val) => batteryName = val,
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setStateSlider) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('State of Charge: $soc%'),
                      Slider(
                        value: soc.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        activeColor: const Color(0xFF00A896),
                        onChanged: (val) {
                          setStateSlider(() {
                            soc = val.toInt();
                          });
                        },
                      ),
                      Text('Temperature: ${temp.toStringAsFixed(1)}°C'),
                      Slider(
                        value: temp,
                        min: 15,
                        max: 45,
                        divisions: 60,
                        activeColor: Colors.orange,
                        onChanged: (val) {
                          setStateSlider(() {
                            temp = val;
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                notifier.addSimulatedBattery(batteryName, soc.toDouble(), temp);
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Also close scanning dialog
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C81),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class RadarRipplePainter extends CustomPainter {
  final double animationValue;
  RadarRipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    for (int i = 3; i >= 0; i--) {
      final progress = (animationValue + i / 4.0) % 1.0;
      final radius = maxRadius * progress;
      final opacity = (1.0 - progress) * 0.35;
      final paint = Paint()
        ..color = const Color(0xFF0F4C81).withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
