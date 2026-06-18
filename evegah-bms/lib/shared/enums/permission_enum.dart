enum Permission {
  viewEmployees,
  createEmployee,
  editEmployee,
  disableEmployee,

  viewZones,
  manageZones,

  viewFranchises,
  manageFranchises,

  createRide,
  extendRide,
  returnRide,

  batterySwap,

  viewReports,
  viewAnalytics,
}

extension PermissionExtension on Permission {
  String get label {
    switch (this) {
      case Permission.viewEmployees:
        return 'View Employees';

      case Permission.createEmployee:
        return 'Create Employee';

      case Permission.editEmployee:
        return 'Edit Employee';

      case Permission.disableEmployee:
        return 'Disable Employee';

      case Permission.viewZones:
        return 'View Zones';

      case Permission.manageZones:
        return 'Manage Zones';

      case Permission.viewFranchises:
        return 'View Franchises';

      case Permission.manageFranchises:
        return 'Manage Franchises';

      case Permission.createRide:
        return 'Create Ride';

      case Permission.extendRide:
        return 'Extend Ride';

      case Permission.returnRide:
        return 'Return Ride';

      case Permission.batterySwap:
        return 'BMS Swap';

      case Permission.viewReports:
        return 'View Reports';

      case Permission.viewAnalytics:
        return 'View Analytics';
    }
  }
}
