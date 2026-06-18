import 'dart:async';
import 'package:flutter/material.dart';
import 'package:evegah_rider_app/features/dashboard/presentation/screens/main_navigation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/feedback_bottom_sheet.dart';
import '../../data/services/ride_service.dart';

class RideStartedScreen extends StatefulWidget {
  final String vehicleId;
  final int rideBookingId; // 🚨 1. We added this here!

  // 🚨 2. We require it in the constructor
  const RideStartedScreen({
    super.key, 
    required this.vehicleId, 
    required this.rideBookingId 
  });

  @override
  State<RideStartedScreen> createState() => _RideStartedScreenState();
}

class _RideStartedScreenState extends State<RideStartedScreen> {
  final RideService _rideService = RideService();
  
  // 🚨 3. DELETED the hardcoded currentRideBookingId = 456; 
  // We don't need it anymore because we have widget.rideBookingId!

  // --- TIMERS ---
  int seconds = 0;
  Timer? timer;
  Timer? apiPollingTimer;

  // --- LIVE DATA STATS ---
  String batteryPercentage = "--%";
  String speed = "0 km/h";
  
  // --- STATE TOGGLES ---
  bool isEndingRide = false;
  bool isPaused = false;
  bool isProcessingPause = false;

  // --- MAP & TRACKING VARIABLES ---
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  final List<LatLng> _routePoints = []; 
  Marker? _riderMarker; 

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(20.5937, 78.9629), 
    zoom: 16.0,
  );

  @override
  void initState() {
    super.initState();
    _startTimers();
    _startLocationTracking();
  }

  void _startTimers() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        setState(() => seconds++);
      }
    });

    apiPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchLiveRideDetails();
    });
  }

  // --- MAP & GPS TRACKING ---
  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, 
      ),
    ).listen((Position position) {
      LatLng currentPos = LatLng(position.latitude, position.longitude);

      setState(() {
        _routePoints.add(currentPos);

        _riderMarker = Marker(
          markerId: const MarkerId('rider'),
          position: currentPos,
          rotation: position.heading, 
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPos,
            zoom: 17.5,
            bearing: position.heading, 
            tilt: 45.0, 
          ),
        ),
      );
    });
  }

  // --- APIs (NOW POWERED BY CLEAN ARCHITECTURE) ---
  Future<void> _fetchLiveRideDetails() async {
    if (widget.vehicleId == "TEST123") {
      if (mounted) {
        setState(() {
          batteryPercentage = "86%";
          speed = isPaused ? "0 km/h" : "18 km/h";
        });
      }
      return;
    }

    // 🚨 CLEAN ARCHITECTURE: Let the service do the work!
    final data = await _rideService.getLiveRideDetails(widget.vehicleId, widget.rideBookingId);
    
    if (mounted) {
      setState(() {
        batteryPercentage = "${data['batteryPercentage'] ?? 0}%";
        speed = "${data['speed'] ?? 0} km/h";
      });
    }
  }

  Future<void> _togglePause() async {
    setState(() => isProcessingPause = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: Add real Pause API to service later

    if (mounted) {
      setState(() {
        isPaused = !isPaused;
        isProcessingPause = false;
        if (isPaused) speed = "0 km/h";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isPaused ? "Ride Paused ⏸️ Bike Locked" : "Ride Resumed ▶️ Bike Unlocked")),
      );
    }
  }

 Future<void> _endRide() async {
    setState(() => isEndingRide = true);

    Position? finalPos;
    try {
      finalPos = await Geolocator.getLastKnownPosition();
    } catch (e) {
      print("Couldn't get final GPS");
    }

    if (widget.vehicleId == "TEST123") {
      await Future.delayed(const Duration(seconds: 2));
      _showFeedbackAndExit();
      return;
    }

    // 🚨 CLEAN ARCHITECTURE: Ask the service to end the ride!
    bool success = await _rideService.endRide(widget.rideBookingId, finalPos?.latitude ?? 0.0, finalPos?.longitude ?? 0.0);
    if (success) {
      _showFeedbackAndExit();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to end ride. Please check connection.")));
        setState(() => isEndingRide = false);
      }
    }
  }

  // Helper method to keep code DRY
  void _showFeedbackAndExit() {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => FeedbackBottomSheet(rideId: widget.vehicleId),
    ).then((_) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    apiPollingTimer?.cancel();
    _positionStream?.cancel(); 
    _mapController?.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int remainingSeconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 🚨 UPGRADE: PopScope applied here to lock the screen!
    return PopScope(
      canPop: false, 
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You cannot leave this screen while a ride is active. Please End the ride first."),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // LAYER 1: MAP
            GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              myLocationEnabled: false, 
              compassEnabled: false,
              zoomControlsEnabled: false, 
              mapToolbarEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: _riderMarker != null ? {_riderMarker!} : {},
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _routePoints,
                  color: Colors.blue, 
                  width: 6,
                  jointType: JointType.round,
                  endCap: Cap.roundCap,
                )
              },
            ),

            // LAYER 2: TOP BAR
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, bottom: 16, left: 16, right: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      // 🚨 UPGRADE: SOS Button instead of back arrow!
                      child: IconButton(
                        icon: const Icon(Icons.support_agent_rounded, color: Colors.black), 
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Calling Support... (To be implemented)")),
                          );
                        }, 
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // LAYER 3: BOTTOM DASHBOARD
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGauge(Icons.timer_outlined, Colors.blue, _formatTime(seconds), "Time"),
                        _buildGauge(Icons.speed_rounded, Colors.orange, speed, "Speed"),
                        _buildGauge(Icons.battery_charging_full_rounded, Colors.green, batteryPercentage, "Battery"),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isProcessingPause || isEndingRide ? null : _togglePause,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPaused ? Colors.green : Colors.orange.shade400,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              child: isProcessingPause
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      isPaused ? "Resume" : "Pause",
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isEndingRide ? null : _endRide,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                elevation: 0,
                              ),
                              child: isEndingRide
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("End Ride", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E1452))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}