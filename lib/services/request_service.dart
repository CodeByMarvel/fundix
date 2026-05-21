import 'dart:convert';
import 'api_client.dart';

class RequestService {
  static Future<Map<String, dynamic>> createRequest({
    required Map<String, dynamic> vehicleInfo,
    required String symptoms,
    required double lat,
    required double lng,
    String? address,
    String? declaredType,
  }) async {
    final response = await ApiClient.post('/requests', {
      'vehicleInfo': vehicleInfo,
      'symptoms': symptoms,
      'location': {
        'lat': lat,
        'lng': lng,
        if (address != null) 'address': address,
        if (declaredType != null) 'declaredType': declaredType,
      },
    });

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) return body;

    throw Exception(body['error'] ?? 'Failed to create request (${response.statusCode})');
  }

  static Future<List<Map<String, dynamic>>> fetchRequests() async {
    final response = await ApiClient.get('/requests');

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['error'] ?? 'Failed to fetch requests');
  }
}
