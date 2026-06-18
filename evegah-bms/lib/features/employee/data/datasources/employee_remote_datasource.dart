import '../models/employee_model.dart';

/// Abstract contract for the Employee remote data source.
///
/// Placeholder for future API integration.
abstract class EmployeeRemoteDatasource {
  Future<List<EmployeeModel>> getEmployees();
  Future<EmployeeModel> getEmployeeById(String id);
  Future<EmployeeModel> createEmployee(EmployeeModel employee);
  Future<EmployeeModel> updateEmployee(EmployeeModel employee);
  Future<void> deleteEmployee(String id);
}
