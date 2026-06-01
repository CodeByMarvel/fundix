import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/mechanic_api_service.dart';

const _kStatusKey = 'mechanic_application_status';
const _storage = FlutterSecureStorage();

class MechanicApplicationNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    try {
      final profile = await MechanicApiService.getProfile();
      final status = profile['application_status'] as String?;
      if (status != null) await _storage.write(key: _kStatusKey, value: status);
      return status;
    } catch (_) {
      return await _storage.read(key: _kStatusKey);
    }
  }

  Future<void> markSubmitted() async {
    await _storage.write(key: _kStatusKey, value: 'pending');
    state = const AsyncData('pending');
  }

  Future<void> clear() async {
    await _storage.delete(key: _kStatusKey);
    state = const AsyncData(null);
  }
}

final mechanicApplicationStatusProvider =
    AsyncNotifierProvider<MechanicApplicationNotifier, String?>(
  MechanicApplicationNotifier.new,
);
