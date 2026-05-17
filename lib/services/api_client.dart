import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

// Single point of contact for all calls to the Fundix backend.
//
// Every request automatically carries the verified Clerk JWT in the
// Authorization header. The backend MUST verify this token with Clerk's
// Backend API using the SECRET key (never the publishable key, which lives
// only in .env and never on any server you control).
//
// Pattern on your backend:
//   1. Receive Bearer token from this client
//   2. Verify with Clerk SDK: clerk.verifyToken(token)
//   3. Read role from public_metadata (server-assigned, not client-writable)
//   4. Enforce authorization and return business data
class ApiClient {
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'session_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path) =>
      Uri.parse('${AppConfig.backendUrl}$path');

  static Future<http.Response> get(String path) async =>
      http.get(_uri(path), headers: await _headers());

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) async =>
      http.post(_uri(path),
          headers: await _headers(), body: jsonEncode(body));

  static Future<http.Response> patch(
    String path,
    Map<String, dynamic> body,
  ) async =>
      http.patch(_uri(path),
          headers: await _headers(), body: jsonEncode(body));

  static Future<http.Response> delete(String path) async =>
      http.delete(_uri(path), headers: await _headers());
}
