import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../domain/entities/franchise_entity.dart';
import '../providers/franchise_provider.dart';

class FranchiseListScreen extends ConsumerStatefulWidget {
  const FranchiseListScreen({super.key});

  @override
  ConsumerState<FranchiseListScreen> createState() => _FranchiseListScreenState();
}

class _FranchiseListScreenState extends ConsumerState<FranchiseListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedZone = 'All Zones';
  String _selectedStatus = 'All Status';
  String _selectedApproval = 'All';
  String _selectedType = 'All Types';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedZone = 'All Zones';
      _selectedStatus = 'All Status';
      _selectedApproval = 'All';
      _selectedType = 'All Types';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    final refFranchises = ref.watch(franchiseProvider);

    // Initial mockup data
    final List<Map<String, dynamic>> mockupList = [
      {
        'id': 'FRN-CP-0001',
        'name': 'CP E-Vegah Hub',
        'ownerName': 'Rahul Sharma',
        'location': 'Connaught Place, Delhi',
        'type': 'Battery Swapping + Rental',
        'status': 'Active',
        'approvalStatus': 'Approved',
        'joinedOn': '12 Jan 2024',
        'revenue': 324850.0,
      },
      {
        'id': 'FRN-KR-0002',
        'name': 'Karol Bagh E-Vegah',
        'ownerName': 'Aarav Verma',
        'location': 'Karol Bagh, Delhi',
        'type': 'Battery Swapping',
        'status': 'Active',
        'approvalStatus': 'Approved',
        'joinedOn': '18 Jan 2024',
        'revenue': 288650.0,
      },
      {
        'id': 'FRN-JM-0003',
        'name': 'Janakpuri E-Vegah',
        'ownerName': 'Neha Gupta',
        'location': 'Janakpuri, Delhi',
        'type': 'Rental',
        'status': 'Active',
        'approvalStatus': 'Approved',
        'joinedOn': '22 Jan 2024',
        'revenue': 245320.0,
      },
      {
        'id': 'FRN-RJ-0004',
        'name': 'Raja Garden E-Vegah',
        'ownerName': 'Mohit Singh',
        'location': 'Raja Garden, Delhi',
        'type': 'Battery Swapping + Rental',
        'status': 'Active',
        'approvalStatus': 'Approved',
        'joinedOn': '02 Feb 2024',
        'revenue': 312750.0,
      },
      {
        'id': 'FRN-DW-0005',
        'name': 'Dwarka E-Vegah',
        'ownerName': 'Pooja Mehta',
        'location': 'Dwarka, Delhi',
        'type': 'Battery Swapping',
        'status': 'Inactive',
        'approvalStatus': 'N/A',
        'joinedOn': '10 Feb 2024',
        'revenue': 0.0,
      },
      {
        'id': 'FRN-PK-0006',
        'name': 'Pitampura E-Vegah',
        'ownerName': 'Vikram Arora',
        'location': 'Pitampura, Delhi',
        'type': 'Rental',
        'status': 'Pending',
        'approvalStatus': 'Pending',
        'joinedOn': '15 Feb 2024',
        'revenue': 0.0,
      },
      {
        'id': 'FRN-NR-0007',
        'name': 'Nehru Place E-Vegah',
        'ownerName': 'Sandeep Kumar',
        'location': 'Nehru Place, Delhi',
        'type': 'Battery Swapping + Rental',
        'status': 'Active',
        'approvalStatus': 'Approved',
        'joinedOn': '20 Feb 2024',
        'revenue': 295600.0,
      },
      {
        'id': 'FRN-LJ-0008',
        'name': 'Lajpat Nagar E-Vegah',
        'ownerName': 'Karan Malhotra',
        'location': 'Lajpat Nagar, Delhi',
        'type': 'Battery Swapping',
        'status': 'Suspended',
        'approvalStatus': 'Approved',
        'joinedOn': '05 Mar 2024',
        'revenue': 0.0,
      },
    ];

    // Combine static mockup with dynamic provider list
    final List<Map<String, dynamic>> allFranchises = [...mockupList];
    for (var f in refFranchises) {
      if (!allFranchises.any((item) => item['id'] == f.id || item['name'] == f.name)) {
        allFranchises.add({
          'id': f.id.startsWith('FRN-') ? f.id : 'FRN-NEW-00${f.id}',
          'name': f.name,
          'ownerName': f.ownerName,
          'location': 'Connaught Place, Delhi',
          'type': 'Battery Swapping',
          'status': 'Active',
          'approvalStatus': 'Approved',
          'joinedOn': '14 Jun 2026',
          'revenue': 0.0,
        });
      }
    }

    // Apply active filters
    final filteredFranchises = allFranchises.where((frn) {
      final name = (frn['name'] as String? ?? '').toLowerCase();
      final code = (frn['id'] as String? ?? '').toLowerCase();
      final owner = (frn['ownerName'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          code.contains(query) ||
          owner.contains(query);

      final matchesZone = _selectedZone == 'All Zones' ||
          (frn['location'] as String? ?? '').contains(_selectedZone.replaceAll(', Delhi', ''));

      final matchesStatus = _selectedStatus == 'All Status' || frn['status'] == _selectedStatus;

      final matchesApproval = _selectedApproval == 'All' || frn['approvalStatus'] == _selectedApproval;

      final matchesType = _selectedType == 'All Types' ||
          (frn['type'] as String? ?? '').contains(_selectedType.split(' ')[0]);

      return matchesSearch && matchesZone && matchesStatus && matchesApproval && matchesType;
    }).toList();

    Widget dashboardBody = _buildDashboardContent(context, filteredFranchises, isDesktop);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            const SizedBox(
              width: 260,
              child: SidebarNavigation(activeItem: 'Franchise', activeSubItem: 'Franchise List'),
            ),
            Expanded(
              child: dashboardBody,
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const Drawer(
          width: 260,
          child: SidebarNavigation(activeItem: 'Franchise', activeSubItem: 'Franchise List'),
        ),
        body: dashboardBody,
      );
    }
  }

  Widget _buildDashboardContent(BuildContext context, List<Map<String, dynamic>> franchises, bool isDesktop) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Row
          _buildHeader(context, isDesktop),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable View
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumbs
                  Row(
                    children: const [
                      Text(
                        'Home',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                      Text(
                        'Franchise',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                      Text(
                        'Franchise Management',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title and Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Franchise Management',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: -0.5),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage and monitor all franchise operations and performance',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      // Actions buttons group
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(90, 40),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.file_upload_outlined, size: 16, color: Color(0xFF64748B)),
                            label: const Text('Export', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _showAddFranchiseDialog(context),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(130, 40),
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Franchise', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Metrics Cards Row
                  _buildMetricsRow(),
                  const SizedBox(height: 24),

                  // Filter Row Panel
                  _buildFiltersBar(),
                  const SizedBox(height: 16),

                  // Table list containing card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: const Text(
                            'Franchise List',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildFranchiseTable(franchises),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildPaginationRow(franchises.length),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Charts Grid
                  _buildChartsGrid(isDesktop),
                  const SizedBox(height: 24),

                  // Bottom Quick Summary Footer
                  _buildQuickSummaryCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF64748B)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'AV',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Hello, Akash 👋',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                'Zone Employee',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Spacer(),
          // Location card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  'Connaught Place Zone',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Bell notification
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 18, color: Color(0xFF1E293B)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F46E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 5;
        final isCompact = constraints.maxWidth < 900;

        final cards = [
          _metricCard('Total Franchises', '48', 'Across all zones', const Color(0xFFEEF2FF), const Color(0xFF4F46E5), Icons.storefront_rounded),
          _metricCard('Active Franchises', '42', '87.50%', const Color(0xFFECFDF5), const Color(0xFF059669), Icons.store_mall_directory_outlined),
          _metricCard('Pending Approval', '3', '6.25%', const Color(0xFFFFF7ED), const Color(0xFFEA580C), Icons.watch_later_outlined),
          _metricCard('Inactive / Suspended', '3', '6.25%', const Color(0xFFFEE2E2), const Color(0xFFDC2626), Icons.store_outlined),
          _revenueMetricCard('Total Revenue (MTD)', '₹28,75,450', '↑ 12.6% vs last month', const Color(0xFFEFF6FF), const Color(0xFF2563EB), Icons.account_balance_wallet_outlined),
        ];

        if (isCompact) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: cards,
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: cards.map((c) => SizedBox(width: cardWidth, child: c)).toList(),
        );
      },
    );
  }

  Widget _metricCard(String label, String value, String subtext, Color bgColor, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _revenueMetricCard(String label, String value, String trend, Color bgColor, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded, size: 10, color: Color(0xFF16A34A)),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  trend,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 800;

          final searchField = Expanded(
            flex: isCompact ? 0 : 2,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF1E293B)),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Search by Franchise Name / Code / Owner',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          final filters = [
            _buildDropdownFilter('All Zones', _selectedZone, ['Connaught Place', 'Karol Bagh', 'Janakpuri', 'Raja Garden', 'Dwarka', 'Pitampura', 'Nehru Place', 'Lajpat Nagar'], (v) {
              setState(() => _selectedZone = v!);
            }),
            _buildDropdownFilter('All Status', _selectedStatus, ['Active', 'Inactive', 'Pending', 'Suspended'], (v) {
              setState(() => _selectedStatus = v!);
            }),
            _buildDropdownFilter('All', _selectedApproval, ['Approved', 'Pending', 'N/A'], (v) {
              setState(() => _selectedApproval = v!);
            }),
            _buildDropdownFilter('All Types', _selectedType, ['Battery Swapping', 'Rental', 'Battery Swapping + Rental'], (v) {
              setState(() => _selectedType = v!);
            }),
            // More Filters button
            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(95, 36),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF64748B)),
              label: const Text('More Filters', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ),
            // Reset Button
            OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(60, 36),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Reset', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ),
            // Apply Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(70, 36),
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Apply', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
          ];

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: double.infinity, child: searchField),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filters,
                ),
              ],
            );
          }

          return Row(
            children: [
              searchField,
              const SizedBox(width: 12),
              ...filters.map((w) => Padding(padding: const EdgeInsets.only(left: 6.0), child: w)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdownFilter(String hint, String currentVal, List<String> items, ValueChanged<String?> onChanged) {
    final list = [hint, ...items];
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          items: list.map((e) {
            return DropdownMenuItem<String>(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildFranchiseTable(List<Map<String, dynamic>> franchises) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        headingRowHeight: 44,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        columns: const [
          DataColumn(label: Text('Franchise Code')),
          DataColumn(label: Text('Franchise Name')),
          DataColumn(label: Text('Owner Name')),
          DataColumn(label: Text('Zone / Location')),
          DataColumn(label: Text('Franchise Type')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Approval Status')),
          DataColumn(label: Text('Joined On')),
          DataColumn(label: Text('Revenue (MTD)')),
          DataColumn(label: Text('Actions')),
        ],
        rows: franchises.map((frn) {
          final String code = frn['id'] ?? '';
          final String name = frn['name'] ?? '';
          final String owner = frn['ownerName'] ?? '';
          final String loc = frn['location'] ?? '';
          final String type = frn['type'] ?? '';
          final String status = frn['status'] ?? 'Active';
          final String approval = frn['approvalStatus'] ?? 'Approved';
          final String joined = frn['joinedOn'] ?? '';
          final double rev = frn['revenue'] ?? 0.0;

          // Badges formatting
          Color statusBg = const Color(0xFFDCFCE7);
          Color statusText = const Color(0xFF15803D);
          if (status == 'Inactive') {
            statusBg = const Color(0xFFF1F5F9);
            statusText = const Color(0xFF64748B);
          } else if (status == 'Pending') {
            statusBg = const Color(0xFFFEF3C7);
            statusText = const Color(0xFFD97706);
          } else if (status == 'Suspended') {
            statusBg = const Color(0xFFFEE2E2);
            statusText = const Color(0xFFDC2626);
          }

          Color appBg = const Color(0xFFDCFCE7);
          Color appText = const Color(0xFF15803D);
          if (approval == 'Pending') {
            appBg = const Color(0xFFFEF3C7);
            appText = const Color(0xFFD97706);
          } else if (approval == 'N/A') {
            appBg = const Color(0xFFF1F5F9);
            appText = const Color(0xFF64748B);
          }

          final revStr = rev > 0 ? '₹${_formatRevenue(rev)}' : '₹0';

          return DataRow(cells: [
            DataCell(Text(code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)))),
            DataCell(Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
            DataCell(Text(owner, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)))),
            DataCell(Text(loc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
            DataCell(Text(type, style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)))),
            // Status
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusText)),
              ),
            ),
            // Approval
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(6)),
                child: Text(approval, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: appText)),
              ),
            ),
            DataCell(Text(joined, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)))),
            DataCell(Text(revStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF64748B)),
                    onPressed: () => _viewFranchiseDetails(context, frn),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 14, color: Color(0xFF64748B)),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildPaginationRow(int showing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'Showing 1 to $showing of 48 entries',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const Spacer(),
          _buildPageArrow(Icons.chevron_left_rounded, false),
          _buildPageNumber('1', true),
          _buildPageNumber('2', false),
          _buildPageNumber('3', false),
          _buildPageNumber('4', false),
          _buildPageNumber('5', false),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text('...', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ),
          _buildPageNumber('6', false),
          _buildPageArrow(Icons.chevron_right_rounded, true),
          const SizedBox(width: 12),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: 10,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 / page', style: TextStyle(fontSize: 11, color: Color(0xFF1E293B)))),
                  DropdownMenuItem(value: 10, child: Text('10 / page', style: TextStyle(fontSize: 11, color: Color(0xFF1E293B)))),
                  DropdownMenuItem(value: 20, child: Text('20 / page', style: TextStyle(fontSize: 11, color: Color(0xFF1E293B)))),
                ],
                onChanged: (_) {},
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumber(String page, bool active) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEEF2FF) : Colors.transparent,
        border: active ? Border.all(color: const Color(0xFF4F46E5), width: 1.2) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          page,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildPageArrow(IconData icon, bool enabled) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(icon, size: 14, color: enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
    );
  }

  Widget _buildChartsGrid(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _buildDistributionCard()),
          const SizedBox(width: 14),
          Expanded(flex: 3, child: _buildStatusCard()),
          const SizedBox(width: 14),
          Expanded(flex: 4, child: _buildRevenueChartCard()),
          const SizedBox(width: 14),
          Expanded(flex: 4, child: _buildRecentInwardCard()),
        ],
      );
    } else {
      return Column(
        children: [
          _buildDistributionCard(),
          const SizedBox(height: 14),
          _buildStatusCard(),
          const SizedBox(height: 14),
          _buildRevenueChartCard(),
          const SizedBox(height: 14),
          _buildRecentInwardCard(),
        ],
      );
    }
  }

  Widget _buildDistributionCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Franchise Distribution by Zone', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Spacer(),
          Row(
            children: [
              // Doughnut visual
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(80, 80),
                      painter: DoughnutChartPainter(
                        values: [12, 8, 6, 5, 5, 12],
                        colors: const [
                          Color(0xFF6366F1), // CP
                          Color(0xFF3B82F6), // KB
                          Color(0xFFF59E0B), // JP
                          Color(0xFFEF4444), // RG
                          Color(0xFFEC4899), // NP
                          Color(0xFFCBD5E1), // Others
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('48', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.1)),
                        Text('Total', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Legend
              Expanded(
                child: Column(
                  children: [
                    _legendItem('Connaught Place', '12 (25%)', const Color(0xFF6366F1)),
                    _legendItem('Karol Bagh', '8 (16.7%)', const Color(0xFF3B82F6)),
                    _legendItem('Janakpuri', '6 (12.5%)', const Color(0xFFF59E0B)),
                    _legendItem('Raja Garden', '5 (10.4%)', const Color(0xFFEF4444)),
                    _legendItem('Nehru Place', '5 (10.4%)', const Color(0xFFEC4899)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () {},
            child: const Text('View All Zones →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Franchise Status', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Spacer(),
          Row(
            children: [
              // Doughnut visual
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(80, 80),
                      painter: DoughnutChartPainter(
                        values: [42, 3, 3, 3],
                        colors: const [
                          Color(0xFF10B981), // Active
                          Color(0xFF3B82F6), // Inactive
                          Color(0xFFEF4444), // Suspended
                          Color(0xFFF59E0B), // Pending
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('48', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.1)),
                        Text('Total', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Legend
              Expanded(
                child: Column(
                  children: [
                    _legendItem('Active', '42 (87.50%)', const Color(0xFF10B981)),
                    _legendItem('Inactive', '3 (6.25%)', const Color(0xFF3B82F6)),
                    _legendItem('Suspended', '3 (6.25%)', const Color(0xFFEF4444)),
                    _legendItem('Pending Approval', '3 (6.25%)', const Color(0xFFF59E0B)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () {},
            child: const Text('View All →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String zone, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(zone, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(percent, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildRevenueChartCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Revenue Overview', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'This Month',
                    items: const [
                      DropdownMenuItem(value: 'This Month', child: Text('This Month', style: TextStyle(fontSize: 10, color: Color(0xFF1E293B), fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (_) {},
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Custom bar chart row
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _barColumn('CP', 0.8),
                _barColumn('KR', 0.65),
                _barColumn('JM', 0.55),
                _barColumn('RG', 0.72),
                _barColumn('NR', 0.68),
                _barColumn('DW', 0.15),
                _barColumn('PK', 0.38),
                _barColumn('Others', 0.78),
              ],
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {},
            child: const Text('View Detailed Report →', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          ),
        ],
      ),
    );
  }

  Widget _barColumn(String label, double fillPercent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Bar track and fill
        Container(
          width: 14,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 14,
            height: 70 * fillPercent,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildRecentInwardCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Franchise Inward', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              InkWell(
                onTap: () {},
                child: const Text('View All', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _recentInwardItem('FRN-PK-0006', 'Pitampura E-Vegah', '20 May 2024, 11:30 AM'),
          const Divider(height: 10, color: Color(0xFFF1F5F9)),
          _recentInwardItem('FRN-CR-0009', 'Chandni Chowk E-Vegah', '20 May 2024, 10:45 AM'),
          const Divider(height: 10, color: Color(0xFFF1F5F9)),
          _recentInwardItem('FRN-SA-0010', 'Saket E-Vegah', '20 May 2024, 09:15 AM'),
        ],
      ),
    );
  }

  Widget _recentInwardItem(String code, String name, String time) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
          child: const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF4F46E5)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text(name, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
              child: const Text('Pending', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
            ),
            const SizedBox(height: 2),
            Text(time, style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryCol(Icons.storefront_rounded, 'Total Franchises', '48', const Color(0xFF4F46E5)),
              _summaryCol(Icons.check_circle_outline_rounded, 'Active', '42', const Color(0xFF10B981)),
              _summaryCol(Icons.cancel_outlined, 'Inactive / Suspended', '3', const Color(0xFFEF4444)),
              _summaryCol(Icons.watch_later_outlined, 'Pending Approval', '3', const Color(0xFFF59E0B)),
              _summaryCol(Icons.currency_rupee_rounded, 'Total Revenue (MTD)', '₹28,75,450', const Color(0xFF2563EB)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Revenue vs Last Month', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  SizedBox(height: 4),
                  Text('↑ 12.6%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCol(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  String _formatRevenue(double value) {
    // Basic formatting for Indian Rupees (e.g. 3,24,850)
    final String str = value.toInt().toString();
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    final other = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < other.length; i++) {
      if (i > 0 && (other.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(other[i]);
    }
    buffer.write(',');
    buffer.write(lastThree);
    return buffer.toString();
  }

  void _showAddFranchiseDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String owner = '';
    String zone = 'Connaught Place';
    String type = 'Battery Swapping';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Franchise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Franchise Name', hintText: 'Enter franchise hub name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => name = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Owner Full Name', hintText: 'Enter owner name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => owner = v!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: zone,
                    decoration: const InputDecoration(labelText: 'Zone Scope'),
                    items: const [
                      DropdownMenuItem(value: 'Connaught Place', child: Text('Connaught Place, Delhi')),
                      DropdownMenuItem(value: 'Karol Bagh', child: Text('Karol Bagh, Delhi')),
                      DropdownMenuItem(value: 'Janakpuri', child: Text('Janakpuri, Delhi')),
                    ],
                    onChanged: (val) => zone = val!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Franchise Type'),
                    items: const [
                      DropdownMenuItem(value: 'Battery Swapping', child: Text('Battery Swapping')),
                      DropdownMenuItem(value: 'Rental', child: Text('Rental')),
                      DropdownMenuItem(value: 'Battery Swapping + Rental', child: Text('Battery Swapping + Rental')),
                    ],
                    onChanged: (val) => type = val!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  // Save franchise in State
                  final newId = 'FRN-NEW-${ref.read(franchiseProvider).length + 1}';
                  ref.read(franchiseProvider.notifier).addFranchise(
                        FranchiseEntity(
                          id: newId,
                          name: name,
                          ownerName: owner,
                          zoneIds: const [],
                        ),
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully added franchise $name')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add Franchise'),
            ),
          ],
        );
      },
    );
  }

  void _viewFranchiseDetails(BuildContext context, Map<String, dynamic> frn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text(frn['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Franchise Code', frn['id'] ?? ''),
            _detailRow('Owner Name', frn['ownerName'] ?? ''),
            _detailRow('Location', frn['location'] ?? ''),
            _detailRow('Type', frn['type'] ?? ''),
            _detailRow('Status', frn['status'] ?? 'Active'),
            _detailRow('Approval Status', frn['approvalStatus'] ?? 'Approved'),
            _detailRow('Joined On', frn['joinedOn'] ?? ''),
            _detailRow('MTD Revenue', '₹${frn['revenue'] ?? 0.0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF4F46E5))),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: val),
          ],
        ),
      ),
    );
  }
}

class DoughnutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DoughnutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0, (sum, val) => sum + val);
    if (total == 0) return;

    const double strokeWidth = 8.0;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    double startAngle = -3.1415926535 / 2; // Start from top center
    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final double sweepAngle = (values[i] / total) * 3.1415926535 * 2;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DoughnutChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

class SidebarNavigation extends StatelessWidget {
  final String activeItem;
  final String? activeSubItem;

  const SidebarNavigation({
    super.key,
    required this.activeItem,
    this.activeSubItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Branding Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4F46E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'e',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'evegah',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Sidebar Menu Options List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _menuItem(context, Icons.grid_view_rounded, 'Dashboard', activeItem == 'Dashboard', AppRoutes.dashboard),
                  _menuItem(context, Icons.assignment_outlined, 'Registrations', activeItem == 'Registrations', null),
                  _menuItem(context, Icons.directions_car_outlined, 'Vehicles', activeItem == 'Vehicles', null),
                  _menuItem(context, Icons.pedal_bike_rounded, 'Riders', activeItem == 'Riders', AppRoutes.riderDashboard),
                  _menuItem(context, Icons.battery_charging_full_rounded, 'Battery', activeItem == 'Battery', AppRoutes.batteryManagement),
                  _menuItem(context, Icons.description_outlined, 'Reports', activeItem == 'Reports', null),
                  _menuItem(context, Icons.notifications_none_rounded, 'Alerts', activeItem == 'Alerts', null),
                  _menuItem(context, Icons.location_city_rounded, 'Zone Management', activeItem == 'Zone Management', AppRoutes.zones),
                  
                  // Expanded Franchise
                  _expandableMenu(
                    context,
                    Icons.storefront_rounded,
                    'Franchise',
                    activeItem == 'Franchise',
                    [
                      _subMenuItem(context, 'Franchise List', activeSubItem == 'Franchise List', AppRoutes.franchises),
                      _subMenuItem(context, 'Franchise Inward', activeSubItem == 'Franchise Inward', AppRoutes.franchises),
                      _subMenuItem(context, 'Documents', activeSubItem == 'Documents', AppRoutes.franchises),
                      _subMenuItem(context, 'Payouts', activeSubItem == 'Payouts', AppRoutes.franchises),
                    ],
                  ),
                  _menuItem(context, Icons.people_alt_outlined, 'Users & Roles', activeItem == 'Users & Roles', AppRoutes.roles),
                  _menuItem(context, Icons.eco_outlined, 'Co2 Saving', activeItem == 'Co2 Saving', null),
                  _menuItem(context, Icons.settings_outlined, 'Settings', activeItem == 'Settings', null),
                ],
              ),
            ),
          ),

          // Need Help? Support Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
            child: Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.headset_mic_outlined, size: 16, color: Color(0xFF4F46E5)),
                      SizedBox(width: 6),
                      Text('Need Help?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Raise a ticket or connect with support team.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 30),
                      side: const BorderSide(color: Color(0xFF4F46E5)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Contact Support', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Bottom profile panel card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'AV',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Akash Verma', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text('Zone Employee', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, bool active, String? route) {
    return InkWell(
      onTap: () {
        if (route != null) {
          context.go(route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label feature is coming soon!'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E293B),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _expandableMenu(BuildContext context, IconData icon, String label, bool active, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF8FAFC) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(icon, size: 18, color: active ? const Color(0xFF4F46E5) : const Color(0xFF64748B)),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
          ),
        ),
        initiallyExpanded: active,
        shape: const Border(),
        children: children,
      ),
    );
  }

  Widget _subMenuItem(BuildContext context, String label, bool active, String route) {
    return InkWell(
      onTap: () {
        context.go(route);
      },
      child: Container(
        padding: const EdgeInsets.only(left: 42, top: 8, bottom: 8, right: 12),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
