import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle.dart';

class VehicleService {
  static SupabaseClient get _db => Supabase.instance.client;

  static Future<List<Vehicle>> fetchVehicles() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return [];

    final data = await _db
        .from('vehicles')
        .select()
        .eq('owner_id', uid)
        .order('created_at');

    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(Vehicle.fromJson)
        .toList();
  }

  static Future<Vehicle> insertVehicle(Vehicle vehicle) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final row = await _db
        .from('vehicles')
        .insert({'owner_id': uid, ...vehicle.toJson()})
        .select()
        .single();

    return Vehicle.fromJson(row);
  }

  static Future<void> deleteVehicle(String id) async {
    await _db.from('vehicles').delete().eq('id', id);
  }
}
