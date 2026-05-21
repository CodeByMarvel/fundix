import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/mechanic_type.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme_ext.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/mechanic_availability_provider.dart'; // isOnline drives the status chip
import '../../dev/role_switcher.dart';
import 'mechanic_settings_screen.dart';

// ── State ──────────────────────────────────────────────────────────────────────

// Simulates the persistent account type — in production this comes from Supabase.
// Defaults to mobile because most new signups are mobile mechanics.
// Can only move garage; going back is not allowed.
final mechanicAccountTypeProvider = StateProvider<MechanicType>((_) => MechanicType.mobile);

final _operatingStatusProvider = StateProvider<String>((_) => 'Open now');
final _mechanicSkillsProvider = StateProvider<List<String>>(
  (_) => ['Engine Diagnostics', 'Brake Service', 'Suspension', 'Japanese Cars'],
);

// ── Constants ──────────────────────────────────────────────────────────────────

const _allSkills = [
  'Engine Diagnostics', 'Oil Change', 'Battery', 'Tire',
  'Brake Service', 'Suspension', 'Electrical Systems', 'AC / Cooling',
  'Transmission', 'Bodywork & Paint', 'Exhaust', 'Clutch',
  'Fuel System', 'Steering', 'German Cars', 'Japanese Cars',
  'Subaru Specialist', 'Accident Repair', 'Wheel Alignment', 'Engine Rebuild',
];

const _garageBestFor = [
  'Best for accident repair',
  'Best for diagnostics',
  'Best for Japanese cars',
];
const _mobileBestFor = [
  'Best for emergency battery',
  'Best for quick inspections',
];

const _garageServices = [
  ('Diagnostics', 'KES 1,500 – 3,000'),
  ('Brake Service', 'KES 2,500 – 6,000'),
  ('Suspension Check', 'KES 3,000 – 8,000'),
  ('Accident Repair', 'Inspection required'),
  ('Oil Change', 'KES 1,200 – 2,500'),
  ('Wheel Alignment', 'KES 1,500 – 2,500'),
];

const _mobileServices = [
  ('Battery Jumpstart', 'KES 500 – 1,000'),
  ('Tire Replacement', 'KES 800 – 1,500'),
  ('Basic Diagnostics', 'KES 1,000 – 2,000'),
  ('Overheating Inspection', 'KES 800 – 1,500'),
  ('Minor Electrical', 'KES 600 – 1,200'),
];

const _equipment = ['Diagnostic Scanner', 'Hydraulic Lift', 'Spray Booth', 'Wheel Alignment'];
const _mobileZones = ['Westlands', 'Kilimani', 'Parklands', 'Ngong Road'];
const _operatingStatuses = ['Open now', 'Busy', 'Appointment only'];

final _mockReviews = [
  (
    name: 'John M.',
    rating: 5,
    date: '2 weeks ago',
    text: 'Transparent pricing and updated me daily during accident repair. Car came back looking brand new.',
  ),
  (
    name: 'Sarah K.',
    rating: 5,
    date: '1 month ago',
    text: 'Very professional, diagnosed the issue quickly. Done within the same day.',
  ),
  (
    name: 'David O.',
    rating: 4,
    date: '1 month ago',
    text: 'Good suspension work. Kept me informed throughout. Will come back.',
  ),
];

// ── Main Screen ────────────────────────────────────────────────────────────────

class MechanicProfileScreen extends ConsumerWidget {
  const MechanicProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final accountType = ref.watch(mechanicAccountTypeProvider);

    return Scaffold(
      backgroundColor: context.bg,
      body: CustomScrollView(
        slivers: [
          _ProfileAppBar(lang: lang),
          SliverToBoxAdapter(child: _TrustHeader(accountType: accountType)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SpecializationSection(accountType: accountType),
                const SizedBox(height: 16),
                // Garage profile shows full garage layer; mobile shows their limited info
                if (accountType == MechanicType.garage)
                  _GarageTrustLayer()
                else
                  _MobileInfoSection(),
                const SizedBox(height: 16),
                _ServicesSection(accountType: accountType),
                const SizedBox(height: 16),
                _WorkflowConfidenceSection(),
                const SizedBox(height: 16),
                _CustomerReviewsSection(),
                const SizedBox(height: 16),
                // Mobile mechanics see an upgrade path; garage mechanics cannot go back
                if (accountType == MechanicType.mobile) ...[
                  _UpgradeToGarageSection(),
                  const SizedBox(height: 16),
                ],
                _SectionDivider(label: 'Account'),
                const SizedBox(height: 12),
                _MechanicMenu(lang: lang),
                const SizedBox(height: 12),
                _SignOutButton(lang: lang),
                if (RoleSwitcherScreen.isAvailable) ...[
                  const SizedBox(height: 12),
                  _DevRoleSwitcherButton(),
                ],
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── App Bar ────────────────────────────────────────────────────────────────────

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: context.surface,
      title: Text(
        t('profile', lang),
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.textDark),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined, color: context.textGrey),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MechanicSettingsScreen()),
          ),
        ),
      ],
    );
  }
}

