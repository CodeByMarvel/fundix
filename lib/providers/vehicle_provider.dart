import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';

class VehicleNotifier extends StateNotifier<List<Vehicle>> {
  VehicleNotifier() : super(_mockVehicles);

  void addVehicle(Vehicle vehicle) => state = [...state, vehicle];

  void removeVehicle(String id) =>
      state = state.where((v) => v.id != id).toList();

  static const _mockVehicles = [
    Vehicle(
      id: 'v_001',
      brand: 'Toyota',
      model: 'Premio',
      year: 2012,
      engine: '2ZR',
      fuelType: 'Petrol',
      transmission: 'Auto',
      bodyType: 'Sedan',
      nickname: 'Daily Car',
    ),
    Vehicle(
      id: 'v_002',
      brand: 'Toyota',
      model: 'Noah',
      year: 2015,
      fuelType: 'Petrol',
      transmission: 'Auto',
      bodyType: 'Van',
      nickname: 'Family Car',
    ),
  ];
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, List<Vehicle>>(
  (ref) => VehicleNotifier(),
);

final selectedVehicleIdProvider = StateProvider<String?>((ref) => 'v_001');
