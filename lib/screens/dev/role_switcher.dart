import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../shell/main_shell.dart';
import '../mechanic/shell/mechanic_shell.dart';

// This screen must never appear in a production build.
// Always route through AuthGate in release mode.
class RoleSwitcherScreen extends StatelessWidget {
  static bool get isAvailable => kDebugMode;
  const RoleSwitcherScreen({super.key});

  void _switchTo(BuildContext context, Widget shell) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => shell),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _DevBadge(),
              const SizedBox(height: 32),
              const Text(
                'Preview as',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a role to enter the app.\nThis screen is dev-only.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              _RoleCard(
                role: 'Customer',
                description: 'Request a mechanic, track service, rate & review.',
                icon: Icons.directions_car_rounded,
                accentColor: AppColors.primary,
                tags: const ['Find Mechanic', 'Live Tracking', 'Reviews'],
                onTap: () => _switchTo(context, const MainShell()),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                role: 'Mechanic',
                description: 'Go online, accept jobs, track earnings.',
                icon: Icons.handyman_rounded,
                accentColor: AppColors.success,
                tags: const ['Accept Jobs', 'Earnings', 'Online/Offline'],
                onTap: () => _switchTo(context, const MechanicShell()),
              ),
              const Spacer(),
              Center(
                child: Text(
                  'FUNDIX · DEV BUILD',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7C7CFF).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF7C7CFF).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.code_rounded, color: Color(0xFF7C7CFF), size: 13),
          SizedBox(width: 5),
          Text(
            'DEV MODE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C7CFF),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.tags,
    required this.onTap,
  });

  final String role;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<String> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D2D4E)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: accentColor,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