// ── Trust Header ───────────────────────────────────────────────────────────────

class _TrustHeader extends ConsumerWidget {
  const _TrustHeader({required this.accountType});
  final MechanicType accountType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(mechanicIsOnlineProvider);
    final operatingStatus = ref.watch(_operatingStatusProvider);
    final isGarage = accountType == MechanicType.garage;

    return Container(
      color: context.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garage = square rounded tile; Mobile = circle avatar
              Stack(
                children: [
                  isGarage
                      ? Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: context.primarySurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.store_rounded, size: 40, color: AppColors.primary),
                        )
                      : CircleAvatar(
                          radius: 40,
                          backgroundColor: context.primarySurface,
                          child: const Icon(Icons.person_rounded, size: 40, color: AppColors.primary),
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isGarage ? 'Kings Auto Garage' : 'Your Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: context.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_outlined, size: 16, color: context.textGrey),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _VerificationBadge(accountType: accountType),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 13, color: context.textGrey),
                        const SizedBox(width: 3),
                        Text(
                          isGarage ? 'Westlands, Nairobi' : 'Serves: Westlands, Kilimani',
                          style: TextStyle(fontSize: 12, color: context.textGrey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                i < 4 ? Icons.star_rounded : Icons.star_half_rounded,
                size: 16,
                color: AppColors.warning,
              )),
              const SizedBox(width: 6),
              Text(
                '4.8',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textDark),
              ),
              const SizedBox(width: 4),
              Text('(47 reviews)', style: TextStyle(fontSize: 12, color: context.textGrey)),
              const SizedBox(width: 8),
              Container(width: 1, height: 12, color: context.divider),
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
              const SizedBox(width: 3),
              Text('124 jobs', style: TextStyle(fontSize: 12, color: context.textGrey)),
            ],
          ),
          const SizedBox(height: 12),
          // Status chip: offline overrides the operating status choice
          GestureDetector(
            onTap: isOnline ? () => _showStatusPicker(context, ref) : null,
            child: _OperatingStatusChip(
              status: isOnline ? operatingStatus : 'Offline',
              isOnline: isOnline,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OperatingStatusSheet(
        current: ref.read(_operatingStatusProvider),
        onSelect: (s) => ref.read(_operatingStatusProvider.notifier).state = s,
      ),
    );
  }
}

// ── Verification Badge ─────────────────────────────────────────────────────────

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.accountType});
  final MechanicType accountType;

  @override
  Widget build(BuildContext context) {
    final isGarage = accountType == MechanicType.garage;
    const green = Color(0xFF1A6B3C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isGarage ? green.withValues(alpha: 0.1) : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isGarage ? green.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGarage ? Icons.verified_rounded : Icons.verified_user_rounded,
            size: 12,
            color: isGarage ? green : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            isGarage ? 'Fundix Approved Garage' : 'Verified Mobile Technician',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isGarage ? green : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Operating Status Chip ──────────────────────────────────────────────────────

class _OperatingStatusChip extends StatelessWidget {
  const _OperatingStatusChip({required this.status, this.isOnline = true});
  final String status;
  final bool isOnline;

  Color _color() {
    if (!isOnline) return AppColors.textGrey;
    switch (status) {
      case 'Open now': return AppColors.success;
      case 'Busy': return AppColors.warning;
      default: return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          // Arrow hidden when offline — chip is not tappable in that state
          if (isOnline) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
          ],
        ],
      ),
    );
  }
}

// ── Specialization Section ─────────────────────────────────────────────────────

class _SpecializationSection extends ConsumerWidget {
  const _SpecializationSection({required this.accountType});
  final MechanicType accountType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(_mechanicSkillsProvider);
    final bestFor = accountType == MechanicType.garage ? _garageBestFor : _mobileBestFor;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.workspace_premium_rounded,
            label: 'Specialization',
            actionLabel: 'Edit',
            onAction: () => _showSkillsEditor(context, ref, skills),
          ),
          const SizedBox(height: 4),
          Text('What you are great at', style: TextStyle(fontSize: 11, color: context.textGrey)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...skills.map((s) => _SkillChip(label: s)),
              GestureDetector(
                onTap: () => _showSkillsEditor(context, ref, skills),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 13, color: AppColors.primary),
                      SizedBox(width: 3),
                      Text('Add', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 13, color: context.textGrey),
              const SizedBox(width: 5),
              Text('Best For', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bestFor.map((tag) => _BestForChip(label: tag)).toList(),
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
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
    );
  }
}

