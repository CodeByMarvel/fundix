import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme_ext.dart';
import '../../providers/locale_provider.dart';
import '../dev/role_switcher.dart';
import 'customer_settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(t('profile', lang)),
        backgroundColor: context.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textGrey),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerSettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _ProfileHero(lang: lang),
          const SizedBox(height: 28),
          _AccountMenu(lang: lang),
          const SizedBox(height: 12),
          _SignOutButton(lang: lang),
          if (RoleSwitcherScreen.isAvailable) ...[
            const SizedBox(height: 12),
            _DevRoleSwitcherButton(),
          ],
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: context.primarySurface,
              child: const Icon(Icons.person_rounded, size: 48, color: AppColors.primary),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.surface,
                shape: BoxShape.circle,
                border: Border.all(color: context.divider, width: 1.5),
              ),
              child: Icon(Icons.edit_outlined, size: 14, color: context.textGrey),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Your Name',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          'customer@email.com',
          style: TextStyle(fontSize: 13, color: context.textGrey),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: context.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Customer',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.directions_car_rounded, t('my_vehicles', lang)),
      (Icons.payment_outlined, t('payment_methods', lang)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final (icon, label) = items[i];
          return Column(
            children: [
              ListTile(
                leading: Icon(icon, color: context.textGrey, size: 22),
                title: Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: context.inactive, size: 20),
                onTap: () {},
              ),
              if (i < items.length - 1)
                Divider(height: 1, indent: 56, color: context.divider),
            ],
          );
        }),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
        title: Text(
          t('sign_out', lang),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error),
        ),
        onTap: () => _showSignOutDialog(context, lang),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('sign_out', lang)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(t('sign_out', lang)),
          ),
        ],
      ),
    );
  }
}

class _DevRoleSwitcherButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSwitcherScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2D2D4E)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFF7C7CFF), size: 18),
            SizedBox(width: 8),
            Text(
              'DEV — Switch Role',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7C7CFF),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
