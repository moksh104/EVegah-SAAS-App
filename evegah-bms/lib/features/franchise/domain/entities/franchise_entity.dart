class FranchiseEntity {
  final String id;
  final String name;
  final String ownerName;
  final List<String> zoneIds;

  const FranchiseEntity({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.zoneIds,
  });
}
