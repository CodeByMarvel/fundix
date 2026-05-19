import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  loading,
  unauthenticated,
  authenticated,
  emailConfirmationPending,
}

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? sessionToken;
  // Populated when status == emailConfirmationPending.
  final String? pendingEmail;

  const AuthState({
    required this.status,
    this.user,
    this.sessionToken,
    this.pendingEmail,
  });

  static const loading = AuthState(status: AuthStatus.loading);
  static const unauthenticated = AuthState(status: AuthStatus.unauthenticated);

  const AuthState.authenticated(this.user, String token)
      : status = AuthStatus.authenticated,
        sessionToken = token,
        pendingEmail = null;

  static AuthState awaitingConfirmation(String email) =>
      AuthState(status: AuthStatus.emailConfirmationPending, pendingEmail: email);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading) {
    _init();
  }

  StreamSubscription<sb.AuthState>? _sub;

  void _init() {
    // Seed state from any session persisted by the Supabase SDK.
    final current = AuthService.currentUser();
    final token = AuthService.currentAccessToken();
    if (current != null && token != null) {
      state = AuthState.authenticated(current, token);
    } else {
      state = AuthState.unauthenticated;
    }

    // Stay in sync with Supabase auth events (sign-in, sign-out, token refresh).
    _sub = AuthService.authStateChanges.listen((event) {
      final session = event.session;
      if (session == null) {
        // Only move to unauthenticated if we're not waiting for email confirmation.
        if (state.status != AuthStatus.emailConfirmationPending) {
          state = AuthState.unauthenticated;
        }
        return;
      }
      final user = AuthService.currentUser();
      if (user != null) {
        state = AuthState.authenticated(user, session.accessToken);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Returns null on success, error string on failure.
  Future<String?> signIn(String email, String password) async {
    final result = await AuthService.signIn(email, password);
    if (result.success && result.user != null) {
      final token = AuthService.currentAccessToken() ?? '';
      state = AuthState.authenticated(result.user!, token);
    }
    return result.error;
  }

  // Returns null on success or pending confirmation. Returns error string on failure.
  Future<String?> signUp(String email, String password, UserRole role,
      {required String name}) async {
    final result =
        await AuthService.signUp(email, password, role, name: name);

    if (result.isPendingConfirmation) {
      state = AuthState.awaitingConfirmation(result.pendingConfirmationEmail!);
      return null;
    }

    if (result.success && result.user != null) {
      final token = AuthService.currentAccessToken() ?? '';
      state = AuthState.authenticated(result.user!, token);
    }
    return result.error;
  }

  Future<String?> resendConfirmationEmail(String email) =>
      AuthService.resendConfirmationEmail(email);

  Future<void> signOut() async {
    await AuthService.signOut();
    state = AuthState.unauthenticated;
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
