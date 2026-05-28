                                                              import 'dart:convert';
import 'api_client.dart';

class CustomerApiService {
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiClient.get('/customers/profile');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final b = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(b['error'] ?? 'Failed to fetch profile');
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'phone': ?phone,
    };
    final response = await ApiClient.patch('/customers/profile', body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final b = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(b['error'] ?? 'Failed to update profile');
  }

  static Future<List<Map<String, dynamic>>> getVehicles() async {
    final response = await ApiClient.get('/customers/vehicles');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    final b = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(b['error'] ?? 'Failed to fetch vehicles');
  }

  static Future<Map<String, dynamic>> addVehicle(
      Map<String, dynamic> vehicle) async {
    final response = await ApiClient.post('/customers/vehicles', vehicle);
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final b = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(b['error'] ?? 'Failed to add vehicle');
  }

  static Future<void> deleteVehicle(String vehicleId) async {
    final response = await ApiClient.delete('/customers/vehicles/$vehicleId');
    if (response.statusCode != 204) {
      final b = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(b['error'] ?? 'Failed to delete vehicle');
    }
  }
}
