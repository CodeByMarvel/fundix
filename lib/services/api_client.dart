import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

// Single point of contact for all calls to the Fundix backend.
//
// Every request automatically carries the verified Supabase JWT in the
// Authorization header. The backend MUST verify this token using the Supabase
// JWT secret (or the Supabase admin client), never the anon key.
//
// Pattern on your backend:
//   1. Receive Bearer token from this client
//   2. Verify with Supabase: supabase.auth.getUser(token)
//   3. Read role from user.user_metadata (or a roles table for production)
//   4. Enforce authorization and return business data
class ApiClient {
  static Map<String, String> _headers() {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Uri _uri(String path) =>
      Uri.parse('${AppConfig.backendUrl}$path');

  static Future<http.Response> get(String path) async =>
      http.get(_uri(path), headers: _headers());

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) async =>
      http.post(_uri(path), headers: _headers(), body: jsonEncode(body));

  static Future<http.Response> patch(
    String path,
    Map<String, dynamic> body,
  ) async =>
      http.patch(_uri(path), headers: _headers(), body: jsonEncode(body));

  static Future<http.Response> delete(String path) async =>
      http.delete(_uri(path), headers: _headers());
}
