import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../models/app_user.dart';

class AuthResult {
  final bool success;
  final AppUser? user;
  final String? sessionToken;
  final String? error;

  const AuthResult._({
    required this.success,
    this.user,
    this.sessionToken,
    this.error,
  });

  factory AuthResult.ok(AppUser user, String token) =>
      AuthResult._(success: true, user: user, sessionToken: token);

  factory AuthResult.fail(String error) =>
      AuthResult._(success: false, error: error);
}

class AuthService {
  static const _storage = FlutterSecureStorage();

  // ---------- public API ----------

  static Future<AuthResult> signIn(String email, String password) async {
    final validationError = _validateCredentials(email, password);
    if (validationError != null) return AuthResult.fail(validationError);

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.clerkFrontendApiUrl}/v1/client/sign_ins'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.clerkPublishableKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'identifier': email.trim().toLowerCase(),
          'strategy': 'password',
          'password': password,
        },
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        return AuthResult.fail(_extractError(data, 'Incorrect email or password'));
      }

      final signIn = data['response'] as Map<String, dynamic>;
      final status = signIn['status'] as String;

      if (status == 'needs_first_factor') {
        final signInId = signIn['id'] as String;
        final res2 = await http.post(
          Uri.parse(
              '${AppConfig.clerkFrontendApiUrl}/v1/client/sign_ins/$signInId/attempt_first_factor'),
          headers: {
            'Authorization': 'Bearer ${AppConfig.clerkPublishableKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {'strategy': 'password', 'password': password},
        );
        final data2 = jsonDecode(res2.body) as Map<String, dynamic>;
        if (res2.statusCode != 200) {
          return AuthResult.fail(_extractError(data2, 'Incorrect email or password'));
        }
        return _extractSession(data2);
      }

      if (status == 'complete') return _extractSession(data);
      return AuthResult.fail('Unexpected sign-in status: $status');
    } catch (e) {
      return AuthResult.fail('Connection error. Please try again.');
    }
  }

  static Future<AuthResult> signUp(
      String email, String password, UserRole role) async {
    final validationError = _validateCredentials(email, password);
    if (validationError != null) return AuthResult.fail(validationError);

    try {
      // SECURITY NOTE — unsafe_metadata is client-writable.
      // This means any attacker can call the Clerk API directly and set
      // role: 'mechanic' regardless of what they actually are.
      //
      // The correct fix (requires your backend):
      //   1. Sign up without role metadata
      //   2. Call POST /api/users/role on your backend with the JWT
      //   3. Backend verifies the JWT with Clerk's secret key
      //   4. Backend writes role to public_metadata via Clerk Backend API
      //   5. Future JWTs carry the server-assigned role in public_metadata
      //
      // Once the backend exists, remove unsafe_metadata from this body entirely.
      final res = await http.post(
        Uri.parse('${AppConfig.clerkFrontendApiUrl}/v1/client/sign_ups'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.clerkPublishableKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email_address': email.trim().toLowerCase(),
          'password': password,
          'unsafe_metadata': jsonEncode({'role': role.name}),
        },
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode != 200) {
        return AuthResult.fail(_extractError(data, 'Sign up failed'));
      }

      final signUp = data['response'] as Map<String, dynamic>;
      final status = signUp['status'] as String;

      if (status == 'missing_requirements') {
        return AuthResult.fail(
          'Email verification is enabled. Disable it in Clerk Dashboard:\n'
          'User & Authentication → Email → Verification → None',
        );
      }
      if (status != 'complete') {
        return AuthResult.fail('Sign up status: $status');
      }

      return _extractSession(data);
    } catch (e) {
      return AuthResult.fail('Connection error. Please try again.');
    }
  }

  static Future<void> signOut() async {
    final sessionId = await _storage.read(key: 'session_id');
    final token = await _storage.read(key: 'session_token');

    if (sessionId != null && token != null) {
      try {
        await http.delete(
          Uri.parse(
              '${AppConfig.clerkFrontendApiUrl}/v1/client/sessions/$sessionId'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {}
    }

    await _storage.deleteAll();
  }

  static Future<AppUser?> restoreSession() async {
    final token = await _storage.read(key: 'session_token');
    final userId = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    final name = await _storage.read(key: 'user_name');
    final roleStr = await _storage.read(key: 'user_role');

    if (token == null || userId == null || email == null) return null;

    // Validate the session is still live with Clerk.
    // TODO: Replace this with a call to your own backend's /api/me endpoint,
    // which verifies the JWT server-side and returns authoritative user data.
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.clerkFrontendApiUrl}/v1/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode != 200) {
        await _storage.deleteAll();
        return null;
      }
    } catch (_) {
      return null;
    }

    final role = roleStr == 'mechanic' ? UserRole.mechanic : UserRole.customer;
    return AppUser(id: userId, name: name ?? email, email: email, role: role);
  }

  static Future<String?> getSessionToken() =>
      _storage.read(key: 'session_token');

  // ---------- private helpers ----------

  static String? _validateCredentials(String email, String password) {
    if (email.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'Enter a valid email address';
    }
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static Future<AuthResult> _extractSession(Map<String, dynamic> data) async {
    try {
      final client = data['client'] as Map<String, dynamic>;
      final sessions = client['sessions'] as List;

      if (sessions.isEmpty) return AuthResult.fail('No active session');

      final session = sessions.first as Map<String, dynamic>;
      final jwt = (session['last_active_token'] as Map<String, dynamic>)['jwt']
          as String;
      final sessionId = session['id'] as String;
      final userMap = session['user'] as Map<String, dynamic>;

      final userId = userMap['id'] as String;
      final emails = userMap['email_addresses'] as List;
      final email =
          (emails.first as Map<String, dynamic>)['email_address'] as String;
      final firstName = (userMap['first_name'] as String?) ?? '';
      final lastName = (userMap['last_name'] as String?) ?? '';
      final name = '$firstName $lastName'.trim().isEmpty
          ? email.split('@').first
          : '$firstName $lastName'.trim();

      // TODO: Once the backend sets public_metadata, read role from there:
      //   final metadata = (userMap['public_metadata'] as Map<String, dynamic>?) ?? {};
      final metadata =
          (userMap['unsafe_metadata'] as Map<String, dynamic>?) ?? {};
      final roleStr = metadata['role'] as String? ?? 'customer';
      final role =
          roleStr == 'mechanic' ? UserRole.mechanic : UserRole.customer;

      final user = AppUser(id: userId, name: name, email: email, role: role);

      await Future.wait([
        _storage.write(key: 'session_id', value: sessionId),
        _storage.write(key: 'session_token', value: jwt),
        _storage.write(key: 'user_id', value: userId),
        _storage.write(key: 'user_email', value: email),
        _storage.write(key: 'user_name', value: name),
        _storage.write(key: 'user_role', value: role.name),
      ]);

      return AuthResult.ok(user, jwt);
    } catch (e) {
      return AuthResult.fail('Failed to read session response: $e');
    }
  }

  static String _extractError(Map<String, dynamic> data, String fallback) {
    final errors = data['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      return (errors.first as Map<String, dynamic>)['message'] as String? ??
          fallback;
    }
    return fallback;
  }
}
