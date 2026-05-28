import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../shell/main_shell.dart';
import '../mechanic/shell/mechanic_shell.dart';
import 'login_screen.dart';
import 'confirm_email_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return switch (auth.status) {
      AuthStatus.loading ||
      AuthStatus.profileLoading =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),

      AuthStatus.unauthenticated => const LoginScreen(),

      AuthStatus.emailConfirmationPending => ConfirmEmailScreen(
          email: auth.pendingEmail ?? '',
        ),

      // Network/server error fetching profile — user is still logged in.
      // Show a retry screen; do NOT sign them out.
      AuthStatus.profileError => _ProfileErrorScreen(
          message: auth.profileErrorMessage ?? 'Could not load your profile.',
          onRetry: () => ref.read(authProvider.notifier).retryProfileLoad(),
        ),

      AuthStatus.authenticated => auth.user!.role == UserRole.customer
          ? const MainShell()
          : const MechanicShell(),
    };
  }
}

class _ProfileErrorScreen extends StatelessWidget {
  const _ProfileErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, size: 56, color: colors.error),
                const SizedBox(height: 20),
                Text(
                  'Connection problem',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: text.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
