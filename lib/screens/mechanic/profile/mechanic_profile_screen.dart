import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../dev/role_switcher.dart';
import 'mechanic_settings_screen.dart';

class MechanicProfileScreen extends StatelessWidget {
  const MechanicProfileScreen({super.key});

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
              MaterialPageRoute(builder: (_) => const MechanicSettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: const [
          _MechanicProfileHeader(),
          SizedBox(height: 16),
          _SkillsCard(),
          SizedBox(height: 24),
          _MechanicMenuSection(),
          SizedBox(height: 12),
          _DevRoleSwitcher(),
        ],
      ),
    );
  }
}

class _MechanicProfileHeader extends StatelessWidget {
  const _MechanicProfileHeader();

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
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primarySurface,
                child: const Icon(Icons.person_rounded, size: 34, color: AppColors.primary),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mechanic Name',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'mechanic@email.com',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                    SizedBox(width: 3),
                    Text(
                      '— · 0 reviews',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
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
              'Mechanic',
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

class _SkillsCard extends StatelessWidget {
  const _SkillsCard();

  static const _skills = ['Battery', 'Tire', 'Engine', 'Oil Change'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Skills & Specialties',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                'Edit',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((s) => _SkillChip(label: s)).toList(),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _MechanicMenuSection extends StatelessWidget {
  const _MechanicMenuSection();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.account_balance_outlined, 'Payout Settings', false),
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
                leading: Icon(
                  icon,
                  color: isDestructive ? AppColors.error : AppColors.textGrey,
                  size: 22,
                ),
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
                    : const Icon(Icons.chevron_right_rounded,
                        color: AppColors.inactive, size: 20),
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

class _DevRoleSwitcher extends StatelessWidget {
  const _DevRoleSwitcher();

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