class _BestForChip extends StatelessWidget {
  const _BestForChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1A6B3C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 11, color: green),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: green)),
        ],
      ),
    );
  }
}

// ── Garage Trust Layer ─────────────────────────────────────────────────────────

class _GarageTrustLayer extends StatelessWidget {
  const _GarageTrustLayer();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.store_outlined, label: 'Garage Profile', actionLabel: 'Edit', onAction: () {}),
          const SizedBox(height: 16),
          Text('Garage Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textDark)),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _GaragePhotoSlot(label: 'Front'),
                const SizedBox(width: 10),
                _GaragePhotoSlot(label: 'Work Bay'),
                const SizedBox(width: 10),
                _GaragePhotoSlot(label: 'Equipment'),
                const SizedBox(width: 10),
                _GaragePhotoAdd(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _GarageStat(icon: Icons.history_rounded, value: '12 years', label: 'Experience'),
              _StatDivider(),
              _GarageStat(icon: Icons.people_rounded, value: '5 techs', label: 'Team size'),
              _StatDivider(),
              _GarageStat(icon: Icons.location_on_rounded, value: 'Westlands', label: 'Location'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.build_circle_outlined, size: 13, color: context.textGrey),
              const SizedBox(width: 5),
              Text('Available Equipment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipment.map((e) => _EquipmentChip(label: e)).toList(),
          ),
        ],
      ),
    );
  }
}

class _GaragePhotoSlot extends StatelessWidget {
  const _GaragePhotoSlot({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.divider)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 24, color: context.textGrey),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: context.textGrey)),
        ],
      ),
    );
  }
}

class _GaragePhotoAdd extends StatelessWidget {
  const _GaragePhotoAdd();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, size: 24, color: AppColors.primary),
          SizedBox(height: 4),
          Text('Add photo', style: TextStyle(fontSize: 10, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _GarageStat extends StatelessWidget {
  const _GarageStat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textDark)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: context.textGrey)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(width: 1, height: 40, color: context.divider);
}

class _EquipmentChip extends StatelessWidget {
  const _EquipmentChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.divider)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 11, color: AppColors.success),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: context.textDark)),
        ],
      ),
    );
  }
}

// ── Mobile Info Section ────────────────────────────────────────────────────────

class _MobileInfoSection extends StatelessWidget {
  const _MobileInfoSection();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1A6B3C);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.directions_car_rounded, label: 'Mobile Profile', actionLabel: 'Edit', onAction: () {}),
          const SizedBox(height: 16),
          Text('Operational Zones', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mobileZones.map((z) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.divider)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 11, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(z, style: TextStyle(fontSize: 11, color: context.textDark)),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MobileInfoTile(icon: Icons.access_time_rounded, label: 'Available', value: '8AM – 6PM'),
              const SizedBox(width: 12),
              _MobileInfoTile(icon: Icons.two_wheeler_rounded, label: 'Transport', value: 'Motorcycle'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: green.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: green),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Only accepts jobs in verified safe zones.',
                      style: TextStyle(fontSize: 12, color: green, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileInfoTile extends StatelessWidget {
  const _MobileInfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.divider)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: context.textGrey)),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Services Section ───────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.accountType});
  final MechanicType accountType;

  @override
  Widget build(BuildContext context) {
    final services = accountType == MechanicType.garage ? _garageServices : _mobileServices;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.handyman_rounded, label: 'Services Offered', actionLabel: 'Edit', onAction: () {}),
          const SizedBox(height: 4),
          Text('Transparent pricing reduces customer hesitation', style: TextStyle(fontSize: 11, color: context.textGrey)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: context.divider), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                for (int i = 0; i < services.length; i++)
                  _ServiceRow(name: services[i].$1, range: services[i].$2, showDivider: i < services.length - 1),
              ],
            ),
          ),
          if (accountType == MechanicType.mobile) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: AppColors.warning),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Mobile services are limited to roadside-safe jobs only.',
                        style: TextStyle(fontSize: 11, color: AppColors.warning)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.name, required this.range, this.showDivider = true});
  final String name;
  final String range;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: context.textDark, fontWeight: FontWeight.w500))),
              Text(range, style: TextStyle(fontSize: 12, color: context.textGrey)),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: context.divider),
      ],
    );
  }
}

