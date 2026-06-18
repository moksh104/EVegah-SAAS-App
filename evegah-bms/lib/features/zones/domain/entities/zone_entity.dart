class ZoneEntity {
  final String id;
  final String name;
  final String city;
  final List<String> employeeIds;
  final String? zoneManagerId;

  const ZoneEntity({
    required this.id,
    required this.name,
    required this.city,
    required this.employeeIds,
    this.zoneManagerId,
  });
}
