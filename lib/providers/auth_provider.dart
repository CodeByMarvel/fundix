import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/customer_api_service.dart' show CustomerApiService, UnauthorizedException;

enum AuthStatus {
  loading,
  unauthenticated,
  emailConfirmationPending,
  profileLoading, // session confirmed, verifying profile exists
  profileError,   // session ok but profile fetch failed (network/server)
  authenticated,  // session + profile confirmed — show home shell
}

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? sessionToken;
  final String? pendingEmail;
  final String? profileErrorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.sessionToken,
    this.pendingEmail,
    this.profileErrorMessage,
  });

  static const loading = AuthState(status: AuthStatus.loading);
  static const unauthenticated = AuthState(status: AuthStatus.unauthenticated);

  const AuthState.authenticated(this.user, String token)
      : status = AuthStatus.authenticated,
        sessionToken = token,
        pendingEmail = null,
        profileErrorMessage = null;

  static AuthState awaitingConfirmation(String email) =>
      AuthState(status: AuthStatus.emailConfirmationPending, pendingEmail: email);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading) {
    _init();
  }

  StreamSubscription<sb.AuthState>? _sub;

  void _init() {
    final current = AuthService.currentUser();
    final token = AuthService.currentAccessToken();
    if (current != null && token != null) {
      _onAuthenticated(current, token);
    } else {
      state = AuthState.unauthenticated;
    }

    _sub = AuthService.authStateChanges.listen((event) {
      final session = event.session;
      if (session == null) {
        if (state.status != AuthStatus.emailConfirmationPending) {
          state = AuthState.unauthenticated;
        }
        return;
      }
      final user = AuthService.currentUser();
      if (user != null) {
        _onAuthenticated(user, session.accessToken);
      }
    });
  }

  // Called whenever we confirm a valid session exists.
  // Customers: verify profile is reachable before showing the home shell.
  // Mechanics: go straight through — MechanicShell owns its own onboarding.
  Future<void> _onAuthenticated(AppUser user, String token) async {
    if (user.role == UserRole.mechanic) {
      state = AuthState.authenticated(user, token);
      return;
    }

    state = AuthState(
      status: AuthStatus.profileLoading,
      user: user,
      sessionToken: token,
    );

    try {
      await CustomerApiService.getProfile();
      state = AuthState.authenticated(user, token);
    } on UnauthorizedException {
      // Token is invalid or user was deleted — clear local session and go to login
      await AuthService.signOut();
      state = AuthState.unauthenticated;
    } on TimeoutException {
      state = AuthState(
        status: AuthStatus.profileError,
        user: user,
        sessionToken: token,
        profileErrorMessage:
            'Server is taking too long to respond. Tap "Try again" in a moment.',
      );
    } on SocketException {
      state = AuthState(
        status: AuthStatus.profileError,
        user: user,
        sessionToken: token,
        profileErrorMessage:
            'No internet connection. Check your network and try again.',
      );
    } catch (e) {
      debugPrint('[Auth] profile fetch failed: $e');
      state = AuthState(
        status: AuthStatus.profileError,
        user: user,
        sessionToken: token,
        profileErrorMessage: 'Could not load your profile. ($e)',
      );
    }
  }

  // Retry after a profileError without requiring the user to sign out.
  Future<void> retryProfileLoad() async {
    final user = state.user;
    final token = state.sessionToken;
    if (user == null || token == null) return;
    await _onAuthenticated(user, token);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<String?> signIn(String email, String password) async {
    final result = await AuthService.signIn(email, password);
    if (result.success && result.user != null) {
      final token = AuthService.currentAccessToken() ?? '';
      await _onAuthenticated(result.user!, token);
    }
    return result.error;
  }

  Future<String?> signUp(String email, String password, UserRole role,
      {required String name}) async {
    final result = await AuthService.signUp(email, password, role, name: name);

    if (result.isPendingConfirmation) {
      state = AuthState.awaitingConfirmation(result.pendingConfirmationEmail!);
      return null;
    }

    if (result.success && result.user != null) {
      final token = AuthService.currentAccessToken() ?? '';
      await _onAuthenticated(result.user!, token);
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
