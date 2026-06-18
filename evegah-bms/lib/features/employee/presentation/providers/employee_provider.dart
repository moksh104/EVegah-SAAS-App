import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evegah_maintenance/shared/enums/employee_role.dart';

/// Search query state for filtering employees.
final employeeSearchQueryProvider = StateProvider<String>((ref) => '');

/// Tracks the async status of employee operations.
enum EmployeeStatus { loading, success, error }

/// State class wrapping employee list with loading/error support.
class EmployeeListState {
  final List<Map<String, dynamic>> employees;
  final EmployeeStatus status;
  final String? errorMessage;

  const EmployeeListState({
    this.employees = const [],
    this.status = EmployeeStatus.success,
    this.errorMessage,
  });

  EmployeeListState copyWith({
    List<Map<String, dynamic>>? employees,
    EmployeeStatus? status,
    String? errorMessage,
  }) {
    return EmployeeListState(
      employees: employees ?? this.employees,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// Mock employee data — the single source of truth for Phase 1.
///
/// All CRUD operations mutate this in-memory list.
/// Will be replaced with API calls in a later phase.
final employeeListProvider =
    StateNotifierProvider<EmployeeListNotifier, EmployeeListState>(
  (ref) => EmployeeListNotifier(),
);

class EmployeeListNotifier extends StateNotifier<EmployeeListState> {
  EmployeeListNotifier()
      : super(EmployeeListState(
          employees: [
            {
              'id': 'USR-001',
              'name': 'Akash Verma',
              'email': 'akash.verma@evegah.com',
              'mobile': '9876543210',
              'role': 'Zone Admin',
              'zone': 'Connaught Place Zone',
              'lastLogin': '20 May 2024, 10:30 AM',
              'isActive': true,
            },
            {
              'id': 'USR-002',
              'name': 'Rohit Sharma',
              'email': 'rohit.sharma@evegah.com',
              'mobile': '8765432109',
              'role': 'Operations Manager',
              'zone': 'Connaught Place Zone',
              'lastLogin': '20 May 2024, 09:15 AM',
              'isActive': true,
            },
            {
              'id': 'USR-003',
              'name': 'Neha Pahuja',
              'email': 'neha.pahuja@evegah.com',
              'mobile': '9654321098',
              'role': 'Franchise Manager',
              'zone': 'Connaught Place Zone',
              'lastLogin': '19 May 2024, 06:45 PM',
              'isActive': true,
            },
            {
              'id': 'USR-004',
              'name': 'Sandeep Kumar',
              'email': 'sandeep.kumar@evegah.com',
              'mobile': '9123456789',
              'role': 'Battery Technician',
              'zone': 'Multiple Zones',
              'lastLogin': '19 May 2024, 04:20 PM',
              'isActive': true,
            },
            {
              'id': 'USR-005',
              'name': 'Pooja Mehta',
              'email': 'pooja.mehta@evegah.com',
              'mobile': '9988777665',
              'role': 'Support Executive',
              'zone': 'Connaught Place Zone',
              'lastLogin': '10 May 2024, 11:10 AM',
              'isActive': false,
            },
          ],
          status: EmployeeStatus.success,
        ));

  /// Add a new employee to the list.
  void addEmployee(Map<String, dynamic> employee) {
    state = state.copyWith(status: EmployeeStatus.loading);

    final newId = (state.employees.length + 1).toString();
    final updated = [
      ...state.employees,
      {
        ...employee,
        'id': newId,
        'isActive': true,
      },
    ];

    state = state.copyWith(
      employees: updated,
      status: EmployeeStatus.success,
    );
  }

  /// Update an existing employee by ID.
  void updateEmployee(String id, Map<String, dynamic> updatedFields) {
    state = state.copyWith(status: EmployeeStatus.loading);

    final updated = state.employees.map((emp) {
      if (emp['id'] == id) {
        return {
          ...emp,
          ...updatedFields,
        };
      }
      return emp;
    }).toList();

    state = state.copyWith(
      employees: updated,
      status: EmployeeStatus.success,
    );
  }

  /// Toggle employee active/inactive status.
  void toggleStatus(String id) {
    final updated = state.employees.map((emp) {
      if (emp['id'] == id) {
        return {
          ...emp,
          'isActive': !(emp['isActive'] as bool),
        };
      }
      return emp;
    }).toList();

    state = state.copyWith(employees: updated);
  }

  /// Find a single employee by ID.
  Map<String, dynamic>? getById(String id) {
    try {
      return state.employees.firstWhere((emp) => emp['id'] == id);
    } catch (_) {
      return null;
    }
  }
}
