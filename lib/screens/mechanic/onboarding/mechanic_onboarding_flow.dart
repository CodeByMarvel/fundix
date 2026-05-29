import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme_ext.dart';
import '../../../models/mechanic_type.dart';

const _kNairobiZones = [
  'Westlands', 'Parklands', 'Kilimani', 'Kileleshwa',
  'Karen', 'Lang\'ata', 'Ngong Road', 'Lavington',
  'CBD', 'Industrial Area', 'South B', 'South C',
  'Thika Road', 'Mombasa Road', 'Kasarani', 'Ruiru',
  'Eastlands', 'Embakasi', 'Utawala', 'Syokimau',
];

class MechanicOnboardingFlow extends StatefulWidget {
  const MechanicOnboardingFlow({super.key});

  @override
  State<MechanicOnboardingFlow> createState() => _MechanicOnboardingFlowState();
}

class _MechanicOnboardingFlowState extends State<MechanicOnboardingFlow> {
  final _pageController = PageController();
  int _step = 0;
  bool _submitted = false;

  // Step 1
  MechanicTier? _tier;

  // Step 2
  final _idCtrl = TextEditingController();
  final _kraCtrl = TextEditingController();
  bool _idFrontUploaded = false;
  bool _selfieUploaded = false;

  // Step 3
  int _workspacePhotos = 0;
  int _toolsPhotos = 0;

  // Step 4 — Tier 1
  final List<String> _selectedZones = [];
  int _radiusKm = 10;

  // Step 4 — Tier 2
  final _garageNameCtrl = TextEditingController();
  final _garageAddressCtrl = TextEditingController();
  int _exteriorPhotos = 0;

  static const _totalSteps = 5;

  @override
  void dispose() {
    _pageController.dispose();
    _idCtrl.dispose();
    _kraCtrl.dispose();
    _garageNameCtrl.dispose();
    _garageAddressCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _tier != null;
      case 1:
        return _idCtrl.text.trim().length >= 8 &&
            _kraCtrl.text.trim().length >= 8 &&
            _idFrontUploaded;
      case 2:
        return _workspacePhotos >= 2;
      case 3:
        if (_tier == MechanicTier.tier1) {
          return _selectedZones.length >= 2;
        }
        return _garageNameCtrl.text.trim().isNotEmpty &&
            _garageAddressCtrl.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    if (!_canProceed) return;
    if (_step < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _submit() => setState(() => _submitted = true);

  String get _stepTitle => switch (_step) {
        0 => 'Choose Your Path',
        1 => 'Identity Verification',
        2 => 'Work Verification',
        3 => 'Location & Zone',
        _ => 'Review & Submit',
      };

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _SuccessScreen(onDone: () => Navigator.of(context).pop());
    }

    final tier = _tier ?? MechanicTier.tier1;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        title: Text(
          _stepTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: _back,
        ),
      ),
      body: Column(
        children: [
          _StepProgressBar(current: _step, total: _totalSteps),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1TierSelect(
                  selected: _tier,
                  onSelect: (t) => setState(() => _tier = t),
                ),
                _Step2Identity(
                  idCtrl: _idCtrl,
                  kraCtrl: _kraCtrl,
                  idFrontUploaded: _idFrontUploaded,
                  selfieUploaded: _selfieUploaded,
                  onIdFront: () => setState(() => _idFrontUploaded = true),
                  onSelfie: () => setState(() => _selfieUploaded = true),
                  onChange: () => setState(() {}),
                ),
                _Step3WorkVerification(
                  workspacePhotos: _workspacePhotos,
                  toolsPhotos: _toolsPhotos,
                  onAddWorkspace: () =>
                      setState(() { if (_workspacePhotos < 4) _workspacePhotos++; }),
                  onAddTools: () =>
                      setState(() { if (_toolsPhotos < 4) _toolsPhotos++; }),
                ),
                _Step4Location(
                  tier: tier,
                  selectedZones: _selectedZones,
                  radiusKm: _radiusKm,
                  onZoneToggle: (z) => setState(() {
                    if (_selectedZones.contains(z)) {
                      _selectedZones.remove(z);
                    } else {
                      _selectedZones.add(z);
                    }
                  }),
                  onRadiusChanged: (r) => setState(() => _radiusKm = r),
                  garageNameCtrl: _garageNameCtrl,
                  garageAddressCtrl: _garageAddressCtrl,
                  exteriorPhotos: _exteriorPhotos,
                  onAddExterior: () =>
                      setState(() { if (_exteriorPhotos < 4) _exteriorPhotos++; }),
                  onChange: () => setState(() {}),
                ),
                _Step5ReviewSubmit(
                  tier: tier,
                  nationalId: _idCtrl.text.trim(),
                  idFrontUploaded: _idFrontUploaded,
                  selfieUploaded: _selfieUploaded,
                  workspacePhotos: _workspacePhotos,
                  toolsPhotos: _toolsPhotos,
                  selectedZones: _selectedZones,
                  radiusKm: _radiusKm,
                  garageName: _garageNameCtrl.text.trim(),
                  garageAddress: _garageAddressCtrl.text.trim(),
                  exteriorPhotos: _exteriorPhotos,
                ),
              ],
            ),
          ),
          _BottomNav(
            step: _step,
            total: _totalSteps,
            canProceed: _canProceed,
            onBack: _back,
            onNext: _step < _totalSteps - 1 ? _next : _submit,
          ),
        ],
      ),
    );
  }
}

