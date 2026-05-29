import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

// Single point of contact for all calls to the Fundi-X backend.
//
// Every request automatically carries the verified Supabase JWT and
// enforces a 15-second timeout so a sleeping Render instance can't
// block the UI indefinitely.
class ApiClient {
  static const _timeout = Duration(seconds: 15);

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
      http.get(_uri(path), headers: _headers()).timeout(_timeout);

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) async =>
      http
          .post(_uri(path), headers: _headers(), body: jsonEncode(body))
          .timeout(_timeout);

  static Future<http.Response> patch(
    String path,
    Map<String, dynamic> body,
  ) async =>
      http
          .patch(_uri(path), headers: _headers(), body: jsonEncode(body))
          .timeout(_timeout);

  static Future<http.Response> delete(String path) async =>
      http.delete(_uri(path), headers: _headers()).timeout(_timeout);
}
