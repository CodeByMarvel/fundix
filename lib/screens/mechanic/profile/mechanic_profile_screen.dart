import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme_ext.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/mechanic_availability_provider.dart';
import '../../dev/role_switcher.dart';
import 'mechanic_settings_screen.dart';

// Persisted skills for this session
final _mechanicSkillsProvider = StateProvider<List<String>>(
  (_) => ['Battery', 'Tire', 'Engine', 'Oil Change'],
);

const _allSkills = [
  'Engine', 'Oil Change', 'Battery', 'Tire', 'Brake', 'Suspension',
  'Electrical', 'AC / Cooling', 'Transmission', 'Diagnostics',
  'Bodywork', 'Exhaust', 'Clutch', 'Fuel System', 'Steering',
];

class MechanicProfileScreen extends ConsumerWidget {
  const MechanicProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final isOnline = ref.watch(mechanicIsOnlineProvider);
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
          _MechanicProfileHero(lang: lang, isOnline: isOnline),
          const SizedBox(height: 28),
          _SkillsSection(lang: lang),
          const SizedBox(height: 12),
          _MechanicMenu(lang: lang),
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

class _MechanicProfileHero extends StatelessWidget {
  const _MechanicProfileHero({required this.lang, required this.isOnline});
  final String lang;
  final bool isOnline;

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
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success : AppColors.textGrey,
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
        // Online/offline status label
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: (isOnline ? AppColors.success : AppColors.textGrey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.textGrey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isOnline ? 'Online · Available for jobs' : 'Offline · Not receiving jobs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? AppColors.success : AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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

class _SkillsSection extends ConsumerWidget {
  const _SkillsSection({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(_mechanicSkillsProvider);

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
            trailing: GestureDetector(
              onTap: () => _showSkillsEditor(context, ref, skills),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: context.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: skills.isEmpty
                ? GestureDetector(
                    onTap: () => _showSkillsEditor(context, ref, skills),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Add your skills',
                              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((s) => _SkillChip(label: s)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _showSkillsEditor(BuildContext context, WidgetRef ref, List<String> currentSkills) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SkillsEditorSheet(
        currentSkills: currentSkills,
        onSave: (updated) => ref.read(_mechanicSkillsProvider.notifier).state = updated,
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

// ── Skills editor bottom sheet ─────────────────────────────────────────────────

class _SkillsEditorSheet extends StatefulWidget {
  const _SkillsEditorSheet({required this.currentSkills, required this.onSave});
  final List<String> currentSkills;
  final ValueChanged<List<String>> onSave;

  @override
  State<_SkillsEditorSheet> createState() => _SkillsEditorSheetState();
}

class _SkillsEditorSheetState extends State<_SkillsEditorSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.currentSkills);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Skills & Specialties',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text('Select all areas you are qualified in',
                        style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selected.length} selected',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSkills.map((skill) {
                  final sel = _selected.contains(skill);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (sel) {
                        _selected.remove(skill);
                      } else {
                        _selected.add(skill);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primarySurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel) ...[
                            const Icon(Icons.check_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            skill,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              color: sel ? AppColors.primary : AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected.isNotEmpty
                  ? () {
                      widget.onSave(_selected.toList());
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Save Skills'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mechanic menu ──────────────────────────────────────────────────────────────

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
        onTap: () => _showPayoutSheet(context),
      ),
    );
  }

  void _showPayoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PayoutSettingsSheet(),
    );
  }
}

// ── Payout settings sheet ──────────────────────────────────────────────────────

class _PayoutSettingsSheet extends StatefulWidget {
  const _PayoutSettingsSheet();

  @override
  State<_PayoutSettingsSheet> createState() => _PayoutSettingsSheetState();
}

class _PayoutSettingsSheetState extends State<_PayoutSettingsSheet> {
  final _mpesaCtrl = TextEditingController(text: '+254 7XX XXX XXX');
  String _frequency = 'Instant';

  @override
  void dispose() {
    _mpesaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Payout Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Earnings are sent directly to your M-Pesa',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 20),

          // Earnings summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Balance',
                        style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text('KES 0.00',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('0 completed jobs',
                          style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // M-Pesa number
          const Text('M-Pesa Payout Number',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _mpesaCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.success, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),

          // Payout frequency
          const Text('Payout Frequency',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Row(
            children: ['Instant', 'Daily', 'Weekly'].map((opt) {
              final sel = _frequency == opt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _frequency = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primarySurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AppColors.primary : AppColors.divider,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            opt,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                              color: sel ? AppColors.primary : AppColors.textGrey,
                            ),
                          ),
                          if (opt == 'Instant') ...[
                            const SizedBox(height: 2),
                            Text('Auto',
                                style: TextStyle(
                                    fontSize: 9, color: sel ? AppColors.primary : AppColors.textGrey)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payout settings saved')),
                );
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Save Payout Settings'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign out & dev buttons ────────────────────────────────────────────────────

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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
                fontSize: 13, fontWeight: FontWeight.w600,
                color: Color(0xFF7C7CFF), letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