// ── Workflow Confidence Section ────────────────────────────────────────────────

class _WorkflowConfidenceSection extends StatelessWidget {
  const _WorkflowConfidenceSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.track_changes_rounded, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Repair Progress Updates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textDark)),
                    const SizedBox(height: 1),
                    Text('Customers stay informed at every stage', style: TextStyle(fontSize: 11, color: context.textGrey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _ProgressStep(label: 'Diagnosis\ncomplete', isDone: true),
              _ProgressConnector(isDone: true),
              _ProgressStep(label: 'Parts\nordered', isDone: false),
              _ProgressConnector(isDone: false),
              _ProgressStep(label: 'Repair\nongoing', isDone: false),
              _ProgressConnector(isDone: false),
              _ProgressStep(label: 'Ready for\npickup', isDone: false),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Customers see live updates like this — they're never left in the dark.",
            style: TextStyle(fontSize: 11, color: context.textGrey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.label, required this.isDone});
  final String label;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone ? AppColors.success : context.bg,
            shape: BoxShape.circle,
            border: Border.all(color: isDone ? AppColors.success : context.divider, width: 2),
          ),
          child: isDone ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: isDone ? AppColors.success : context.textGrey,
            fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ProgressConnector extends StatelessWidget {
  const _ProgressConnector({required this.isDone});
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(height: 2, margin: const EdgeInsets.only(bottom: 22), color: isDone ? AppColors.success : context.divider),
    );
  }
}

// ── Customer Reviews Section ───────────────────────────────────────────────────

class _CustomerReviewsSection extends StatelessWidget {
  const _CustomerReviewsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: Icons.star_rounded, label: 'Customer Reviews'),
          const SizedBox(height: 4),
          Text('Real feedback from verified customers', style: TextStyle(fontSize: 11, color: context.textGrey)),
          const SizedBox(height: 14),
          for (final r in _mockReviews)
            _ReviewCard(name: r.name, rating: r.rating, date: r.date, text: r.text),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.name, required this.rating, required this.date, required this.text});
  final String name;
  final int rating;
  final String date;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(name[0], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textDark)),
                      Row(
                        children: [
                          ...List.generate(rating, (_) => const Icon(Icons.star_rounded, size: 11, color: AppColors.warning)),
                          const SizedBox(width: 4),
                          Text(date, style: TextStyle(fontSize: 10, color: context.textGrey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('"$text"', style: TextStyle(fontSize: 12, color: context.textGrey, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

// ── Upgrade to Garage Section (mobile mechanics only) ──────────────────────────

class _UpgradeToGarageSection extends ConsumerWidget {
  const _UpgradeToGarageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.08), const Color(0xFF1A6B3C).withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.store_rounded, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upgrade to Garage Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.textDark)),
                    const SizedBox(height: 2),
                    Text('One-time upgrade · cannot be reversed', style: TextStyle(fontSize: 11, color: context.textGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Benefits list
          _UpgradeBenefit(text: 'Fundix Approved Garage badge'),
          _UpgradeBenefit(text: 'Garage photos, team & equipment display'),
          _UpgradeBenefit(text: 'Full service pricing table'),
          _UpgradeBenefit(text: 'Higher job match priority on the platform'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_upward_rounded, size: 16),
              label: const Text('Apply for Garage Verification'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmUpgrade(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmUpgrade(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upgrade to Garage?'),
        content: const Text(
          'This changes your profile to a garage-based mechanic. '
          'You will gain the Fundix Approved badge and full garage profile. '
          'This upgrade cannot be reversed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(mechanicAccountTypeProvider.notifier).state = MechanicType.garage;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upgrade submitted — review takes 24–48 hours.')),
              );
            },
            child: const Text('Confirm Upgrade'),
          ),
        ],
      ),
    );
  }
}

class _UpgradeBenefit extends StatelessWidget {
  const _UpgradeBenefit({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: context.textDark)),
        ],
      ),
    );
  }
}

// ── Shared Components ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.divider)),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, this.actionLabel, this.onAction});
  final IconData icon;
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textDark))),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20)),
              child: Text(actionLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label, style: TextStyle(fontSize: 11, color: context.textGrey, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: context.divider)),
      ],
    );
  }
}

// ── Operating Status Sheet ─────────────────────────────────────────────────────