// ── Step progress bar ─────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        children: [
          Row(
            children: List.generate(total, (i) {
              final done = i <= current;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: done ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Step ${current + 1} of $total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.step,
    required this.total,
    required this.canProceed,
    required this.onBack,
    required this.onNext,
  });
  final int step;
  final int total;
  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = step == total - 1;
    return Container(
      color: context.surface,
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          if (step > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textGrey,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: canProceed ? onNext : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.divider,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isLast ? 'Submit Application' : 'Continue',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1 — Choose Professional Type ────────────────────────────────────────

class _Step1TierSelect extends StatelessWidget {
  const _Step1TierSelect({required this.selected, required this.onSelect});
  final MechanicTier? selected;
  final ValueChanged<MechanicTier> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you work?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the type that best describes your operation. This determines your allowed job types and verification requirements.',
            style: TextStyle(fontSize: 14, color: context.textGrey, height: 1.5),
          ),
          const SizedBox(height: 28),
          _TierCard(
            tier: MechanicTier.tier1,
            isSelected: selected == MechanicTier.tier1,
            icon: Icons.directions_bike_rounded,
            color: AppColors.primary,
            title: 'Mobile Technician',
            subtitle: 'Tier 1 · Freelance & on-site work',
            description:
                'You work independently, travel to customers, and handle straightforward mobile jobs.',
            allowedJobs: [
              'Battery jumpstart & replacement',
              'Tire change & puncture repair',
              'Basic diagnostics & inspection',
              'Overheating & coolant issues',
              'Minor electrical work',
            ],
            requirements: [
              'National ID + selfie',
              'Tools/workspace photos',
              'Approved operational zones',
            ],
            onTap: () => onSelect(MechanicTier.tier1),
          ),
          const SizedBox(height: 16),
          _TierCard(
            tier: MechanicTier.tier2,
            isSelected: selected == MechanicTier.tier2,
            icon: Icons.store_rounded,
            color: const Color(0xFF6366F1),
            title: 'Garage Partner',
            subtitle: 'Tier 2 · Verified workshop operator',
            description:
                'You run a fixed garage or workshop with full repair capability and structured operations.',
            allowedJobs: [
              'Accident & bodywork repairs',
              'Engine overhaul & rebuilds',
              'Suspension & brakes',
              'Diagnostics & electrical',
              'Long-term repair jobs',
            ],
            requirements: [
              'Business permit + KRA PIN',
              'Garage photos & Maps pin',
              'Workspace & team evidence',
              'Fundix review call',
            ],
            onTap: () => onSelect(MechanicTier.tier2),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Not sure? Start with Tier 1. You can upgrade to Tier 2 after you\'ve built a track record.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.isSelected,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.allowedJobs,
    required this.requirements,
    required this.onTap,
  });
  final MechanicTier tier;
  final bool isSelected;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String description;
  final List<String> allowedJobs;
  final List<String> requirements;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : context.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? color : AppColors.inactive,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: TextStyle(
                  fontSize: 13, color: context.textGrey, height: 1.5),
            ),
            const SizedBox(height: 14),
            Text(
              'Allowed jobs',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.textDark,
                  letterSpacing: 0.4),
            ),
            const SizedBox(height: 6),
            ...allowedJobs.map((j) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 13, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(j,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textGrey))),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Text(
              'Requirements',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.textDark,
                  letterSpacing: 0.4),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: requirements
                  .map((r) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: color),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2 — Identity Verification ───────────────────────────────────────────

