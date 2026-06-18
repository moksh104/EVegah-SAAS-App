import '../../domain/entities/employee_entity.dart';
import '../../domain/repositories/employee_repository.dart';

/// Concrete implementation of [EmployeeRepository].
///
/// Placeholder for future API integration.
/// Currently all CRUD is handled by the in-memory Riverpod provider.
class EmployeeRepositoryImpl implements EmployeeRepository {
  const EmployeeRepositoryImpl();

  @override
  Future<List<EmployeeEntity>> getEmployees() async {
    // TODO: Connect to remote datasource
    return [];
  }

  @override
  Future<EmployeeEntity> getEmployeeById(String id) async {
    // TODO: Connect to remote datasource
    throw UnimplementedError();
  }

  @override
  Future<EmployeeEntity> createEmployee(EmployeeEntity employee) async {
    // TODO: Connect to remote datasource
    return employee;
  }

  @override
  Future<EmployeeEntity> updateEmployee(EmployeeEntity employee) async {
    // TODO: Connect to remote datasource
    return employee;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    // TODO: Connect to remote datasource
  }
}