class _OperatingStatusSheet extends StatelessWidget {
  const _OperatingStatusSheet({required this.current, required this.onSelect});
  final String current;
  final ValueChanged<String> onSelect;

  static const _descriptions = {
    'Open now': 'Accepting all new job requests',
    'Busy': 'Working on jobs, limited availability',
    'Appointment only': 'New jobs by booking only',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: context.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Operating Status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.textDark)),
          const SizedBox(height: 4),
          Text('Customers see this on your profile', style: TextStyle(fontSize: 12, color: context.textGrey)),
          const SizedBox(height: 16),
          for (final s in _operatingStatuses) ...[
            GestureDetector(
              onTap: () { onSelect(s); Navigator.pop(context); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: s == current ? AppColors.primarySurface : context.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: s == current ? AppColors.primary : context.divider, width: s == current ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: s == 'Open now' ? AppColors.success : s == 'Busy' ? AppColors.warning : AppColors.textGrey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s, style: TextStyle(fontSize: 14, fontWeight: s == current ? FontWeight.w700 : FontWeight.w500, color: context.textDark)),
                          Text(_descriptions[s]!, style: TextStyle(fontSize: 11, color: context.textGrey)),
                        ],
                      ),
                    ),
                    if (s == current) const Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Skills Editor Sheet ────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(color: context.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: context.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Skills & Specialties', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: context.textDark)),
                    const SizedBox(height: 2),
                    Text('Select all areas you are qualified in', style: TextStyle(fontSize: 12, color: context.textGrey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                child: Text('${_selected.length} selected', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
                      if (sel) { _selected.remove(skill); }
                      else { _selected.add(skill); }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primarySurface : context.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.primary : context.divider, width: sel ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel) ...[const Icon(Icons.check_rounded, size: 12, color: AppColors.primary), const SizedBox(width: 4)],
                          Text(skill, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? AppColors.primary : context.textGrey)),
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
              onPressed: _selected.isNotEmpty ? () { widget.onSave(_selected.toList()); Navigator.pop(context); } : null,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Save Skills'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mechanic Menu ──────────────────────────────────────────────────────────────

class _MechanicMenu extends StatelessWidget {
  const _MechanicMenu({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.divider)),
      child: ListTile(
        leading: Icon(Icons.account_balance_outlined, color: context.textGrey, size: 22),
        title: Text(t('payout_settings', lang), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark)),
        trailing: Icon(Icons.chevron_right_rounded, color: context.inactive, size: 20),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _PayoutSettingsSheet(),
        ),
      ),
    );
  }
}

// ── Payout Settings Sheet ──────────────────────────────────────────────────────

class _PayoutSettingsSheet extends StatefulWidget {
  const _PayoutSettingsSheet();

  @override
  State<_PayoutSettingsSheet> createState() => _PayoutSettingsSheetState();
}

class _PayoutSettingsSheetState extends State<_PayoutSettingsSheet> {
  final _mpesaCtrl = TextEditingController(text: '+254 7XX XXX XXX');
  String _frequency = 'Instant';

  @override
  void dispose() { _mpesaCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: context.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Payout Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textDark)),
          const SizedBox(height: 4),
          Text('Earnings are sent directly to your M-Pesa', style: TextStyle(fontSize: 13, color: context.textGrey)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Balance', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text('KES 0.00', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: const Text('0 completed jobs', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('M-Pesa Payout Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: _mpesaCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.success, size: 20),
              filled: true,
              fillColor: context.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.divider)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.divider)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: TextStyle(fontSize: 14, color: context.textDark),
          ),
          const SizedBox(height: 16),
          Text('Payout Frequency', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textDark)),
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
                        color: sel ? AppColors.primarySurface : context.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? AppColors.primary : context.divider, width: sel ? 1.5 : 1),
                      ),
                      child: Column(
                        children: [
                          Text(opt, style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: sel ? AppColors.primary : context.textGrey)),
                          if (opt == 'Instant') ...[
                            const SizedBox(height: 2),
                            Text('Auto', style: TextStyle(fontSize: 9, color: sel ? AppColors.primary : context.textGrey)),
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout settings saved')));
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

// ── Sign Out & Dev Buttons ─────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.divider)),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
        title: Text(t('sign_out', lang), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error)),
        onTap: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t('sign_out', lang)),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
                onPressed: () => Navigator.pop(context),
                child: Text(t('sign_out', lang)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevRoleSwitcherButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RoleSwitcherScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2D2D4E))),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFF7C7CFF), size: 18),
            SizedBox(width: 8),
            Text('DEV — Switch Role', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C7CFF), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
