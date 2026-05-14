import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/job_notifier.dart';

// ── Public entry point ─────────────────────────────────────────────────────────

/// Opens the multi-step request creation flow.
///
/// - [preselectedType]: 'repair' or 'routine' — skips step 0 and pre-fills the type.
/// - [preselectedCategory]: a specific category from the category grid — skips step 0
///   and pre-fills both type and category.
/// - [preselectedVehicleId]: pre-selects a vehicle in step 1.
void openRequestFlow(
  BuildContext context, {
  String? preselectedCategory,
  String? preselectedType,
  String? preselectedVehicleId,
}) {
  const routineCategories = {
    'Oil Change',
    'Major Service',
    'Brake Service',
    'Tire Rotation',
    'Inspection',
  };

  String? type;
  String? service;
  String? category;
  int startStep = 0;

  if (preselectedType != null) {
    startStep = 1;
    type = preselectedType;
  } else if (preselectedCategory != null && preselectedCategory != 'More') {
    startStep = 1;
    if (routineCategories.contains(preselectedCategory)) {
      type = 'routine';
      service = preselectedCategory;
    } else {
      type = 'repair';
      category = preselectedCategory;
    }
  }

  Navigator.push<void>(
    context,
    PageRouteBuilder(
      pageBuilder: (_, _, _) => RequestCreationFlow(
        initialStep: startStep,
        preselectedType: type,
        preselectedService: service,
        preselectedCategory: category,
        preselectedVehicleId: preselectedVehicleId,
      ),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

// ── Main flow widget ───────────────────────────────────────────────────────────

class RequestCreationFlow extends ConsumerStatefulWidget {
  const RequestCreationFlow({
    super.key,
    this.initialStep = 0,
    this.preselectedType,
    this.preselectedService,
    this.preselectedCategory,
    this.preselectedVehicleId,
  });

  final int initialStep;
  final String? preselectedType;
  final String? preselectedService;
  final String? preselectedCategory;
  final String? preselectedVehicleId;

  @override
  ConsumerState<RequestCreationFlow> createState() =>
      _RequestCreationFlowState();
}

class _RequestCreationFlowState extends ConsumerState<RequestCreationFlow> {
  static const int _totalSteps = 5; // indices 0–4

  late int _step;
  String? _requestType;
  Vehicle? _selectedVehicle;
  String? _selectedService;   // routine only
  String? _selectedCategory;  // repair only
  String? _expandedCategory;  // which repair category is showing sub-tags
  final Set<String> _selectedTags = {};
  final _descController = TextEditingController();
  String? _urgency;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _requestType = widget.preselectedType;
    _selectedService = widget.preselectedService;
    _selectedCategory = widget.preselectedCategory;
    _expandedCategory = widget.preselectedCategory;

    if (widget.preselectedVehicleId != null) {
      final vehicles = ref.read(vehicleProvider);
      try {
        _selectedVehicle =
            vehicles.firstWhere((v) => v.id == widget.preselectedVehicleId);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _requestType != null;
      case 1:
        return _selectedVehicle != null;
      case 2:
        return _requestType == 'routine'
            ? _selectedService != null
            : _selectedCategory != null;
      case 3:
        return true; // description is optional
      case 4:
        return _urgency != null;
      default:
        return false;
    }
  }

  void _goNext() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_step > widget.initialStep) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  // ── Submission ──────────────────────────────────────────────────────────────

  static const _routineCategoryMap = {
    'Oil Change': 'Oil Change',
    'Major Service': 'Diagnostics',
    'Brake Service': 'Brakes',
    'Tire Rotation': 'Tire',
    'Inspection': 'Diagnostics',
  };

  void _submit() {
    final extra = _descController.text.trim();
    final urgencyPrefix =
        _urgency != null ? 'Urgency: $_urgency.' : '';
    String description;
    String? manualCategory;

    if (_requestType == 'routine') {
      final service = _selectedService ?? 'Service';
      final base =
          extra.isEmpty ? 'Routine $service' : 'Routine $service. $extra';
      description =
          urgencyPrefix.isEmpty ? base : '$urgencyPrefix $base';
      manualCategory = _routineCategoryMap[service];
    } else {
      final tags = _selectedTags.join(', ');
      final parts = <String>[
        if (_selectedCategory != null && tags.isNotEmpty)
          '$_selectedCategory: $tags',
        if (_selectedCategory != null && tags.isEmpty)
          '$_selectedCategory issue',
        if (extra.isNotEmpty) extra,
      ];
      final base = parts.isEmpty
          ? '${_selectedCategory ?? 'Vehicle'} issue'
          : parts.join('. ');
      description =
          urgencyPrefix.isEmpty ? base : '$urgencyPrefix $base';
      manualCategory = _selectedCategory;
    }

    Navigator.of(context).pop();

    ref.read(jobProvider.notifier).submitRequest(
          description: description,
          carType: _selectedVehicle?.displayName ?? 'Unknown vehicle',
          location: 'Nairobi, Kenya',
          manualCategory: manualCategory,
        );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'What kind of service?';
      case 1:
        return 'Which vehicle?';
      case 2:
        return _requestType == 'routine'
            ? 'What service do you need?'
            : "What's the problem?";
      case 3:
        return 'Anything to add?';
      case 4:
        return 'How urgent is this?';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotsTotal = _totalSteps - widget.initialStep;
    final dotsCurrent = _step - widget.initialStep;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            _step == widget.initialStep
                ? Icons.close_rounded
                : Icons.arrow_back_rounded,
          ),
          onPressed: _goBack,
        ),
        title: _StepDots(current: dotsCurrent, total: dotsTotal),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Text(
                      _stepTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStep(),
                  ],
                ),
              ),
            ),
          ),
          _BottomBar(
            isLastStep: _step == _totalSteps - 1,
            enabled: _canContinue,
            onTap: _goNext,
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildTypeStep();
      case 1:
        return _buildVehicleStep();
      case 2:
        return _buildProblemStep();
      case 3:
        return _buildDescriptionStep();
      case 4:
        return _buildUrgencyStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Request type ────────────────────────────────────────────────────

  Widget _buildTypeStep() {
    return Column(
      children: [
        _TypeCard(
          title: 'Routine Service',
          subtitle: 'Scheduled maintenance',
          examples: const [
            'Oil change',
            'Brake service',
            'Tire rotation',
            'Major service',
            'Inspection',
          ],
          icon: Icons.build_circle_outlined,
          color: AppColors.success,
          selected: _requestType == 'routine',
          onTap: () {
            setState(() {
              _requestType = 'routine';
              _selectedCategory = null;
              _selectedTags.clear();
            });
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted && _step == 0) setState(() => _step = 1);
            });
          },
        ),
        const SizedBox(height: 14),
        _TypeCard(
          title: 'Repair / Problem',
          subtitle: "Something's wrong",
          examples: const [
            'Engine issue',
            "Car won't start",
            'Overheating',
            'Strange noise',
            'Suspension',
          ],
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          selected: _requestType == 'repair',
          onTap: () {
            setState(() {
              _requestType = 'repair';
              _selectedService = null;
            });
            Future.delayed(const Duration(milliseconds: 250), () {
              if (mounted && _step == 0) setState(() => _step = 1);
            });
          },
        ),
      ],
    );
  }

  // ── Step 1: Vehicle selection ───────────────────────────────────────────────

  Widget _buildVehicleStep() {
    final vehicles = ref.watch(vehicleProvider);
    return Column(
      children: [
        ...vehicles.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _VehicleCard(
                vehicle: v,
                selected: _selectedVehicle?.id == v.id,
                onTap: () => setState(() => _selectedVehicle = v),
              ),
            )),
        _AddVehicleTile(),
      ],
    );
  }

  // ── Step 2: Service or problem tags ────────────────────────────────────────

  Widget _buildProblemStep() {
    if (_requestType == 'routine') {
      return _RoutineServiceList(
        selected: _selectedService,
        onSelect: (s) => setState(() => _selectedService = s),
      );
    }
    return _RepairCategoryPanel(
      expandedCategory: _expandedCategory,
      selectedCategory: _selectedCategory,
      selectedTags: _selectedTags,
      onCategoryTap: (cat) => setState(() {
        _expandedCategory = _expandedCategory == cat ? null : cat;
        _selectedCategory = cat;
        _selectedTags.clear();
      }),
      onTagTap: (tag) => setState(() {
        if (_selectedTags.contains(tag)) {
          _selectedTags.remove(tag);
        } else {
          _selectedTags.add(tag);
        }
      }),
    );
  }

  // ── Step 3: Optional description ───────────────────────────────────────────

  Widget _buildDescriptionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(
          vehicle: _selectedVehicle,
          service: _requestType == 'routine' ? _selectedService : null,
          category: _requestType == 'repair' ? _selectedCategory : null,
          tags: _selectedTags,
        ),
        const SizedBox(height: 24),
        const Text(
          'Describe what\'s happening',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Optional — most customers skip this',
          style: TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _descController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'When did it start? Any sounds or warning lights?',
          ),
        ),
      ],
    );
  }

  // ── Step 4: Urgency ─────────────────────────────────────────────────────────

  Widget _buildUrgencyStep() {
    return _UrgencySelector(
      selected: _urgency,
      onSelect: (u) => setState(() => _urgency = u),
    );
  }
}

