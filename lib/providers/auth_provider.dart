import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? sessionToken;

  const AuthState({required this.status, this.user, this.sessionToken});

  static const loading = AuthState(status: AuthStatus.loading);
  static const unauthenticated = AuthState(status: AuthStatus.unauthenticated);

  const AuthState.authenticated(this.user, String token)
      : status = AuthStatus.authenticated,
        sessionToken = token;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading) {
    _restore();
  }

  Future<void> _restore() async {
    final user = await AuthService.restoreSession();
    final token = await AuthService.getSessionToken();
    if (user != null && token != null) {
      state = AuthState.authenticated(user, token);
    } else {
      state = AuthState.unauthenticated;
    }
  }

  // Returns null on success, error message on failure.
  Future<String?> signIn(String email, String password) async {
    final result = await AuthService.signIn(email, password);
    if (result.success) {
      state = AuthState.authenticated(result.user!, result.sessionToken!);
      return null;
    }
    return result.error;
  }

  // Returns null on success, error message on failure.
  Future<String?> signUp(String email, String password, UserRole role) async {
    final result = await AuthService.signUp(email, password, role);
    if (result.success) {
      state = AuthState.authenticated(result.user!, result.sessionToken!);
      return null;
    }
    return result.error;
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    state = AuthState.unauthenticated;
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
