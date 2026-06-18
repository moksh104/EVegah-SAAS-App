import '../entities/employee_entity.dart';

/// Contract definition for Employee Repository in the Domain layer.
///
/// Will be implemented with real API calls in a later phase.
/// For now, all CRUD is handled by the in-memory provider.
abstract class EmployeeRepository {
  Future<List<EmployeeEntity>> getEmployees();
  Future<EmployeeEntity> getEmployeeById(String id);
  Future<EmployeeEntity> createEmployee(EmployeeEntity employee);
  Future<EmployeeEntity> updateEmployee(EmployeeEntity employee);
  Future<void> deleteEmployee(String id);
}
