import '../../domain/entities/zone_entity.dart';

class ZoneModel extends ZoneEntity {
  const ZoneModel({
    required super.id,
    required super.name,
    required super.city,
    required super.employeeIds,
    super.zoneManagerId,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      employeeIds: List<String>.from(json['employeeIds'] ?? []),
      zoneManagerId: json['zoneManagerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'employeeIds': employeeIds,
      'zoneManagerId': zoneManagerId,
    };
  }
}
