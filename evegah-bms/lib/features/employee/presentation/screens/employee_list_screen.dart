import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evegah_maintenance/app/routes.dart';
import '../providers/employee_provider.dart';
import '../widgets/employee_card.dart';

class EmployeeListScreen extends ConsumerWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(employeeListProvider);
    final searchQuery = ref.watch(employeeSearchQueryProvider);

    // Filter employees based on search
    final filtered = searchQuery.isEmpty
        ? state.employees
        : state.employees.where((e) {
            final q = searchQuery.toLowerCase();
            return e['name'].toString().toLowerCase().contains(q) ||
                e['email'].toString().toLowerCase().contains(q) ||
                e['role'].toString().toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.employeeCreate);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                ref.read(employeeSearchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Search Employee',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildContent(state, filtered, context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    EmployeeListState state,
    List<Map<String, dynamic>> filtered,
    BuildContext context,
    WidgetRef ref,
  ) {
    // Loading state
    if (state.status == EmployeeStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (state.status == EmployeeStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Something went wrong',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No Employees Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search or add a new employee.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Success — show list
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final employee = filtered[index];

        return EmployeeCard(
          name: employee['name'] as String,
          email: employee['email'] as String,
          role: employee['role'] as String,
          isActive: employee['isActive'] as bool,
          onTap: () {
            context.push(
              AppRoutes.employeeById(employee['id'] as String),
            );
          },
        );
      },
    );
  }
}
