import 'dart:async';

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    hide ClusterManager, Cluster;
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/vehicle_details_screen.dart';

// 🚨 ADDED: The new Dashboard Chef!
import '../../data/services/dashboard_service.dart'; 

class MapDiscoveryScreen extends StatefulWidget {
  const MapDiscoveryScreen({super.key});

  @override
  State<MapDiscoveryScreen> createState() => _MapDiscoveryScreenState();
}

class _MapDiscoveryScreenState extends State<MapDiscoveryScreen> {
  // 🚨 HIRE THE CHEF
  final DashboardService _dashboardService = DashboardService();

  // 🚨 DISTANCE FILTER VARIABLES
  double _selectedRadiusKm = 11.0; // Default to max 10km
  Position?
  _currentUserPosition; // Stores their GPS location so we don't have to keep pinging it
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  BitmapDescriptor? _customZoneMarker;
  Timer? _refreshTimer;
  bool _hasLocationPermission = false;
  bool _isLocatingUser = true;
  bool _mapReady = false;

  // 🚨 THE GPS ENGINE
  Future<Position?> _getUserLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // 1. Check if GPS is turned on in the phone settings
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please enable GPS services in your phone settings.',
              ),
            ),
          );
        }
        return null;
      }

      // 2. Check if the user has granted our app permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied, we cannot request permissions.',
              ),
            ),
          );
        }
        return null;
      }

      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
        });
      }

      // 3. If all checks pass, grab the coordinates with timeout!
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        ),
      );
    } catch (e) {
      debugPrint('GPS Error: $e');
      return null;
    }
  }

  // 🚨 AUTOMATIC STARTUP RADAR
  Future<void> _locateUserAndCheckZones() async {
    // 1. Get User Location quietly
    Position? userPos = await _getUserLocation();

    // 🚨 NEW: Save it so the filter slider can use it!
    if (userPos != null) {
      _currentUserPosition = userPos;
    }

    // 2. If we got the location, change the map's starting point to HERE!
    if (userPos != null) {
      _initialCameraPosition = CameraPosition(
        target: LatLng(userPos.latitude, userPos.longitude),
        zoom: 14.0, // Zoomed in perfectly on the user
      );
    }

    // 3. Stop the loading screen and finally draw the map
    if (mounted) {
      setState(() {
        _isLocatingUser = false;
      });
    }

    if (userPos == null) return; // Stop here if GPS failed

    // 4. Scan the 10km radius
    bool hasNearbyZones = false;
    double maxAllowedDistanceInKm = 10.0;

    for (var zone in _allLiveZones) {
      final center = zone['center'] as LatLng?;
      if (center == null) continue;

      double dist = _calculateDistance(
        userPos.latitude,
        userPos.longitude,
        center.latitude,
        center.longitude,
      );

      if (dist <= maxAllowedDistanceInKm) {
        hasNearbyZones = true;
        break;
      }
    }

    // 5. If they are far away, show the alert!
    if (!hasNearbyZones && mounted) {
      _showNoZonesAlert(context);
    }
  }

  // 🚨 FILTER STATE VARIABLES
  String _selectedVehicleType = "All";
  double _minBatteryLevel = 0;
  double _maxPrice = 0.50;
  List<Map<String, dynamic>> _allLiveZones = [];

  // 🚨 NEW CLUSTER VARIABLES
  late ClusterManager<ZonePlace> _clusterManager;
  List<ZonePlace> _clusterItems = [];

  @override
  void initState() {
    super.initState();
    _clusterManager = _initClusterManager();
    _startupSequence();
    _startAutoRefreshEngine();
  }

  Future<void> _startupSequence() async {
    // Load map data first so zones are ready when we check location
    await _loadMapData();
    // Then locate user and check zones against loaded data
    await _locateUserAndCheckZones();
    // After location is known, move camera to user position
    if (_currentUserPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(_initialCameraPosition),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // 🚨 CLUSTER MANAGER SETUP
  ClusterManager<ZonePlace> _initClusterManager() {
    return ClusterManager<ZonePlace>(
      _clusterItems,
      _updateMarkers,
      markerBuilder: (dynamic cluster) =>
          _markerBuilder(cluster as Cluster<ZonePlace>),
    );
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers = markers;
    });
  }

  // 🚨 THE SMART MARKER BUILDER
  Future<Marker> _markerBuilder(Cluster<ZonePlace> cluster) async {
    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      onTap: () async {
        if (cluster.isMultiple) {
          final GoogleMapController? controller = _mapController;
          if (controller == null) return;

          double minLat = cluster.items.first.location.latitude;
          double maxLat = cluster.items.first.location.latitude;
          double minLng = cluster.items.first.location.longitude;
          double maxLng = cluster.items.first.location.longitude;

          for (var item in cluster.items) {
            if (item.location.latitude < minLat) minLat = item.location.latitude;
            if (item.location.latitude > maxLat) maxLat = item.location.latitude;
            if (item.location.longitude < minLng) minLng = item.location.longitude;
            if (item.location.longitude > maxLng) maxLng = item.location.longitude;
          }

          if (minLat == maxLat && minLng == maxLng) {
            controller.animateCamera(
              CameraUpdate.newLatLngZoom(
                cluster.location,
                (await controller.getZoomLevel()) + 4,
              ),
            );
          } else {
            final LatLngBounds bounds = LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            );
            controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
          }
        } else {
          _showZoneVehiclesSheet(context, cluster.items.first.rawData);
        }
      },
      icon: cluster.isMultiple
          ? await _getClusterIcon(cluster.count)
          : _customZoneMarker ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
    );
  }

  // 🚨 DRAW THE NUMBERED CIRCLE FOR CLUSTERS
  Future<BitmapDescriptor> _getClusterIcon(int clusterSize) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 120.0;

    final Paint paint = Paint()
      ..color = const Color(0xFF1E1452)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.2, paint);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.2,
      borderPaint,
    );

    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: clusterSize.toString(),
      style: const TextStyle(
        fontSize: size / 3,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    painter.layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
    );

    final img = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _silentRefreshData() async {
    try {
      // 🚨 ASK THE CHEF!
      final liveZones = await _dashboardService.fetchLiveZonesFromApi();
      if (liveZones.isNotEmpty && mounted) {
        _allLiveZones = liveZones;
        _applyFilters();
      }
    } catch (e) {
      debugPrint("Background refresh failed silently: $e");
    }
  }

  void _startAutoRefreshEngine() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _silentRefreshData();
    });
  }

  Future<void> _loadMapData() async {
    try {
      _customZoneMarker = await _loadCustomIconFromAsset(
        'assets/evegah-zone-1.png',
        size: 130,
      );
    } catch (e) {
      debugPrint("Error loading custom icon, using default marker: $e");
      _customZoneMarker = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueViolet,
      );
    }

    setState(() => _markers = {});

    // 🚨 ASK THE CHEF!
    final liveZones = await _dashboardService.fetchLiveZonesFromApi();

    if (liveZones.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNoZonesAlert(context);
      });
    } else {
      _allLiveZones = liveZones;
      _applyFilters();
    }
  }

  Future<BitmapDescriptor> _loadCustomIconFromAsset(
    String path, {
    int size = 100,
  }) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: size,
    );
    ui.FrameInfo fi = await codec.getNextFrame();

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..filterQuality = ui.FilterQuality.high;

    canvas.drawImageRect(
      fi.image,
      Rect.fromLTWH(
        0,
        0,
        fi.image.width.toDouble(),
        fi.image.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      paint,
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size,
      size,
    );
    final ByteData? bytes = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // 🚨 UPDATED MAGIC SIEVE TO USE CLUSTER MANAGER
  void _applyFilters({bool showAlert = false}) {
    List<Map<String, dynamic>> filteredZones = [];
    bool isFilterActive = _minBatteryLevel > 0;

    for (var zone in _allLiveZones) {
      if (_currentUserPosition != null && _selectedRadiusKm < 11.0) {
        final center = zone['center'] as LatLng?;
        if (center != null) {
          double dist = _calculateDistance(
            _currentUserPosition!.latitude,
            _currentUserPosition!.longitude,
            center.latitude,
            center.longitude,
          );

          if (dist > _selectedRadiusKm) {
            continue;
          }
        }
      }
      List<dynamic> allVehiclesInZone = zone['vehicles'] ?? [];

      List<dynamic> validVehicles = allVehiclesInZone.where((vehicle) {
        if (!isFilterActive) return true;

        int battery =
            int.tryParse(vehicle['batteryPercentage']?.toString() ?? '-1') ??
            -1;
        return battery >= _minBatteryLevel;
      }).toList();

      if (isFilterActive ? validVehicles.isNotEmpty : true) {
        Map<String, dynamic> updatedZone = Map<String, dynamic>.from(zone);
        updatedZone['vehicles'] = isFilterActive
            ? validVehicles
            : allVehiclesInZone;
        updatedZone['bikeCount'] = isFilterActive
            ? validVehicles.length
            : allVehiclesInZone.length;

        filteredZones.add(updatedZone);
      }
    }

    setState(() {
      _clusterItems = filteredZones
          .map(
            (zone) => ZonePlace(
              name: zone['zoneName']?.toString() ?? '',
              rawData: zone,
              latLng: zone['center'],
            ),
          )
          .toList();

      _clusterManager.setItems(_clusterItems);
    });
    
    if (showAlert) {
      bool isMapEmpty = _markers.isEmpty;
      if (isMapEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showNoZonesAlert(context);
          }
        });
      }
    }
  }

  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(
      23.0225,
      72.5714,
    ),
    zoom: 14.0,
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLocatingUser
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1E1452)),
                  SizedBox(height: 16),
                  Text(
                    "Locating nearest bikes...",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _clusterManager.setMapId(controller.mapId);
                    if (_clusterItems.isNotEmpty) {
                      _clusterManager.setItems(_clusterItems);
                    }
                    if (mounted) {
                      setState(() => _mapReady = true);
                    }
                  },
                  onCameraMove: _clusterManager.onCameraMove,
                  onCameraIdle: _clusterManager.updateMap,
                  zoomControlsEnabled: false,
                  myLocationEnabled: _hasLocationPermission,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu, color: Colors.black87),
                            onPressed: () {},
                          ),
                        ),

                        Container(
                          height: 50,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.tune,
                              color:
                                  _minBatteryLevel > 0 ||
                                          _selectedVehicleType != "All"
                                      ? Colors.purple
                                      : Colors.black87,
                            ),
                            onPressed: () {
                              _showFilterSheet(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    height: 60,
                    width: double.infinity,

                    child: ElevatedButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Locating nearest available bikes...',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        Position? userPos = await _getUserLocation();
                        if (userPos == null) return; 

                        Map<String, dynamic>? closestZone;
                        double minDistance = double.infinity;

                        for (var zone in _allLiveZones) {
                          if (zone['vehicles']?.isEmpty ?? true) continue;

                          final center = zone['center'] as LatLng?;
                          if (center == null) continue;

                          double dist = _calculateDistance(
                            userPos.latitude,
                            userPos.longitude,
                            center.latitude,
                            center.longitude,
                          );

                          if (dist < minDistance) {
                            minDistance = dist;
                            closestZone = zone;
                          }
                        }

                        double maxAllowedDistanceInKm = 10.0; 

                        if (closestZone != null &&
                            minDistance <= maxAllowedDistanceInKm) {
                          final targetLatLng = closestZone['center'] as LatLng;
                          final GoogleMapController? controller =
                              _mapController;

                          if (controller != null) {
                            await controller.animateCamera(
                              CameraUpdate.newLatLngZoom(targetLatLng, 16.5),
                            );
                          }

                          if (mounted) {
                            _showZoneVehiclesSheet(context, closestZone);
                          }
                        } else {
                          if (mounted) {
                            _showNoZonesAlert(context);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1452),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 10,
                        shadowColor: const Color(0x661E1452),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.near_me, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Find Nearby",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!_mapReady)
                  Container(
                    color: const Color(0xFFF5F6FA),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF1E1452)),
                          SizedBox(height: 16),
                          Text(
                            "Loading map...",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showNoZonesAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Alert",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No eVegah zones found in the specified location.\nExplore other areas for available zones.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 160,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showZoneVehiclesSheet(BuildContext context, Map<String, dynamic> zone) {
    String zoneName = zone['zoneName']?.toString() ?? 'eVegah Parking Zone';
    String zoneAddress =
        zone['zone_address']?.toString() ?? 'Address not available';
    List<dynamic> zoneVehicles = zone['vehicles'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zoneName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  zoneAddress,
                                  maxLines: 2, // 🚨 THE MAGIC FIX: Limits to 2 lines
                                  overflow: TextOverflow.ellipsis, // 🚨 Adds "..." at the end
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  final centerPoint = zone['center'];
                                  if (centerPoint != null) {
                                    _launchDirections(
                                      centerPoint.latitude,
                                      centerPoint.longitude,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.directions_walk,
                                  size: 16,
                                  color: Color(0xFF1E1452),
                                ),
                                label: const Text(
                                  "Directions",
                                  style: TextStyle(
                                    color: Color(0xFF1E1452),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(color: Color(0xFF1E1452), width: 1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  bool isEmptyZone = zoneVehicles.isEmpty;
                  bool isHighDemand =
                      zoneVehicles.isNotEmpty && zoneVehicles.length <= 2;

                  Map<String, dynamic>? alternativeZone;
                  if (isEmptyZone || isHighDemand) {
                    alternativeZone = _getBestAlternativeZone(zone);
                  }

                  return Column(
                    children: [
                      if (isEmptyZone)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "All bikes are currently rented from this zone.",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (isHighDemand)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "High Demand Area! Bikes here usually go fast.",
                                  style: TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (alternativeZone != null)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EDFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1E1452).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_circle,
                                color: Color(0xFF1E1452),
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Nearest Available Bikes",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF1E1452),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${alternativeZone['zoneName']} has ${alternativeZone['vehicles']?.length} bikes and is just ${(alternativeZone['temp_distance'] * 1000).toInt()}m away.",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.directions,
                                  color: Color(0xFF1E1452),
                                ),
                                onPressed: () {
                                  final altCenter =
                                      alternativeZone!['center'] as LatLng;
                                  _launchDirections(
                                    altCenter.latitude,
                                    altCenter.longitude,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              Divider(thickness: 1, color: Colors.grey[300], height: 24),
              if (zoneVehicles.isNotEmpty) 
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Vehicle No.",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "Status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: zoneVehicles.isEmpty
                    ? const Center(
                        child: Text(
                          "No vehicles currently available here.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        itemCount: zoneVehicles.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.grey.shade200,
                          indent: 24,
                          endIndent: 24,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final vehicle = zoneVehicles[index];
                          final String vehicleId =  vehicle['lockNumber']?.toString() ?? "Unknown";
                          final int battery =
                              int.tryParse(
                                vehicle['batteryPercentage']?.toString() ??
                                    '-1',
                              ) ??
                              -1;
                          final String statusText = battery < 0
                              ? "Available - NA"
                              : "Available - $battery%";

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VehicleDetailsScreen(
                                    vehicleId: vehicleId,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    vehicleId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: battery < 0
                                          ? Colors.grey.shade600
                                          : Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
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
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    String tempType = _selectedVehicleType;
    double tempBattery = _minBatteryLevel;
    double tempPrice = _maxPrice;
    double tempRadius = _selectedRadiusKm;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter Options",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1452),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempType = "All";
                              tempBattery = 0;
                              tempPrice = 0.50;
                              tempRadius = 11.0; 
                            });
                          },
                          child: const Text(
                            "Clear All",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Vehicle Type",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: ["All", "Scooter", "E-Bike"].map((type) {
                        final isSelected = tempType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1E1452),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (bool selected) {
                            setModalState(() => tempType = type);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Maximum Walking Distance",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tempRadius == 11.0
                              ? "Anywhere"
                              : "${tempRadius.toInt()} km",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempRadius,
                      min: 1.0,
                      max: 11.0, 
                      divisions: 10, 
                      activeColor: Colors.blue,
                      inactiveColor: Colors.blue.shade100,
                      onChanged: (value) =>
                          setModalState(() => tempRadius = value),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Minimum Battery",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${tempBattery.toInt()}%",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempBattery,
                      min: 0,
                      max: 100,
                      divisions: 10,
                      activeColor: Colors.green,
                      inactiveColor: Colors.green.shade100,
                      onChanged: (value) =>
                          setModalState(() => tempBattery = value),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Max Fare/Min",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "₹${tempPrice.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempPrice,
                      min: 0.10,
                      max: 1.00,
                      divisions: 18,
                      activeColor: Colors.red,
                      inactiveColor: Colors.red.shade100,
                      onChanged: (value) =>
                          setModalState(() => tempPrice = value),
                    ),

                    const SizedBox(
                      height: 30,
                    ), 
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedVehicleType = tempType;
                            _minBatteryLevel = tempBattery;
                            _maxPrice = tempPrice;
                            _selectedRadiusKm = tempRadius; 
                          });
                          Navigator.pop(context);
                          _applyFilters(
                            showAlert: true,
                          ); 
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1452),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Apply Filters",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchDirections(
    double destinationLat,
    double destinationLng,
  ) async {
    final String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng&travelmode=walking";
    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not open maps application.");
    }
  }

  Map<String, dynamic>? _getBestAlternativeZone(
    Map<String, dynamic> currentZone,
  ) {
    final currentCenter = currentZone['center'] as LatLng?;
    if (currentCenter == null) return null;

    List<Map<String, dynamic>> validAlternatives = [];

    for (var zone in _allLiveZones) {
      if (zone['id'] == currentZone['id']) continue; 

      final center = zone['center'] as LatLng?;
      if (center == null) continue;

      int bikeCount = zone['vehicles']?.length ?? 0;
      if (bikeCount < 3) continue;

      double distanceKm = _calculateDistance(
        currentCenter.latitude,
        currentCenter.longitude,
        center.latitude,
        center.longitude,
      );

      if (distanceKm <= 10) {
        var potentialZone = Map<String, dynamic>.from(zone);
        potentialZone['temp_distance'] = distanceKm;
        validAlternatives.add(potentialZone);
      }
    }

    if (validAlternatives.isEmpty) return null;

    validAlternatives.sort(
      (a, b) => (a['temp_distance'] as double).compareTo(
        b['temp_distance'] as double,
      ),
    );
    return validAlternatives.first;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var a =
        0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }
}

// 🚨 Place this at the very bottom of the file, outside of the main class!
class ZonePlace with ClusterItem {
  final String name;
  final Map<String, dynamic> rawData;
  final LatLng latLng;

  ZonePlace({required this.name, required this.rawData, required this.latLng});

  @override
  LatLng get location => latLng;
}