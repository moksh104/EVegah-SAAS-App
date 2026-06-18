import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/franchise_entity.dart';

final franchiseProvider =
    StateNotifierProvider<FranchiseNotifier, List<FranchiseEntity>>(
      (ref) => FranchiseNotifier(),
    );

class FranchiseNotifier extends StateNotifier<List<FranchiseEntity>> {
  FranchiseNotifier()
    : super([
        const FranchiseEntity(
          id: '1',
          name: 'Vadodara Franchise',
          ownerName: 'Parth Patel',
          zoneIds: [],
        ),
        const FranchiseEntity(
          id: '2',
          name: 'Ahmedabad Franchise',
          ownerName: 'Daksh Parmar',
          zoneIds: [],
        ),
      ]);

  void addFranchise(FranchiseEntity franchise) {
    state = [...state, franchise];
  }

  void updateFranchise(FranchiseEntity updatedFranchise) {
    state = state.map((franchise) {
      return franchise.id == updatedFranchise.id ? updatedFranchise : franchise;
    }).toList();
  }

  void deleteFranchise(String franchiseId) {
    state = state.where((franchise) {
      return franchise.id != franchiseId;
    }).toList();
  }
}
