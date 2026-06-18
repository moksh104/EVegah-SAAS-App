import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/zone_entity.dart';

final zoneProvider = StateNotifierProvider<ZoneNotifier, List<ZoneEntity>>(
  (ref) => ZoneNotifier(),
);

class ZoneNotifier extends StateNotifier<List<ZoneEntity>> {
  ZoneNotifier()
    : super([
        const ZoneEntity(
          id: '1',
          name: 'Vadodara Central',
          city: 'Vadodara',
          employeeIds: [],
        ),
        const ZoneEntity(
          id: '2',
          name: 'Rajkot East',
          city: 'Rajkot',
          employeeIds: [],
        ),
      ]);

  void addZone(ZoneEntity zone) {
    state = [...state, zone];
  }

  void updateZone(ZoneEntity updatedZone) {
    state = state.map((zone) {
      return zone.id == updatedZone.id ? updatedZone : zone;
    }).toList();
  }

    void deleteZone(String zoneId) {
    state = state.where((zone) => zone.id != zoneId).toList();
  }

  void assignEmployee({
    required String zoneId,
    required String employeeId,
  }) {
    state = state.map((zone) {
      if (zone.id != zoneId) {
        return zone;
      }

      final updatedEmployees = [
        ...zone.employeeIds,
      ];

      if (!updatedEmployees.contains(employeeId)) {
        updatedEmployees.add(employeeId);
      }

      return ZoneEntity(
        id: zone.id,
        name: zone.name,
        city: zone.city,
        employeeIds: updatedEmployees,
        zoneManagerId: zone.zoneManagerId,
      );
    }).toList();
  }
}

