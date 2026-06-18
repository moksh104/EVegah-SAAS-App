import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'unlocking_screen.dart';

class BluetoothUnlockScreen extends StatefulWidget {
  const BluetoothUnlockScreen({super.key});

  @override
  State<BluetoothUnlockScreen> createState() => _BluetoothUnlockScreenState();
}

class _BluetoothUnlockScreenState extends State<BluetoothUnlockScreen> {
  List<ScanResult> devices = [];
  bool scanning = false;

@override
  void initState() {
    super.initState();
    
    // 🚨 THE FIX: Wait for the screen to render its first frame BEFORE scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startScan();
    });
  }

  // 🚨 ADDED: Cleanup when the user leaves the screen
  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> startScan() async {
    setState(() {
      scanning = true;
      devices.clear();
    });

    try {
      // 1. Start listening to results
      FlutterBluePlus.scanResults.listen((results) {
        if (mounted) { // 🚨 SAFETY CHECK
          setState(() {
            devices = results;
          });
        }
      });

      // 2. Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      
    } catch (e) {
      // 🚨 SAFETY NET: Catch errors if Bluetooth is OFF or permissions denied
      debugPrint("Bluetooth Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ensure Bluetooth is ON and permissions are granted."), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 3. Ensure UI updates safely after scanning stops
      if (mounted) { // 🚨 SAFETY CHECK
        setState(() {
          scanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Bluetooth Unlock 📶"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // STATUS CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  scanning ? Icons.bluetooth_searching : Icons.bluetooth,
                  color: Colors.green,
                  size: 40,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scanning ? "Searching Nearby EVs..." : "Nearby EVs Found",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text("Bluetooth EV unlock system"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

         // DEVICE LIST
          Expanded(
            child: devices.isEmpty
                ? const Center(child: Text("No Nearby EV Found"))
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index].device;
                      
                      // 🚨 FALLBACK: Some devices don't broadcast a name
                      String deviceName = device.platformName.isNotEmpty 
                          ? device.platformName 
                          : "Unknown EV Module";

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Icon(Icons.electric_bike, color: Colors.white),
                          ),
                          title: Text(deviceName, overflow: TextOverflow.ellipsis),
                          subtitle: Text(device.remoteId.toString(), overflow: TextOverflow.ellipsis),
                          
                          // 🚨 Wrapped button in SizedBox to fix the layout crash
                          trailing: SizedBox(
                            width: 85,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () async {
                                // 🚨 CRITICAL: Stop scanning BEFORE opening the new screen
                                await FlutterBluePlus.stopScan(); 
                                
                                if (!mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UnlockingScreen(
                                      vehicleId: device.remoteId.toString(),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Unlock", style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ); // <-- The semicolon that was causing the issue is now safely closing the Container!
                    },
                  ),
          ),

          // RESCAN BUTTON
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                // 🚨 Disable button while already scanning to prevent overlapping scans
                onPressed: scanning ? null : startScan, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  "Scan Again",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}