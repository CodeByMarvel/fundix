import 'dart:convert';
import 'api_client.dart';

class MechanicApiService {
  static Future<void> setAvailability(
    bool isOnline, {
    double? lat,
    double? lng,
  }) async {
    final body = <String, dynamic>{'isOnline': isOnline};
    if (isOnline && lat != null && lng != null) {
      body['position'] = {'lat': lat, 'lng': lng};
    }

    final response = await ApiClient.patch('/mechanics/availability', body);
    if (response.statusCode != 200) {
      final b = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(b['error'] ?? 'Failed to update availability');
    }
  }

  static Future<void> updateLocation(double lat, double lng) async {
    final response = await ApiClient.patch('/mechanics/location', {
      'lat': lat,
      'lng': lng,
    });
    if (response.statusCode != 200) {
      final b = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(b['error'] ?? 'Failed to update location');
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiClient.get('/mechanics');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final b = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(b['error'] ?? 'Failed to fetch mechanic profile');
  }
}
