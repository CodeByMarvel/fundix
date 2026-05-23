import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  UserRole _role = UserRole.customer;
  bool _loading = false;
  String? _apiError;
  bool _obscure = true;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Rebuild on every keystroke so strength bar and post-submit errors update live
    _nameCtrl.addListener(() => setState(() {}));
    _emailCtrl.addListener(() => setState(() {}));
    _passwordCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // 0 = empty, 1 = too short, 2 = ok length but no digit, 3 = strong
  int get _strength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    if (p.length < 8) return 1;
    if (!p.contains(RegExp(r'[0-9]'))) return 2;
    return 3;
  }

  String? get _nameError {
    if (!_submitted) return null;
    if (_nameCtrl.text.trim().length < 2) return 'Enter your full name';
    return null;
  }

  String? get _emailError {
    if (!_submitted) return null;
    final e = _emailCtrl.text.trim();
    if (e.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? get _passwordError {
    if (!_submitted) return null;
    if (_passwordCtrl.text.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  bool get _hasFieldErrors =>
      _nameError != null || _emailError != null || _passwordError != null;

  Future<void> _signup() async {
    setState(() {
      _submitted = true;
      _apiError = null;
    });

    if (_hasFieldErrors) return;

    setState(() => _loading = true);

    final error = await ref.read(authProvider.notifier).signUp(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _role,
          name: _nameCtrl.text.trim(),
        );

    if (mounted) {
      setState(() {
        _loading = false;
        _apiError = error;
      });
      // On success (error == null), AuthGate has already switched to the correct
      // screen below us. Pop back to root so it becomes visible.
      if (error == null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Text(
                  'FUNDI-X',
                  textAlign: TextAlign.center,
                  style: text.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create your account',
                  textAlign: TextAlign.center,
                  style:
                      text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 28),

                // ── Role selector ───────────────────────────────────────────
                Text(
                  'I am a',
                  style: text.labelMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        label: 'Customer',
                        icon: Icons.directions_car_outlined,
                        selected: _role == UserRole.customer,
                        onTap: () => setState(() => _role = UserRole.customer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        label: 'Mechanic',
                        icon: Icons.build_outlined,
                        selected: _role == UserRole.mechanic,
                        onTap: () => setState(() => _role = UserRole.mechanic),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Name ────────────────────────────────────────────────────
                TextField(
                  controller: _nameCtrl,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'e.g. Jane Muthoni',
                    prefixIcon: const Icon(Icons.person_outlined),
                    errorText: _nameError,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Email ───────────────────────────────────────────────────
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _emailError,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Password + strength bar ─────────────────────────────────
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signup(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _StrengthBar(strength: _strength),
                const SizedBox(height: 4),

                // ── API error ───────────────────────────────────────────────
                if (_apiError != null) ...[
                  const SizedBox(height: 8),
                  AuthErrorBanner(message: _apiError!),
                ],
                const SizedBox(height: 24),

                // ── Submit ──────────────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signup,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Login link ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Have an account?',
                        style:
                            TextStyle(color: colors.onSurfaceVariant)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Log in'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Password strength bar ─────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});
  final int strength; // 0–3

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox.shrink();

    final color = switch (strength) {
      1 => AppColors.error,
      2 => AppColors.warning,
      _ => AppColors.success,
    };
    final label = switch (strength) {
      1 => 'Too short',
      2 => 'Add a number to strengthen',
      _ => 'Strong',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 3,
                margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                decoration: BoxDecoration(
                  color: i < strength ? color : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}

// ── Role card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer
              : colors.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color:
                  selected ? colors.primary : colors.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? colors.primary : colors.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