// ── Step indicator ─────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        total,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i <= current ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

// ── Bottom action bar ──────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar(
      {required this.isLastStep, required this.enabled, required this.onTap});
  final bool isLastStep;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          child: Text(isLastStep ? 'Find Mechanic' : 'Continue'),
        ),
      ),
    );
  }
}

// ── Step 0 widgets ─────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.title,
    required this.subtitle,
    required this.examples,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<String> examples;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textGrey),
                    ),
                  ],
                ),
                const Spacer(),
                if (selected) Icon(Icons.check_circle_rounded, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: examples
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          e,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textGrey),
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

// ── Step 1 widgets ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  const _VehicleCard(
      {required this.vehicle, required this.selected, required this.onTap});
  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car_rounded,
                color: selected ? AppColors.primary : AppColors.textGrey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicle.subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _AddVehicleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adding vehicles coming soon'),
          duration: Duration(seconds: 2),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            const Text(
              'Add New Vehicle',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2 widgets ─────────────────────────────────────────────────────────────

class _RoutineServiceList extends StatelessWidget {
  const _RoutineServiceList({required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String> onSelect;

  static const _services = [
    (Icons.oil_barrel_outlined, 'Oil Change', AppColors.success),
    (Icons.build_circle_outlined, 'Major Service', AppColors.primary),
    (Icons.do_not_touch_rounded, 'Brake Service', AppColors.error),
    (Icons.tire_repair_rounded, 'Tire Rotation', AppColors.warning),
    (Icons.search_rounded, 'Inspection', Color(0xFF6366F1)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _services
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoutineServiceCard(
                  icon: s.$1,
                  label: s.$2,
                  color: s.$3,
                  selected: selected == s.$2,
                  onTap: () => onSelect(s.$2),
                ),
              ))
          .toList(),
    );
  }
}

class _RoutineServiceCard extends StatelessWidget {
  const _RoutineServiceCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textDark,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ProblemCategoryData {
  const _ProblemCategoryData({
    required this.name,
    required this.icon,
    required this.color,
    required this.tags,
  });
  final String name;
  final IconData icon;
  final Color color;
  final List<String> tags;
}

class _RepairCategoryPanel extends StatelessWidget {
  const _RepairCategoryPanel({
    required this.expandedCategory,
    required this.selectedCategory,
    required this.selectedTags,
    required this.onCategoryTap,
    required this.onTagTap,
  });

  final String? expandedCategory;
  final String? selectedCategory;
  final Set<String> selectedTags;
  final ValueChanged<String> onCategoryTap;
  final ValueChanged<String> onTagTap;

  static const _categories = [
    _ProblemCategoryData(
      name: 'Engine',
      icon: Icons.settings_outlined,
      color: AppColors.error,
      tags: [
        'Overheating',
        'Misfiring',
        'Knocking',
        'Stalling',
        'Smoking',
        "Won't rev",
      ],
    ),
    _ProblemCategoryData(
      name: 'Electrical',
      icon: Icons.electric_bolt_rounded,
      color: Color(0xFF6366F1),
      tags: [
        'Battery dead',
        'Starter issues',
        'Alternator fault',
        'Wiring issue',
        'Fuse / short',
      ],
    ),
    _ProblemCategoryData(
      name: 'Suspension',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF0891B2),
      tags: [
        'Shocks / struts',
        'Steering issue',
        'Vibration',
        'Rough ride',
        'Pulling to side',
      ],
    ),
    _ProblemCategoryData(
      name: 'Brakes',
      icon: Icons.do_not_touch_rounded,
      color: AppColors.error,
      tags: [
        'Squeaking',
        'Grinding noise',
        'Weak braking',
        'Brake light on',
        'Pulling when braking',
      ],
    ),
    _ProblemCategoryData(
      name: 'Transmission',
      icon: Icons.settings_input_component_rounded,
      color: AppColors.warning,
      tags: ['Slipping gears', 'Hard shifting', 'Clutch issues', 'Loud noise'],
    ),
    _ProblemCategoryData(
      name: 'AC / Cooling',
      icon: Icons.ac_unit_rounded,
      color: Color(0xFF0891B2),
      tags: ['No cold air', 'Overheating', 'Coolant leak', 'Fan issues'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _categories.map((cat) {
        final isExpanded = expandedCategory == cat.name;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryRow(
                category: cat,
                selected: selectedCategory == cat.name,
                expanded: isExpanded,
                onTap: () => onCategoryTap(cat.name),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: cat.tags
                              .map((tag) => _TagChip(
                                    label: tag,
                                    selected: selectedTags.contains(tag),
                                    color: cat.color,
                                    onTap: () => onTagTap(tag),
                                  ))
                              .toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });
  final _ProblemCategoryData category;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? category.color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: category.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? category.color : AppColors.textDark,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: selected ? category.color : AppColors.textGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

// ── Step 3 widgets ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.vehicle,
    this.service,
    this.category,
    required this.tags,
  });
  final Vehicle? vehicle;
  final String? service;
  final String? category;
  final Set<String> tags;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR REQUEST',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (vehicle != null)
            _SummaryRow(
              icon: Icons.directions_car_rounded,
              color: AppColors.primary,
              text: vehicle!.displayName,
            ),
          if (service != null) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.build_circle_outlined,
              color: AppColors.success,
              text: service!,
            ),
          ],
          if (category != null) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              text: tags.isEmpty
                  ? '$category issue'
                  : '$category — ${tags.join(', ')}',
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textDark, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ── Step 4 widgets ─────────────────────────────────────────────────────────────

class _UrgencyOption {
  const _UrgencyOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _UrgencySelector extends StatelessWidget {
  const _UrgencySelector({required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String> onSelect;

  static const _options = [
    _UrgencyOption(
      label: 'ASAP',
      subtitle: 'I need help right away',
      icon: Icons.flash_on_rounded,
      color: AppColors.error,
    ),
    _UrgencyOption(
      label: 'Within 2 hours',
      subtitle: 'Flexible but soon',
      icon: Icons.schedule_rounded,
      color: AppColors.warning,
    ),
    _UrgencyOption(
      label: 'Today',
      subtitle: 'Anytime today works',
      icon: Icons.today_rounded,
      color: AppColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _options
          .map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UrgencyCard(
                  option: opt,
                  selected: selected == opt.label,
                  onTap: () => onSelect(opt.label),
                ),
              ))
          .toList(),
    );
  }
}

class _UrgencyCard extends StatelessWidget {
  const _UrgencyCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final _UrgencyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? option.color.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? option.color : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, color: option.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? option.color : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: option.color, size: 22),
          ],
        ),
      ),
    );
  }
}
