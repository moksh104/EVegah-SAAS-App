import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/services/unlock_service.dart';
import '../../data/services/location_service.dart';

import '../../../rides/presentation/screen/ride_started_screen.dart';

class UnlockingScreen extends StatefulWidget {
  final String vehicleId;

  const UnlockingScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<UnlockingScreen> createState() =>
      _UnlockingScreenState();
}

class _UnlockingScreenState
    extends State<UnlockingScreen> {

  final UnlockService unlockService =
      UnlockService();

  final LocationService locationService =
      LocationService();

  @override
  void initState() {

    super.initState();

    startUnlockFlow();
  }

  Future<void> startUnlockFlow() async {
  // 1. GOD MODE BYPASS
  if (widget.vehicleId == "TEST123") {
    // We add a tiny delay to allow the screen to fully transition
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Safety check: Is the screen still there?
    if (!mounted) return; 

    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const RideStartedScreen(
        vehicleId: "TEST123", 
        rideBookingId: 101, // 🚨 Added dummy ID for testing!
      ))
    );
    return;
  }

  // 2. Get User Location
  Position? userLocation = await locationService.getCurrentLocation();
  if (!mounted) return; // 🚨 CRITICAL: Check if still mounted after await

  if (userLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location Permission Required")));
    Navigator.pop(context);
    return;
  }

  // 3. DYNAMICALLY FETCH VEHICLE LOCATION
  final vehicleCoords = await unlockService.fetchVehicleLocation(widget.vehicleId);
  if (!mounted) return; // 🚨 CRITICAL: Check if still mounted after await

  if (vehicleCoords == null || (vehicleCoords['lat'] == 0 && vehicleCoords['lng'] == 0)) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vehicle Location Not Found")));
    Navigator.pop(context);
    return;
  }

  // 4. CALCULATE DISTANCE
  double distance = locationService.calculateDistance(
    userLocation.latitude,
    userLocation.longitude,
    vehicleCoords['lat']!,
    vehicleCoords['lng']!,
  );

  // 5. DISTANCE CHECK
  if (distance > 20) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Move closer. Distance: ${distance.toStringAsFixed(1)}m")),
    );
    Navigator.pop(context);
    return;
  }

  // 6. UNLOCK
  int? generatedRideId = await unlockService.unlockVehicle(widget.vehicleId);
  if (!mounted) return; // 🚨 CRITICAL: Check if still mounted after await

  if (generatedRideId != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideStartedScreen(
          vehicleId: widget.vehicleId,
          rideBookingId: generatedRideId, // 🚨 Passing the real ID!
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unlock failed. Please try again.")));
    Navigator.pop(context);
  }
}

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(
      backgroundColor:
          Colors.black,

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,

          children: [

            // ICON
            Container(
              height: 140,
              width: 140,

              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,

                color: Colors
                    .green.shade100,
              ),

              child: const Icon(
                Icons.lock_open,

                size: 70,

                color: Colors.green,
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            // TITLE
            const Text(
              "Unlocking EV 🔓",

              style: TextStyle(
                color:
                    Colors.white,

                fontSize: 30,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // VEHICLE ID
            Text(
              "Vehicle ID: ${widget.vehicleId}",

              style:
                  const TextStyle(
                color:
                    Colors.white70,

                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            // LOADER
            const CircularProgressIndicator(
              color: Colors.green,
            ),

            const SizedBox(
              height: 30,
            ),

            // MESSAGE
            const Text(
              "Checking GPS & connecting to smart vehicle system...",

              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}