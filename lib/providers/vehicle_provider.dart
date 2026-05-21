import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class VehicleNotifier extends StateNotifier<List<Vehicle>> {
  VehicleNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    try {
      final vehicles = await VehicleService.fetchVehicles();
      if (mounted) state = vehicles;
    } catch (_) {
      // No-op — user starts with empty list, can add vehicles manually
    }
  }

  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    final saved = await VehicleService.insertVehicle(vehicle);
    state = [...state, saved];
    return saved;
  }

  Future<void> removeVehicle(String id) async {
    await VehicleService.deleteVehicle(id);
    state = state.where((v) => v.id != id).toList();
  }
}

final vehicleProvider =
    StateNotifierProvider<VehicleNotifier, List<Vehicle>>(
  (ref) => VehicleNotifier(),
);

// Null by default — no vehicle pre-selected until user picks one
final selectedVehicleIdProvider = StateProvider<String?>((ref) => null);
