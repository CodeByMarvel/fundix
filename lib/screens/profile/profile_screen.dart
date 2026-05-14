import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../dev/role_switcher.dart';
import 'customer_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textGrey),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerSettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const _ProfileHero(),
          const SizedBox(height: 28),
          const _AccountMenu(),
          const SizedBox(height: 12),
          const _SignOutButton(),
          const SizedBox(height: 12),
          _DevRoleSwitcherButton(),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero();

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
              backgroundColor: AppColors.primarySurface,
              child: const Icon(Icons.person_rounded, size: 48, color: AppColors.primary),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 1.5),
              ),
              child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.textGrey),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Your Name',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        const Text(
          'customer@email.com',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
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
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.directions_car_rounded, 'My Vehicles'),
      (Icons.payment_outlined, 'Payment Methods'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final (icon, label) = items[i];
          return Column(
            children: [
              ListTile(
                leading: Icon(icon, color: AppColors.textGrey, size: 22),
                title: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.inactive, size: 20),
                onTap: () {},
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 56, color: AppColors.divider),
            ],
          );
        }),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error),
        ),
        onTap: () {},
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
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
