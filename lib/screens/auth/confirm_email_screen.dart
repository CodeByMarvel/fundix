import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'auth_widgets.dart';

class ConfirmEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const ConfirmEmailScreen({super.key, required this.email});

  @override
  ConsumerState<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  // Countdown before the user can request another email.
  static const _cooldownSeconds = 60;
  int _secondsLeft = 0;
  Timer? _timer;
  String? _resendError;
  bool _resending = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _resendError = null;
    });

    final error = await ref
        .read(authProvider.notifier)
        .resendConfirmationEmail(widget.email);

    if (mounted) {
      setState(() {
        _resending = false;
        _resendError = error;
      });
      if (error == null) _startCooldown();
    }
  }

  void _backToLogin() {
    ref.read(authProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final canResend = _secondsLeft == 0 && !_resending;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 48),

                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Check your email',
                  style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a confirmation link to:',
                  style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.email,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tap the link in the email to verify your account, then come back and log in.',
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),

                if (_resendError != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBanner(message: _resendError!),
                ],

                const SizedBox(height: 32),

                // Resend button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: canResend ? _resend : null,
                    child: _resending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _secondsLeft > 0
                                ? 'Resend in ${_secondsLeft}s'
                                : 'Resend confirmation email',
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to login
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: _backToLogin,
                    child: const Text('Back to login'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
