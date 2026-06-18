import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // 🚨 Added for real token
import 'unlocking_screen.dart';
import 'package:evegah_rider_app/core/constants/app_constants.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  late AnimationController animationController;
  late Animation<double> animation;
  
  bool flashOn = false;
  bool scanned = false;
  bool isProcessingApi = false;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    animation = Tween<double>(begin: 0, end: 250).animate(animationController);
  }

  @override
  void dispose() {
    controller.dispose();
    animationController.dispose();
    super.dispose();
  }

  // 🚨 THE FIXED API INTEGRATION
  Future<void> _verifyAndUnlock(String code, {required bool isManual}) async {
    // 1. MAGIC TEST BYPASS
    if (code.toUpperCase() == "TEST123") {
      Navigator.pop(context); // Close dialog or bottom sheet
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UnlockingScreen(vehicleId: "TEST123")),
      );
      return;
    }

    setState(() {
      isProcessingApi = true;
    });

    try {
      // 🚨 GET THE REAL TOKEN
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');
      
      if (token == null || token.isEmpty) throw Exception("User not logged in");

      // 2. CALL THE REAL API (Fixed URL spelling!)
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/qrDecrypted?access_token=$token'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "qrString": isManual ? null : code,
          "userId": 0, // Keep 0 if backend handles it via token
          "lockNumber": isManual ? code : null
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // 3. EXTRACT THE REAL LOCK NUMBER FROM SERVER
        if (decoded['data'] != null && decoded['data'].isNotEmpty) {
          final realLockNumber = decoded['data'][0]['lockNumber'];
          
          if (!mounted) return;
          
          // If coming from manual entry, pop the bottom sheet
          if (isManual) Navigator.pop(context); 
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UnlockingScreen(vehicleId: realLockNumber.toString())),
          );
        } else {
          throw Exception("Vehicle not found");
        }
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Vehicle QR or ID. Please try again."), backgroundColor: Colors.red),
      );
      setState(() {
        scanned = false; // Allow them to scan again
      });
    } finally {
      if (mounted) {
        setState(() {
          isProcessingApi = false;
        });
      }
    }
  }

  void onDetectBarcode(BarcodeCapture capture) {
    if (scanned || isProcessingApi) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String code = barcode.rawValue ?? "";
      if (code.isNotEmpty) {
        setState(() {
          scanned = true;
        });

        // Show confirmation dialog before hitting API
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Vehicle Found"),
              content: const Text("Would you like to unlock this vehicle?"),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      scanned = false;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    await _verifyAndUnlock(code, isManual: false);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Unlock", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: onDetectBarcode),
          Container(color: Colors.black.withValues(alpha: 0.45)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                      const Text("Scan EV QR", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () async {
                          await controller.toggleTorch();
                          setState(() => flashOn = !flashOn);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                          child: Icon(flashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: SizedBox(
                    width: 280, height: 280,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 4), 
                            borderRadius: BorderRadius.circular(24)
                          )
                        ),
                        AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Positioned(
                              top: animation.value, left: 0, right: 0,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.7), blurRadius: 12)],
                                ),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Point camera toward EV QR sticker", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 40),
                // MANUAL ENTRY BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity, height: 58,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                          builder: (context) {
                            TextEditingController vehicleController = TextEditingController();
                            return Padding(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: StatefulBuilder(
                                    builder: (BuildContext context, StateSetter setModalState) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text("Enter Vehicle ID", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 20),
                                          TextField(
                                            controller: vehicleController,
                                            decoration: InputDecoration(
                                              hintText: "EVM1025029 or TEST123",
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity, height: 56,
                                            child: ElevatedButton(
                                              onPressed: isProcessingApi ? null : () async {
                                                setModalState(() => isProcessingApi = true);
                                                await _verifyAndUnlock(vehicleController.text, isManual: true);
                                                setModalState(() => isProcessingApi = false);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                              ),
                                              child: isProcessingApi
                                                  ? const CircularProgressIndicator(color: Colors.white)
                                                  : const Text("Unlock Vehicle", style: TextStyle(color: Colors.white, fontSize: 18)),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                      );
                                    }
                                  ),
                                ),
                              ),
                            );
                          }
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))
                      ),
                      icon: const Icon(Icons.keyboard, color: Colors.white),
                      label: const Text("Enter Vehicle ID Manually", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (isProcessingApi)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            )
        ],
      ),
    );
  }
}