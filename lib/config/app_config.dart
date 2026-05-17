import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get clerkPublishableKey => _require('CLERK_PUBLISHABLE_KEY');
  static String get clerkFrontendApiUrl => _require('CLERK_FRONTEND_API_URL');

  // Base URL for your own backend. All authenticated business logic lives here.
  // Your backend verifies Clerk JWTs using the SECRET key — never the publishable key.
  static String get backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:3000';

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('$key is not set in .env');
    }
    return value;
  }
}
