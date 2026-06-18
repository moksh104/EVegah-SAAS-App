import 'package:flutter/material.dart';
import '../../data/services/ride_service.dart'; // 🚨 Make sure this import path matches where you saved the service!
import 'ride_detail_screen.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rideService = RideService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Ride History", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // 🚨 NEW: FutureBuilder to handle the API wait time automatically
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: rideService.fetchRideHistory(),
        builder: (context, snapshot) {
          
          // STATE 1: Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          
          // STATE 2: Error
          if (snapshot.hasError) {
            return Center(child: Text("Oops! Couldn't load rides.\n${snapshot.error}", textAlign: TextAlign.center));
          }

          // STATE 3: Empty (No Rides)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          // STATE 4: Success! Draw the list
          final pastRides = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pastRides.length,
            itemBuilder: (context, index) {
              final ride = pastRides[index];
              return _buildRideCard(context, ride);
            },
          );
        },
      ),
    );
  }

  // --- EMPTY STATE UI ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No past rides yet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("Your completed trips will appear here.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- RIDE CARD UI ---
  Widget _buildRideCard(BuildContext context, Map<String, dynamic> ride) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RideDetailScreen(rideData: ride)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Date & ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ride['date'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Text(ride['rideId'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Middle Row: Vehicle Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                  child: const Icon(Icons.electric_bike, color: Colors.black87),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Vehicle Scanned", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(ride['vehicleId'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const Spacer(),
                Text(ride['cost'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
            const SizedBox(height: 12),
            
            // Bottom Row: Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(Icons.route_outlined, ride['distance']),
                _buildMetric(Icons.timer_outlined, ride['time']),
                const Row(
                  children: [
                    Text("View Details", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right, color: Colors.blue, size: 20),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- HELPER METRIC ---
  Widget _buildMetric(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
      ],
    );
  }
}