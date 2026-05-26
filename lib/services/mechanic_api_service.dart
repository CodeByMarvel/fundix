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

  static Future<void> updateProfile({
    String? name,
    String? bio,
    String? location,
  }) async {
    final body = <String, dynamic>{
      'name': ?name,
      'bio': ?bio,
      'location': ?location,
    };
    final response = await ApiClient.patch('/mechanics/profile', body);
    if (response.statusCode != 200) {
      final b = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(b['error'] ?? 'Failed to update profile');
    }
  }

  static Future<void> updateSkills(List<String> skills) async {
    final response = await ApiClient.patch('/mechanics/skills', {'skills': skills});
    if (response.statusCode != 200) {
      final b = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(b['error'] ?? 'Failed to update skills');
    }
  }

  static Future<List<Map<String, dynamic>>> getServices() async {
    final response = await ApiClient.get('/mechanics/services');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    final b = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(b['error'] ?? 'Failed to fetch services');
  }

  static Future<void> updateServices(List<Map<String, dynamic>> services) async {
    final response = await ApiClient.patch('/mechanics/services', {'services': services});
    if (response.statusCode != 200) {
      final b = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(b['error'] ?? 'Failed to update services');
    }
  }

  static Future<List<Map<String, dynamic>>> getReviews() async {
    final response = await ApiClient.get('/mechanics/reviews');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    final b = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(b['error'] ?? 'Failed to fetch reviews');
  }
}
