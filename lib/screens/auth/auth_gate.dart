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
      AuthStatus.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.emailConfirmationPending => ConfirmEmailScreen(
          email: auth.pendingEmail ?? '',
        ),
      AuthStatus.authenticated => auth.user!.role == UserRole.customer
          ? const MainShell()
          : const MechanicShell(),
    };
  }
}
