import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

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
