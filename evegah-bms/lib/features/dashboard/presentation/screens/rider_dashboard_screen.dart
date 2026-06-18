import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RiderDashboardScreen extends StatelessWidget {
  const RiderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              _buildQuickActions(),
              const SizedBox(height: 18),
              _buildActiveRideCard(width),
              const SizedBox(height: 18),
              _buildKpiRow(),
              const SizedBox(height: 18),
              _buildRewardsBanner(),
              const SizedBox(height: 18),
              const Text('Recent Rides', style: AppTextStyles.titleLarge),
              const SizedBox(height: 8),
              _buildRecentRideTile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Good Morning', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 4),
              Text('Arthur Evans', style: AppTextStyles.dashboardTitle),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('Wallet Balance', style: TextStyle(color: Colors.white, fontSize: 12)),
              SizedBox(height: 4),
              Text('\$48.60', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final items = [
      ['Scan to Ride', Icons.qr_code],
      ['Plan Trip', Icons.place],
      ['Ride Pass', Icons.card_giftcard],
      ['Rewards', Icons.card_giftcard],
    ];

    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((it) {
          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.background,
                  child: Icon(it[1] as IconData, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(it[0] as String, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveRideCard(double width) {
    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('levegah 1S\nElectric Scooter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: const [Icon(Icons.battery_charging_full, color: Colors.green), SizedBox(width: 6), Text('78% Battery')]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: const [Icon(Icons.timer), SizedBox(width: 8), Text('12 min 34 sec')]),
                ),
                const SizedBox(height: 12),
                const Text('\$3.75', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () {}, child: const Text('End Ride')),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // scooter image placeholder
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Icon(Icons.electric_scooter, size: 64, color: AppColors.primary)),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 72,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Icon(Icons.map, color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    final kpis = [
      ['23', 'Total Rides'],
      ['18h 42m', 'Total Time'],
      ['68.4 kg', 'CO2 Saved'],
      ['520', 'Reward Points'],
    ];

    return Container(
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: kpis.map((k) {
          return Expanded(
            child: Column(
              children: [
                Text(k[0] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(k[1] as String, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRewardsBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEDE7F6), Color(0xFFF3E5F5)]),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Ride more, save more!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Unlock exclusive rewards and rider benefits.'),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.card_giftcard, color: Colors.white, size: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRideTile() {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.electric_scooter)),
        title: const Text('Today, 8:15 AM'),
        subtitle: const Text('Main St, Downtown → Park Ave'),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Text('12 min'), SizedBox(height: 4), Text('\$3.75')]),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.home, color: AppColors.primary)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.list_alt)),
            FloatingActionButton(
              onPressed: () {},
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.qr_code, size: 28),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.account_balance_wallet)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline)),
          ],
        ),
      ),
    );
  }
}
