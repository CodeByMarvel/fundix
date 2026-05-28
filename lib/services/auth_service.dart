import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';

class AuthResult {
  final bool success;
  final AppUser? user;
  final String? error;

  // Non-null when sign-up succeeds but email confirmation is still pending.
  // The caller should show a "check your inbox" screen rather than treating
  // this as an error.
  final String? pendingConfirmationEmail;

  bool get isPendingConfirmation => pendingConfirmationEmail != null;

  const AuthResult._({
    required this.success,
    this.user,
    this.error,
    this.pendingConfirmationEmail,
  });

  factory AuthResult.ok(AppUser user) =>
      AuthResult._(success: true, user: user);

  factory AuthResult.pendingConfirmation(String email) =>
      AuthResult._(success: false, pendingConfirmationEmail: email);

  factory AuthResult.fail(String error) =>
      AuthResult._(success: false, error: error);
}

class AuthService {
  static GoTrueClient get _auth => Supabase.instance.client.auth;

  // ---------- public API ----------

  static Future<AuthResult> signIn(String email, String password) async {
    final validationError = _validateCredentials(email, password);
    if (validationError != null) return AuthResult.fail(validationError);

    try {
      final res = await _auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = res.user;
      if (user == null) return AuthResult.fail('Sign in failed. Please try again.');
      return AuthResult.ok(_toAppUser(user));
    } on AuthException catch (e) {
      return AuthResult.fail(_friendlyError(e));
    } catch (_) {
      return AuthResult.fail('Connection error. Please try again.');
    }
  }

  static Future<AuthResult> signUp(
      String email, String password, UserRole role,
      {required String name}) async {
    final nameError = _validateName(name);
    if (nameError != null) return AuthResult.fail(nameError);
    final validationError = _validateCredentials(email, password);
    if (validationError != null) return AuthResult.fail(validationError);

    try {
      final res = await _auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        emailRedirectTo: 'fundix://login-callback/',
        data: {
          'role': role.name,
          'name': name.trim(),
        },
      );

      // Session is null when Supabase requires email confirmation.
      // This is the recommended secure default — do not disable it.
      if (res.session == null) {
        return AuthResult.pendingConfirmation(email.trim().toLowerCase());
      }

      final user = res.user;
      if (user == null) return AuthResult.fail('Sign up failed. Please try again.');
      return AuthResult.ok(_toAppUser(user));
    } on AuthException catch (e) {
      return AuthResult.fail(_friendlyError(e));
    } catch (_) {
      return AuthResult.fail('Connection error. Please try again.');
    }
  }

  /// Resends the confirmation email. Returns an error string or null on success.
  static Future<String?> resendConfirmationEmail(String email) async {
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'fundix://login-callback/',
      );
      return null;
    } on AuthException catch (e) {
      return _friendlyError(e);
    } catch (_) {
      return 'Connection error. Please try again.';
    }
  }

  /// Sends a password-reset email. Returns an error string or null on success.
  /// Always returns null for unknown emails to prevent account enumeration.
  static Future<String?> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) return 'Email is required';
    try {
      await _auth.resetPasswordForEmail(
        trimmed,
        redirectTo: 'fundix://reset-password/',
      );
      return null;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      // Never reveal whether the email exists in the system
      if (msg.contains('not found') || msg.contains('no user')) return null;
      if (msg.contains('too many') || msg.contains('rate limit')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      return 'Something went wrong. Please try again.';
    } catch (_) {
      return 'Connection error. Please try again.';
    }
  }

  static Future<void> signOut() => _auth.signOut();

  /// Returns the currently signed-in user, or null if there is no active session.
  static AppUser? currentUser() {
    final user = _auth.currentUser;
    return user == null ? null : _toAppUser(user);
  }

  /// Stream of Supabase auth events (sign-in, sign-out, token refresh, etc.).
  /// The SDK automatically refreshes the access token — no manual refresh needed.
  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  static String? currentAccessToken() => _auth.currentSession?.accessToken;

  // ---------- private helpers ----------

  static AppUser _toAppUser(User user) {
    final meta = user.userMetadata ?? {};
    final roleStr = meta['role'] as String? ?? 'customer';
    final role =
        roleStr == 'mechanic' ? UserRole.mechanic : UserRole.customer;
    final name = meta['name'] as String? ??
        user.email?.split('@').first ??
        'User';
    return AppUser(
      id: user.id,
      name: name,
      email: user.email ?? '',
      role: role,
    );
  }

  // Generic messages that don't reveal whether an email exists.
  // Leaking "email already registered" lets attackers enumerate valid accounts.
  static String _friendlyError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        msg.contains('email not confirmed')) {
      return 'Incorrect email or password';
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      // Do NOT say "already registered" — that confirms the email exists.
      return 'Check your email and password and try again';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('password')) return 'Password is too weak';
    return 'Something went wrong. Please try again.';
  }

  static String? _validateName(String name) {
    if (name.trim().length < 2) return 'Enter your full name';
    return null;
  }

  static String? _validateCredentials(String email, String password) {
    if (email.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email.trim())) {
      return 'Enter a valid email address';
    }
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return null;
  }
}