class _Step2Identity extends StatelessWidget {
  const _Step2Identity({
    required this.idCtrl,
    required this.kraCtrl,
    required this.idFrontUploaded,
    required this.selfieUploaded,
    required this.onIdFront,
    required this.onSelfie,
    required this.onChange,
  });
  final TextEditingController idCtrl;
  final TextEditingController kraCtrl;
  final bool idFrontUploaded;
  final bool selfieUploaded;
  final VoidCallback onIdFront;
  final VoidCallback onSelfie;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify your identity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your information is encrypted and used only for verification. We never share it publicly.',
            style: TextStyle(fontSize: 14, color: context.textGrey, height: 1.5),
          ),
          const SizedBox(height: 28),
          _FormLabel('National ID Number *'),
          const SizedBox(height: 6),
          _OnboardingTextField(
            controller: idCtrl,
            hint: '12345678',
            keyboardType: TextInputType.number,
            onChanged: (_) => onChange(),
          ),
          const SizedBox(height: 16),
          _FormLabel('KRA PIN *'),
          const SizedBox(height: 6),
          _OnboardingTextField(
            controller: kraCtrl,
            hint: 'A000000000A',
            onChanged: (_) => onChange(),
          ),
          const SizedBox(height: 24),
          _FormLabel('Documents'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _UploadSlot(
                  label: 'ID Front Photo',
                  sublabel: 'Required',
                  icon: Icons.badge_outlined,
                  uploaded: idFrontUploaded,
                  required: true,
                  onTap: onIdFront,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _UploadSlot(
                  label: 'Selfie with ID',
                  sublabel: 'Recommended',
                  icon: Icons.face_outlined,
                  uploaded: selfieUploaded,
                  required: false,
                  onTap: onSelfie,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: AppColors.warning, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your ID and documents are stored securely and reviewed only by the Fundix team during verification.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3 — Work Verification ────────────────────────────────────────────────

class _Step3WorkVerification extends StatelessWidget {
  const _Step3WorkVerification({
    required this.workspacePhotos,
    required this.toolsPhotos,
    required this.onAddWorkspace,
    required this.onAddTools,
  });
  final int workspacePhotos;
  final int toolsPhotos;
  final VoidCallback onAddWorkspace;
  final VoidCallback onAddTools;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Show your work',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Photos help us verify you\'re operational and serious. At least 2 workspace photos are required.',
            style: TextStyle(fontSize: 14, color: context.textGrey, height: 1.5),
          ),
          const SizedBox(height: 28),
          _FormLabel('Workspace / Garage Photos *'),
          const SizedBox(height: 4),
          Text(
            'Your workstation, bay, or repair area. Min 2, up to 4.',
            style: TextStyle(fontSize: 12, color: context.textGrey),
          ),
          const SizedBox(height: 12),
          _PhotoGrid(
            count: workspacePhotos,
            max: 4,
            onAdd: onAddWorkspace,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          _FormLabel('Tools & Equipment Photos'),
          const SizedBox(height: 4),
          Text(
            'Show the tools and equipment you use. Up to 4.',
            style: TextStyle(fontSize: 12, color: context.textGrey),
          ),
          const SizedBox(height: 12),
          _PhotoGrid(
            count: toolsPhotos,
            max: 4,
            onAdd: onAddTools,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          _UploadSlot(
            label: 'Intro Video (Optional)',
            sublabel: '30–60 seconds showing you at work',
            icon: Icons.videocam_outlined,
            uploaded: false,
            required: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ── Step 4 — Location Verification ───────────────────────────────────────────

class _Step4Location extends StatelessWidget {
  const _Step4Location({
    required this.tier,
    required this.selectedZones,
    required this.radiusKm,
    required this.onZoneToggle,
    required this.onRadiusChanged,
    required this.garageNameCtrl,
    required this.garageAddressCtrl,
    required this.exteriorPhotos,
    required this.onAddExterior,
    required this.onChange,
  });
  final MechanicTier tier;
  final List<String> selectedZones;
  final int radiusKm;
  final ValueChanged<String> onZoneToggle;
  final ValueChanged<int> onRadiusChanged;
  final TextEditingController garageNameCtrl;
  final TextEditingController garageAddressCtrl;
  final int exteriorPhotos;
  final VoidCallback onAddExterior;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: tier == MechanicTier.tier1
          ? _Tier1Location(
              selectedZones: selectedZones,
              radiusKm: radiusKm,
              onZoneToggle: onZoneToggle,
              onRadiusChanged: onRadiusChanged,
            )
          : _Tier2Location(
              garageNameCtrl: garageNameCtrl,
              garageAddressCtrl: garageAddressCtrl,
              exteriorPhotos: exteriorPhotos,
              onAddExterior: onAddExterior,
              onChange: onChange,
            ),
    );
  }
}

class _Tier1Location extends StatelessWidget {
  const _Tier1Location({
    required this.selectedZones,
    required this.radiusKm,
    required this.onZoneToggle,
    required this.onRadiusChanged,
  });
  final List<String> selectedZones;
  final int radiusKm;
  final ValueChanged<String> onZoneToggle;
  final ValueChanged<int> onRadiusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where do you operate?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the Nairobi zones you\'re willing to operate in. You\'ll only receive jobs within these areas.',
          style: TextStyle(fontSize: 14, color: context.textGrey, height: 1.5),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _FormLabel('Operational Zones'),
            const Spacer(),
            if (selectedZones.isNotEmpty)
              Text(
                '${selectedZones.length} selected',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select at least 2 zones.',
          style: TextStyle(fontSize: 12, color: context.textGrey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kNairobiZones.map((zone) {
            final selected = selectedZones.contains(zone);
            return GestureDetector(
              onTap: () => onZoneToggle(zone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : context.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : context.divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  zone,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : context.textGrey,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        _FormLabel('Work Radius'),
        const SizedBox(height: 4),
        Text(
          'Maximum distance from your base you\'ll accept jobs.',
          style: TextStyle(fontSize: 12, color: context.textGrey),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.divider),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Radius',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.textDark),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$radiusKm km',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              Slider(
                value: radiusKm.toDouble(),
                min: 5,
                max: 25,
                divisions: 4,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.divider,
                onChanged: (v) => onRadiusChanged(v.round()),
                label: '${radiusKm}km',
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5 km',
                      style: TextStyle(
                          fontSize: 11, color: context.textGrey)),
                  Text('25 km',
                      style: TextStyle(
                          fontSize: 11, color: context.textGrey)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tier2Location extends StatelessWidget {
  const _Tier2Location({
    required this.garageNameCtrl,
    required this.garageAddressCtrl,
    required this.exteriorPhotos,
    required this.onAddExterior,
    required this.onChange,
  });
  final TextEditingController garageNameCtrl;
  final TextEditingController garageAddressCtrl;
  final int exteriorPhotos;
  final VoidCallback onAddExterior;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your garage location',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'We verify garages have a real, fixed location. Customers will see your garage on the map.',
          style: TextStyle(fontSize: 14, color: context.textGrey, height: 1.5),
        ),
        const SizedBox(height: 28),
        _FormLabel('Garage / Workshop Name *'),
        const SizedBox(height: 6),
        _OnboardingTextField(
          controller: garageNameCtrl,
          hint: 'e.g. Kariuki Auto Workshop',
          onChanged: (_) => onChange(),
        ),
        const SizedBox(height: 16),
        _FormLabel('Physical Address *'),
        const SizedBox(height: 6),
        _OnboardingTextField(
          controller: garageAddressCtrl,
          hint: 'e.g. 14 Mombasa Road, Industrial Area',
          onChanged: (_) => onChange(),
        ),
        const SizedBox(height: 16),
        _FormLabel('Google Maps Link'),
        const SizedBox(height: 6),
        _OnboardingTextField(
          hint: 'Paste a Google Maps link to your location',
          onChanged: (_) {},
        ),
        const SizedBox(height: 24),
        _FormLabel('Exterior Photos'),
        const SizedBox(height: 4),
        Text(
          'Front of your garage/workshop so reviewers can confirm the location.',
          style: TextStyle(fontSize: 12, color: context.textGrey),
        ),
        const SizedBox(height: 12),
        _PhotoGrid(
          count: exteriorPhotos,
          max: 4,
          onAdd: onAddExterior,
          color: const Color(0xFF6366F1),
        ),
      ],
    );
  }
}

// ── Step 5 — Review & Submit ──────────────────────────────────────────────────

class _Step5ReviewSubmit extends StatelessWidget {
  const _Step5ReviewSubmit({
    required this.tier,
    required this.nationalId,
    required this.idFrontUploaded,
    required this.selfieUploaded,
    required this.workspacePhotos,
    required this.toolsPhotos,
    required this.selectedZones,
    required this.radiusKm,
    required this.garageName,
    required this.garageAddress,
    required this.exteriorPhotos,
  });
  final MechanicTier tier;
  final String nationalId;
  final bool idFrontUploaded;
  final bool selfieUploaded;
  final int workspacePhotos;
  final int toolsPhotos;
  final List<String> selectedZones;
  final int radiusKm;
  final String garageName;
  final String garageAddress;
  final int exteriorPhotos;

  @override
  Widget build(BuildContext context) {
    final maskedId = nationalId.length >= 4
        ? '••••${nationalId.substring(nationalId.length - 4)}'
        : nationalId;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your application',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Double-check everything before submitting. Once submitted, our team will review your application within 2–5 business days.',
            style: TextStyle(fontSize: 14, color: context.textGrey, height: 1.5),
          ),
          const SizedBox(height: 24),
          _ReviewCard(
            title: 'Professional Type',
            children: [
              _ReviewRow(
                label: 'Tier',
                value: tier.displayName,
                icon: tier == MechanicTier.tier1
                    ? Icons.directions_bike_rounded
                    : Icons.store_rounded,
                color: tier == MechanicTier.tier1
                    ? AppColors.primary
                    : const Color(0xFF6366F1),
              ),
              _ReviewRow(
                label: 'Entry Level',
                value: MechanicLevel.level1.displayName,
                icon: Icons.verified_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReviewCard(
            title: 'Identity',
            children: [
              _ReviewRow(
                label: 'National ID',
                value: maskedId,
                icon: Icons.badge_outlined,
                color: AppColors.textGrey,
              ),
              _ReviewRow(
                label: 'ID Photo',
                value: idFrontUploaded ? 'Uploaded' : 'Missing',
                icon: idFrontUploaded
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: idFrontUploaded ? AppColors.success : AppColors.error,
              ),
              _ReviewRow(
                label: 'Selfie',
                value: selfieUploaded ? 'Uploaded' : 'Not added',
                icon: selfieUploaded
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selfieUploaded ? AppColors.success : AppColors.textGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ReviewCard(
            title: 'Work Evidence',
            children: [
              _ReviewRow(
                label: 'Workspace photos',
                value: '$workspacePhotos added',
                icon: Icons.photo_library_outlined,
                color: workspacePhotos >= 2
                    ? AppColors.success
                    : AppColors.warning,
              ),
              _ReviewRow(
                label: 'Tools photos',
                value: '$toolsPhotos added',
                icon: Icons.build_outlined,
                color: AppColors.textGrey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tier == MechanicTier.tier1)
            _ReviewCard(
              title: 'Location',
              children: [
                _ReviewRow(
                  label: 'Zones selected',
                  value: '${selectedZones.length} zones',
                  icon: Icons.location_on_outlined,
                  color: selectedZones.length >= 2
                      ? AppColors.success
                      : AppColors.warning,
                ),
                _ReviewRow(
                  label: 'Work radius',
                  value: '$radiusKm km',
                  icon: Icons.radar_rounded,
                  color: AppColors.textGrey,
                ),
              ],
            )
          else
            _ReviewCard(
              title: 'Garage',
              children: [
                _ReviewRow(
                  label: 'Name',
                  value: garageName.isNotEmpty ? garageName : '—',
                  icon: Icons.store_outlined,
                  color: AppColors.textGrey,
                ),
                _ReviewRow(
                  label: 'Address',
                  value: garageAddress.isNotEmpty ? garageAddress : '—',
                  icon: Icons.place_outlined,
                  color: AppColors.textGrey,
                ),
                _ReviewRow(
                  label: 'Exterior photos',
                  value: '$exteriorPhotos added',
                  icon: Icons.photo_library_outlined,
                  color: AppColors.textGrey,
                ),
              ],
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'What happens next',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _NextStep(
                    number: '1', text: 'Our team reviews your application'),
                _NextStep(
                    number: '2',
                    text:
                        'We may contact you for clarification or a short call'),
                _NextStep(
                    number: '3',
                    text: 'Decision sent within 2–5 business days'),
                _NextStep(
                    number: '4',
                    text:
                        'Approved? You\'re in as ${tier.displayName} Level 1'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success screen ────────────────────────────────────────────────────────────

class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    size: 60, color: AppColors.success),
              ),
              const SizedBox(height: 28),
              Text(
                'Application Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: context.textDark,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Our team will review your application and get back to you within 2–5 business days via email.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textGrey, height: 1.6),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Profile',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.textDark,
      ),
    );
  }
}

class _OnboardingTextField extends StatelessWidget {
  const _OnboardingTextField({
    this.controller,
    required this.hint,
    this.keyboardType,
    required this.onChanged,
  });
  final TextEditingController? controller;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
        filled: true,
        fillColor: context.surface,
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
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      style: TextStyle(fontSize: 14, color: context.textDark),
    );
  }
}

class _UploadSlot extends StatelessWidget {
  const _UploadSlot({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.uploaded,
    required this.required,
    required this.onTap,
  });
  final String label;
  final String sublabel;
  final IconData icon;
  final bool uploaded;
  final bool required;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploaded ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: uploaded
              ? AppColors.success.withValues(alpha: 0.05)
              : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded
                ? AppColors.success.withValues(alpha: 0.5)
                : context.divider,
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: uploaded
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                uploaded ? Icons.check_rounded : icon,
                color: uploaded ? AppColors.success : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: uploaded ? AppColors.success : context.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              uploaded ? 'Uploaded' : sublabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: uploaded ? AppColors.success : context.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    required this.count,
    required this.max,
    required this.onAdd,
    required this.color,
  });
  final int count;
  final int max;
  final VoidCallback onAdd;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        ...List.generate(
          count,
          (i) => _FilledPhotoSlot(color: color, index: i + 1),
        ),
        if (count < max) _AddPhotoSlot(onTap: onAdd, color: color),
      ],
    );
  }
}

class _FilledPhotoSlot extends StatelessWidget {
  const _FilledPhotoSlot({required this.color, required this.index});
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_rounded, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            '$index',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoSlot extends StatelessWidget {
  const _AddPhotoSlot({required this.onTap, required this.color});
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: context.divider, style: BorderStyle.solid, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: context.textGrey, size: 22),
            const SizedBox(height: 2),
            Text(
              'Add',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: context.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divider),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style:
                TextStyle(fontSize: 13, color: context.textGrey),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textDark),
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textGrey, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
