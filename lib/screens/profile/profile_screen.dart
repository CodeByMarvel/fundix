import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../dev/role_switcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(Icons.settings_outlined, color: AppColors.textGrey),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 24),
          const _ProfileMenuSection(),
          const SizedBox(height: 12),
          _DevRoleSwitcherButton(),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primarySurface,
            child: const Icon(Icons.person_rounded, size: 34, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Name',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'customer@email.com',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Customer',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
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

class _ProfileMenuSection extends StatelessWidget {
  const _ProfileMenuSection();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.directions_car_rounded, 'My Vehicles', false),
      (Icons.location_on_outlined, 'Saved Locations', false),
      (Icons.payment_outlined, 'Payment Methods', false),
      (Icons.notifications_outlined, 'Notifications', false),
      (Icons.help_outline_rounded, 'Help & Support', false),
      (Icons.logout_rounded, 'Sign Out', true),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final (icon, label, isDestructive) = items[i];
          final color = isDestructive ? AppColors.error : AppColors.textDark;
          return Column(
            children: [
              ListTile(
                leading: Icon(icon, color: isDestructive ? AppColors.error : AppColors.textGrey, size: 22),
                title: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                trailing: isDestructive
                    ? null
                    : const Icon(Icons.chevron_right_rounded, color: AppColors.inactive, size: 20),
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
