import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../shared/enums/permission_enum.dart';
import '../../domain/entities/role_entity.dart';
import '../../../employee/presentation/providers/employee_provider.dart';
import '../providers/role_provider.dart';

class RoleListScreen extends ConsumerStatefulWidget {
  const RoleListScreen({super.key});

  @override
  ConsumerState<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends ConsumerState<RoleListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedRole = 'All Roles';
  String _selectedStatus = 'All Status';
  String _selectedZone = 'All Zones';

  int _activeTab = 0; // 0 for Users, 1 for Roles

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
      _selectedRole = 'All Roles';
      _selectedStatus = 'All Status';
      _selectedZone = 'All Zones';
    });
  }

  void _scrollToSection(double offset) {
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    final employeesState = ref.watch(employeeListProvider);
    final rolesState = ref.watch(roleProvider);

    // Apply filters
    final filteredUsers = employeesState.employees.where((emp) {
      final name = (emp['name'] as String? ?? '').toLowerCase();
      final email = (emp['email'] as String? ?? '').toLowerCase();
      final mobile = (emp['mobile'] as String? ?? '').toLowerCase();
      final id = (emp['id'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          email.contains(query) ||
          mobile.contains(query) ||
          id.contains(query);

      final matchesRole = _selectedRole == 'All Roles' || emp['role'] == _selectedRole;

      final matchesStatus = _selectedStatus == 'All Status' ||
          (_selectedStatus == 'Active' && emp['isActive'] == true) ||
          (_selectedStatus == 'Inactive' && emp['isActive'] == false);

      final matchesZone = _selectedZone == 'All Zones' || emp['zone'] == _selectedZone;

      return matchesSearch && matchesRole && matchesStatus && matchesZone;
    }).toList();

    // Statistics counts
    final totalUsers = employeesState.employees.length;
    final activeUsers = employeesState.employees.where((e) => e['isActive'] == true).length;
    final inactiveUsers = employeesState.employees.where((e) => e['isActive'] == false).length;
    final totalRolesCount = rolesState.length;

    Widget dashboardBody = _buildDashboardContent(
      context,
      filteredUsers,
      rolesState,
      totalUsers,
      activeUsers,
      inactiveUsers,
      totalRolesCount,
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Row(
          children: [
            const SizedBox(
              width: 260,
              child: SidebarNavigation(activeItem: 'Users & Roles', activeSubItem: 'Users'),
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
          child: SidebarNavigation(activeItem: 'Users & Roles', activeSubItem: 'Users'),
        ),
        body: dashboardBody,
      );
    }
  }

  Widget _buildDashboardContent(
    BuildContext context,
    List<Map<String, dynamic>> filteredUsers,
    List<RoleEntity> roles,
    int totalUsers,
    int activeUsers,
    int inactiveUsers,
    int totalRolesCount,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Row
          _buildHeader(context, isDesktop),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Page Content
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
                        'Settings',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                      Text(
                        'Users & Roles',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                      Text(
                        'Users',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title and Subtext
                  const Text(
                    'User & Role Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage platform users and roles, permissions and access',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Metrics Cards Row
                  _buildMetricsRow(totalUsers, activeUsers, inactiveUsers, totalRolesCount),
                  const SizedBox(height: 24),

                  // Tab switcher + Add User aligned row
                  Row(
                    children: [
                      // Tab Bar Button Group
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _buildTabButton('Users', _activeTab == 0, () {
                              setState(() {
                                _activeTab = 0;
                              });
                              _scrollToSection(0);
                            }),
                            _buildTabButton('Roles', _activeTab == 1, () {
                              setState(() {
                                _activeTab = 1;
                              });
                              // Jump to Roles Section
                              _scrollToSection(800.0);
                            }),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Add User action button
                      ElevatedButton.icon(
                        onPressed: () => _showAddUserDialog(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 40),
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Add User',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search and Filters Bar (Users)
                  _buildFiltersBar(roles),
                  const SizedBox(height: 16),

                  // Users Section card containing Table & Pagination
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
                        _buildUsersTable(filteredUsers),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildPaginationRow(filteredUsers.length, 128, 'users'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Roles Section Title and Add Role button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Roles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddRoleDialog(context),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 40),
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Add Role',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Roles Section card containing Table & Pagination
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
                        _buildRolesTable(roles),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        _buildPaginationRow(roles.length, 9, 'roles'),
                      ],
                    ),
                  ),
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
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
            const SizedBox(width: 8),
          ],
          // Profile Indicator
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
                'Zone Admin',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const Spacer(),
          // Location Selector Dropdown Card
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
          // Notification Bell
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

  Widget _buildMetricsRow(int total, int active, int inactive, int totalRoles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 36) / 4;
        final isCompact = constraints.maxWidth < 800;

        if (isCompact) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _metricCard('Total Users', total.toString(), '↑ 12.5% vs last 30 days', const Color(0xFFEEF2FF), const Color(0xFF4F46E5), Icons.person_add_alt_1_outlined, true),
              _metricCard('Active Users', active.toString(), '↑ 10.3% vs last 30 days', const Color(0xFFECFDF5), const Color(0xFF059669), Icons.verified_user_outlined, true),
              _metricCard('Inactive Users', inactive.toString(), '↓ 5.6% vs last 30 days', const Color(0xFFFFF7ED), const Color(0xFFEA580C), Icons.person_off_outlined, false),
              _metricCard('Total Roles', totalRoles.toString(), 'No change vs last 30 days', const Color(0xFFEFF6FF), const Color(0xFF2563EB), Icons.security_rounded, null),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: cardWidth, child: _metricCard('Total Users', total.toString(), '↑ 12.5% vs last 30 days', const Color(0xFFEEF2FF), const Color(0xFF4F46E5), Icons.person_add_alt_1_outlined, true)),
            SizedBox(width: cardWidth, child: _metricCard('Active Users', active.toString(), '↑ 10.3% vs last 30 days', const Color(0xFFECFDF5), const Color(0xFF059669), Icons.verified_user_outlined, true)),
            SizedBox(width: cardWidth, child: _metricCard('Inactive Users', inactive.toString(), '↓ 5.6% vs last 30 days', const Color(0xFFFFF7ED), const Color(0xFFEA580C), Icons.person_off_outlined, false)),
            SizedBox(width: cardWidth, child: _metricCard('Total Roles', totalRoles.toString(), 'No change vs last 30 days', const Color(0xFFEFF6FF), const Color(0xFF2563EB), Icons.security_rounded, null)),
          ],
        );
      },
    );
  }

  Widget _metricCard(String label, String value, String trend, Color bgColor, Color iconColor, IconData icon, bool? positive) {
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
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
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
          const SizedBox(height: 4),
          Row(
            children: [
              if (positive == true)
                const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF16A34A))
              else if (positive == false)
                const Icon(Icons.arrow_downward_rounded, size: 12, color: Color(0xFFDC2626)),
              if (positive != null) const SizedBox(width: 3),
              Expanded(
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: positive == true
                        ? const Color(0xFF16A34A)
                        : (positive == false ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                  ),
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

  Widget _buildTabButton(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersBar(List<RoleEntity> roles) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 750;

          final searchField = Expanded(
            flex: isCompact ? 0 : 3,
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
                        hintText: 'Search by name, email or mobile',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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
            _buildDropdownFilter('All Roles', _selectedRole, roles.map((e) => e.name).toList(), (val) {
              setState(() {
                _selectedRole = val!;
              });
            }),
            _buildDropdownFilter('All Status', _selectedStatus, ['Active', 'Inactive'], (val) {
              setState(() {
                _selectedStatus = val!;
              });
            }),
            _buildDropdownFilter('All Zones', _selectedZone, ['Connaught Place Zone', 'Multiple Zones'], (val) {
              setState(() {
                _selectedZone = val!;
              });
            }),
            // Reset Button
            OutlinedButton.icon(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 36),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF4F46E5)),
              label: const Text(
                'Reset',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
            ),
          ];

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: searchField,
                ),
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
              ...filters.map((widget) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: widget,
                  )),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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

  Widget _buildUsersTable(List<Map<String, dynamic>> users) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 32,
        headingRowHeight: 44,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 56,
        columns: const [
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Zone / Scope')),
          DataColumn(label: Text('Mobile / Email')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Last Login')),
          DataColumn(label: Text('Actions')),
        ],
        rows: users.map((emp) {
          final initials = _getInitials(emp['name'] ?? '');
          final String roleStr = emp['role'] ?? 'Zone Admin';
          final String zoneStr = emp['zone'] ?? 'Connaught Place Zone';
          final String mobileStr = emp['mobile'] ?? '';
          final String emailStr = emp['email'] ?? '';
          final bool active = emp['isActive'] ?? true;
          final String lastLoginStr = emp['lastLogin'] ?? '20 May 2024, 10:30 AM';

          // Color themes for roles
          Color roleBg = const Color(0xFFEEF2FF);
          Color roleText = const Color(0xFF4F46E5);

          if (roleStr == 'Operations Manager') {
            roleBg = const Color(0xFFEFF6FF);
            roleText = const Color(0xFF2563EB);
          } else if (roleStr == 'Franchise Manager') {
            roleBg = const Color(0xFFFFF7ED);
            roleText = const Color(0xFFEA580C);
          } else if (roleStr == 'Battery Technician') {
            roleBg = const Color(0xFFECFDF5);
            roleText = const Color(0xFF059669);
          } else if (roleStr == 'Support Executive') {
            roleBg = const Color(0xFFFDF2F8);
            roleText = const Color(0xFFDB2777);
          }

          // Avatar Color matching
          Color avatarBg = const Color(0xFFEEF2FF);
          Color avatarText = const Color(0xFF4F46E5);
          if (roleStr == 'Operations Manager') {
            avatarBg = const Color(0xFFECFDF5);
            avatarText = const Color(0xFF059669);
          } else if (roleStr == 'Franchise Manager') {
            avatarBg = const Color(0xFFFFF7ED);
            avatarText = const Color(0xFFEA580C);
          } else if (roleStr == 'Battery Technician') {
            avatarBg = const Color(0xFFEFF6FF);
            avatarText = const Color(0xFF2563EB);
          } else if (roleStr == 'Support Executive') {
            avatarBg = const Color(0xFFFDF2F8);
            avatarText = const Color(0xFFDB2777);
          }

          return DataRow(cells: [
            // User cell
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: avatarText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp['name'] ?? '',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'ID: ${emp['id']}',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Role Cell
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: roleBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  roleStr,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: roleText),
                ),
              ),
            ),
            // Zone scope
            DataCell(
              Text(
                zoneStr,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            // Mobile & email
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '+91 $mobileStr',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    emailStr,
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            // Status Active/Inactive
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  active ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: active ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ),
            // Last Login
            DataCell(
              Text(
                lastLoginStr,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ),
            // Actions Buttons
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF64748B)),
                    onPressed: () => _viewUserDetails(context, emp),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                    onPressed: () => _editUser(context, emp),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 14, color: Color(0xFF64748B)),
                    onPressed: () => _showMoreUserActions(context, emp),
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

  Widget _buildRolesTable(List<RoleEntity> roles) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 48,
        headingRowHeight: 44,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 52,
        columns: const [
          DataColumn(label: Text('Role Name')),
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Users')),
          DataColumn(label: Text('Last Updated')),
          DataColumn(label: Text('Actions')),
        ],
        rows: roles.map((role) {
          int usersCount = 12; // Mocks
          if (role.name == 'Operations Manager') {
            usersCount = 18;
          } else if (role.name == 'Franchise Manager') {
            usersCount = 9;
          } else if (role.name == 'Battery Technician') {
            usersCount = 37;
          } else if (role.name == 'Support Executive') {
            usersCount = 22;
          }

          String lastUpdated = '15 May 2024';
          if (role.name == 'Operations Manager') {
            lastUpdated = '12 May 2024';
          } else if (role.name == 'Franchise Manager') {
            lastUpdated = '10 May 2024';
          } else if (role.name == 'Battery Technician') {
            lastUpdated = '08 May 2024';
          } else if (role.name == 'Support Executive') {
            lastUpdated = '05 May 2024';
          }

          return DataRow(cells: [
            DataCell(
              Text(
                role.name,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
            DataCell(
              SizedBox(
                width: 320,
                child: Text(
                  _getRoleDescription(role.name),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            DataCell(
              Text(
                usersCount.toString(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            DataCell(
              Text(
                lastUpdated,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 14, color: Color(0xFF64748B)),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, size: 14, color: Color(0xFF64748B)),
                    onPressed: () => _showMoreRoleActions(context, role),
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

  Widget _buildPaginationRow(int showing, int total, String itemsLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            'Showing 1 to $showing of $total $itemsLabel',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const Spacer(),
          // Page numbers indicators
          _buildPageArrow(Icons.first_page_rounded, false),
          _buildPageArrow(Icons.chevron_left_rounded, false),
          _buildPageNumber('1', true),
          if (itemsLabel == 'users') ...[
            _buildPageNumber('2', false),
            _buildPageNumber('3', false),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text('...', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ),
            _buildPageNumber('26', false),
          ] else ...[
            _buildPageNumber('2', false),
          ],
          _buildPageArrow(Icons.chevron_right_rounded, true),
          _buildPageArrow(Icons.last_page_rounded, true),
          const SizedBox(width: 12),
          // Dropdown 5 / page
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
                value: 5,
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildPageArrow(IconData icon, bool enabled) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(
        icon,
        size: 14,
        color: enabled ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String _getRoleDescription(String roleName) {
    switch (roleName) {
      case 'Zone Admin':
        return 'Full access to all zone operations, users, riders, batteries and reports.';
      case 'Operations Manager':
        return 'Manage daily operations, assignments, and rider activities.';
      case 'Franchise Manager':
        return 'Manage franchise onboarding, performance and operations.';
      case 'Battery Technician':
        return 'Access to battery swap, inventory and maintenance operations.';
      case 'Support Executive':
        return 'Handle rider support tickets and communication.';
      default:
        return 'Custom administrative permissions and system options.';
    }
  }

  // Interactive dialogs
  void _showAddUserDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String mobile = '';
    String role = 'Zone Admin';
    String zone = 'Connaught Place Zone';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Enter name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => name = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email Address', hintText: 'Enter email'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => email = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Mobile Number', hintText: 'Enter 10-digit number'),
                    maxLength: 10,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.length != 10 ? 'Enter exactly 10 digits' : null,
                    onSaved: (v) => mobile = v!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'System Role'),
                    items: const [
                      DropdownMenuItem(value: 'Zone Admin', child: Text('Zone Admin')),
                      DropdownMenuItem(value: 'Operations Manager', child: Text('Operations Manager')),
                      DropdownMenuItem(value: 'Franchise Manager', child: Text('Franchise Manager')),
                      DropdownMenuItem(value: 'Battery Technician', child: Text('Battery Technician')),
                      DropdownMenuItem(value: 'Support Executive', child: Text('Support Executive')),
                    ],
                    onChanged: (val) => role = val!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: zone,
                    decoration: const InputDecoration(labelText: 'Zone Scope'),
                    items: const [
                      DropdownMenuItem(value: 'Connaught Place Zone', child: Text('Connaught Place Zone')),
                      DropdownMenuItem(value: 'Multiple Zones', child: Text('Multiple Zones')),
                    ],
                    onChanged: (val) => zone = val!,
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
                  // Save user in state
                  ref.read(employeeListProvider.notifier).addEmployee({
                    'name': name,
                    'email': email,
                    'mobile': mobile,
                    'role': role,
                    'zone': zone,
                    'lastLogin': '1 min ago',
                    'isActive': true,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully added user $name')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add User'),
            ),
          ],
        );
      },
    );
  }

  void _showAddRoleDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          content: Form(
            key: formKey,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Role Name', hintText: 'Enter role name (e.g. Inspector)'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => name = v!,
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
                  // Save role in provider
                  ref.read(roleProvider.notifier).addRole(
                        RoleEntity(
                          id: (ref.read(roleProvider).length + 1).toString(),
                          name: name,
                          permissions: const [Permission.viewEmployees],
                        ),
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully added role $name')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add Role'),
            ),
          ],
        );
      },
    );
  }

  void _viewUserDetails(BuildContext context, Map<String, dynamic> emp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person_pin_rounded, color: Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Text(emp['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('User ID', emp['id'] ?? ''),
            _detailRow('Email', emp['email'] ?? ''),
            _detailRow('Mobile', '+91 ${emp['mobile'] ?? ""}'),
            _detailRow('Role', emp['role'] ?? ''),
            _detailRow('Zone Scope', emp['zone'] ?? ''),
            _detailRow('Status', (emp['isActive'] ?? true) ? 'Active' : 'Inactive'),
            _detailRow('Last Login', emp['lastLogin'] ?? ''),
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

  void _editUser(BuildContext context, Map<String, dynamic> emp) {
    final formKey = GlobalKey<FormState>();
    String name = emp['name'] ?? '';
    String email = emp['email'] ?? '';
    String mobile = emp['mobile'] ?? '';
    String role = emp['role'] ?? 'Zone Admin';
    String zone = emp['zone'] ?? 'Connaught Place Zone';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit User details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => name = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: email,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => email = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: mobile,
                    decoration: const InputDecoration(labelText: 'Mobile Number'),
                    maxLength: 10,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.length != 10 ? 'Enter exactly 10 digits' : null,
                    onSaved: (v) => mobile = v!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'System Role'),
                    items: const [
                      DropdownMenuItem(value: 'Zone Admin', child: Text('Zone Admin')),
                      DropdownMenuItem(value: 'Operations Manager', child: Text('Operations Manager')),
                      DropdownMenuItem(value: 'Franchise Manager', child: Text('Franchise Manager')),
                      DropdownMenuItem(value: 'Battery Technician', child: Text('Battery Technician')),
                      DropdownMenuItem(value: 'Support Executive', child: Text('Support Executive')),
                    ],
                    onChanged: (val) => role = val!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: zone,
                    decoration: const InputDecoration(labelText: 'Zone Scope'),
                    items: const [
                      DropdownMenuItem(value: 'Connaught Place Zone', child: Text('Connaught Place Zone')),
                      DropdownMenuItem(value: 'Multiple Zones', child: Text('Multiple Zones')),
                    ],
                    onChanged: (val) => zone = val!,
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
                  // Update user state
                  ref.read(employeeListProvider.notifier).updateEmployee(emp['id'], {
                    'name': name,
                    'email': email,
                    'mobile': mobile,
                    'role': role,
                    'zone': zone,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully updated user $name')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showMoreUserActions(BuildContext context, Map<String, dynamic> emp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final active = emp['isActive'] ?? true;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(active ? Icons.person_off_rounded : Icons.person_add_rounded, color: const Color(0xFF64748B)),
                title: Text(active ? 'Disable User Session' : 'Enable User Session', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                onTap: () {
                  ref.read(employeeListProvider.notifier).toggleStatus(emp['id']);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Toggled status for ${emp['name']}')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text('Delete User', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteUser(context, emp);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, Map<String, dynamic> emp) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete user ${emp['name']} from the system?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted user ${emp['name']}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMoreRoleActions(BuildContext context, RoleEntity role) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                title: const Text('Delete Role', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                onTap: () {
                  ref.read(roleProvider.notifier).deleteRole(role.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully deleted role ${role.name}')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
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
                  _menuItem(context, Icons.storefront_rounded, 'Franchise', activeItem == 'Franchise', AppRoutes.franchises),
                  _menuItem(context, Icons.description_outlined, 'Reports', activeItem == 'Reports', null),
                  _menuItem(context, Icons.notifications_none_rounded, 'Alerts', activeItem == 'Alerts', null),
                  _menuItem(context, Icons.location_city_rounded, 'Zone Management', activeItem == 'Zone Management', AppRoutes.zones),
                  
                  // Expanded Users & Roles
                  _expandableMenu(
                    context,
                    Icons.people_alt_outlined,
                    'Users & Roles',
                    activeItem == 'Users & Roles',
                    [
                      _subMenuItem(context, 'Users', activeSubItem == 'Users', AppRoutes.roles),
                      _subMenuItem(context, 'Roles', activeSubItem == 'Roles', AppRoutes.roles),
                    ],
                  ),
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
                    Text('Zone Admin', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
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
