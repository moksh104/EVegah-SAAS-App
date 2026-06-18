import '../../domain/entities/franchise_entity.dart';

class FranchiseModel extends FranchiseEntity {
  const FranchiseModel({
    required super.id,
    required super.name,
    required super.ownerName,
    required super.zoneIds,
  });

  factory FranchiseModel.fromJson(Map<String, dynamic> json) {
    return FranchiseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ownerName: json['ownerName'] ?? '',
      zoneIds: List<String>.from(json['zoneIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'ownerName': ownerName, 'zoneIds': zoneIds};
  }
}
