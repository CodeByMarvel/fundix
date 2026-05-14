import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme_ext.dart';
import '../../../providers/locale_provider.dart';
import '../../dev/role_switcher.dart';
import 'mechanic_settings_screen.dart';

class MechanicProfileScreen extends ConsumerWidget {
  const MechanicProfileScreen({super.key});

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
              MaterialPageRoute(builder: (_) => const MechanicSettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _MechanicProfileHero(lang: lang),
          const SizedBox(height: 28),
          _SkillsSection(lang: lang),
          const SizedBox(height: 12),
          _MechanicMenu(lang: lang),
          const SizedBox(height: 12),
          _SignOutButton(lang: lang),
          const SizedBox(height: 12),
          _DevRoleSwitcherButton(),
        ],
      ),
    );
  }
}

class _MechanicProfileHero extends StatelessWidget {
  const _MechanicProfileHero({required this.lang});
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
            // Online indicator
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: context.surface, width: 2.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Mechanic Name',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          'mechanic@email.com',
          style: TextStyle(fontSize: 13, color: context.textGrey),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
            const SizedBox(width: 3),
            Text(
              '— · 0 reviews',
              style: TextStyle(fontSize: 12, color: context.textGrey),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: context.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Mechanic',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _SkillsSection extends StatelessWidget {
  const _SkillsSection({required this.lang});
  final String lang;

  static const _skills = ['Battery', 'Tire', 'Engine', 'Oil Change'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.build_outlined, color: context.textGrey, size: 22),
            title: Text(
              t('skills_specialties', lang),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark),
            ),
            trailing: Text(
              'Edit',
              style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skills.map((s) => _SkillChip(label: s, context: context)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label, required this.context});
  final String label;
  final BuildContext context;

  @override
  Widget build(_) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary),
      ),
    );
  }
}

class _MechanicMenu extends StatelessWidget {
  const _MechanicMenu({required this.lang});
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
        leading: Icon(Icons.account_balance_outlined, color: context.textGrey, size: 22),
        title: Text(
          t('payout_settings', lang),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: context.inactive, size: 20),
        onTap: () {},
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
