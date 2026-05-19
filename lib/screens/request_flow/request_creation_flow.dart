import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../models/vehicle.dart';
import '../../providers/vehicle_provider.dart';
import '../../providers/job_notifier.dart';

// ── Public entry point ─────────────────────────────────────────────────────────

void openRequestFlow(
  BuildContext context, {
  String? preselectedType,
  String? preselectedVehicleId,
}) {
  Navigator.push<void>(
    context,
    PageRouteBuilder(
      pageBuilder: (_, _, _) => RequestCreationFlow(
        initialStep: preselectedType != null ? 1 : 0,
        preselectedType: preselectedType,
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

// ── Data models ────────────────────────────────────────────────────────────────

class _ServiceCategory {
  const _ServiceCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.services,
    required this.description,
  });
  final String name;
  final IconData icon;
  final Color color;
  final List<String> services;
  final String description;
}

class _RepairProblem {
  const _RepairProblem({
    required this.name,
    required this.icon,
    required this.color,
    required this.subtitle,
  });
  final String name;
  final IconData icon;
  final Color color;
  final String subtitle;
}

class _DiagQuestion {
  const _DiagQuestion({
    required this.key,
    required this.text,
    required this.options,
  });
  final String key;
  final String text;
  final List<String> options;
}

// ── Static data ────────────────────────────────────────────────────────────────

const _serviceCategories = <_ServiceCategory>[
  _ServiceCategory(
    name: 'Engine Service',
    icon: Icons.settings_outlined,
    color: Color(0xFF6366F1),
    description: 'Oil, filter, plugs & internals',
    services: [
      'Oil change',
      'Air filter replacement',
      'Spark plug replacement',
      'Coolant flush',
      'Timing belt check',
      'Fuel filter replacement',
    ],
  ),
  _ServiceCategory(
    name: 'Brake Service',
    icon: Icons.do_not_touch_rounded,
    color: AppColors.error,
    description: 'Pads, rotors, fluid & lines',
    services: [
      'Brake pad replacement',
      'Brake fluid change',
      'Rotor resurfacing',
      'Brake line inspection',
      'Handbrake adjustment',
    ],
  ),
  _ServiceCategory(
    name: 'Tire Service',
    icon: Icons.tire_repair_rounded,
    color: AppColors.warning,
    description: 'Rotation, balancing & alignment',
    services: [
      'Tire rotation',
      'Wheel balancing',
      'Pressure check & inflate',
      'Wheel alignment',
      'Tire replacement',
    ],
  ),
  _ServiceCategory(
    name: 'Electrical Service',
    icon: Icons.electric_bolt_rounded,
    color: AppColors.primary,
    description: 'Battery, alternator & wiring',
    services: [
      'Battery test',
      'Battery replacement',
      'Alternator check',
      'Starter check',
      'Fuse & wiring inspection',
    ],
  ),
  _ServiceCategory(
    name: 'Full Inspection',
    icon: Icons.search_rounded,
    color: AppColors.success,
    description: '30-point comprehensive check',
    services: [
      '30-point inspection',
      'Pre-purchase inspection',
      'Annual service check',
      'Road-worthiness check',
    ],
  ),
  _ServiceCategory(
    name: 'Other',
    icon: Icons.more_horiz_rounded,
    color: AppColors.textGrey,
    description: 'Custom or unlisted service',
    services: [
      'General service',
      'Custom request',
      'AC service',
      'Suspension service',
    ],
  ),
];

const _repairProblems = <_RepairProblem>[
  _RepairProblem(
    name: "Won't start",
    icon: Icons.power_settings_new_rounded,
    color: AppColors.error,
    subtitle: 'Engine not cranking or turning over',
  ),
  _RepairProblem(
    name: 'Overheating',
    icon: Icons.whatshot_rounded,
    color: AppColors.error,
    subtitle: 'Temperature rising, steam or warning light',
  ),
  _RepairProblem(
    name: 'Strange sound',
    icon: Icons.volume_up_rounded,
    color: AppColors.warning,
    subtitle: 'Knocking, grinding, squeaking or rattling',
  ),
  _RepairProblem(
    name: 'Smoke',
    icon: Icons.blur_on_rounded,
    color: AppColors.textGrey,
    subtitle: 'Visible smoke from engine, exhaust or cabin',
  ),
  _RepairProblem(
    name: 'Brake issue',
    icon: Icons.do_not_touch_rounded,
    color: AppColors.error,
    subtitle: 'Poor stopping, spongy pedal or brake light',
  ),
  _RepairProblem(
    name: 'Electrical issue',
    icon: Icons.electric_bolt_rounded,
    color: Color(0xFF6366F1),
    subtitle: 'Lights, battery, starter or dashboard faults',
  ),
  _RepairProblem(
    name: 'Steering issue',
    icon: Icons.navigation_rounded,
    color: AppColors.warning,
    subtitle: 'Heavy, pulling, vibrating or noisy steering',
  ),
  _RepairProblem(
    name: 'Other issue',
    icon: Icons.help_outline_rounded,
    color: AppColors.textGrey,
    subtitle: "Something else — describe it in the notes",
  ),
];

const Map<String, List<_DiagQuestion>> _diagData = {
  "Won't start": [
    _DiagQuestion(key: 'lights', text: 'Dashboard lights on?', options: ['Yes', 'No']),
    _DiagQuestion(key: 'clicking', text: 'Clicking when you turn the key?', options: ['Yes', 'No']),
    _DiagQuestion(key: 'cranking', text: 'Engine cranking at all?', options: ['Yes', 'No']),
    _DiagQuestion(key: 'failure', text: 'How did it fail?', options: ['Suddenly', 'Gradually']),
  ],
  'Overheating': [
    _DiagQuestion(key: 'warning', text: 'Temperature warning light on?', options: ['Yes', 'No']),
    _DiagQuestion(key: 'steam', text: 'Steam or smoke visible?', options: ['Yes', 'No']),
    _DiagQuestion(key: 'coolant', text: 'Coolant recently checked?', options: ['Yes', 'No']),
    _DiagQuestion(key: 'when', text: 'When does it happen?', options: ['While driving', 'When idle', 'Both']),
  ],
  'Strange sound': [
    _DiagQuestion(key: 'when', text: 'When does it happen?', options: ['Accelerating', 'Braking', 'Turning', 'Always']),
    _DiagQuestion(key: 'type', text: 'Type of sound?', options: ['Knocking', 'Grinding', 'Squeaking', 'Rattling']),
    _DiagQuestion(key: 'location', text: 'Where does it seem to come from?', options: ['Engine', 'Wheels', 'Brakes', 'Interior']),
  ],
  'Smoke': [
    _DiagQuestion(key: 'color', text: 'Smoke color?', options: ['White', 'Blue', 'Black', 'Grey']),
    _DiagQuestion(key: 'source', text: 'Where is it coming from?', options: ['Engine bay', 'Exhaust', 'Inside cabin']),
    _DiagQuestion(key: 'smell', text: 'Any burning smell?', options: ['Yes', 'No']),
  ],
  'Brake issue': [
    _DiagQuestion(key: 'type', text: 'Type of issue?', options: ['Squeaking', 'Grinding', 'Soft pedal', 'Pulling to side']),
    _DiagQuestion(key: 'light', text: 'Brake warning light on?', options: ['Yes', 'No']),
    _DiagQuestion(key: 'when', text: 'When does it happen?', options: ['Light braking', 'Hard braking', 'Always']),
  ],
  'Electrical issue': [
    _DiagQuestion(key: 'what', text: "What is not working?", options: ['Lights', 'Battery', 'Starter', 'Dashboard', 'AC']),
    _DiagQuestion(key: 'warning', text: 'Warning lights on dashboard?', options: ['Yes', 'No']),
    _DiagQuestion(key: 'when', text: 'When did it start?', options: ['Suddenly', 'Gradually', 'After rain/wash']),
  ],
  'Steering issue': [
    _DiagQuestion(key: 'type', text: 'Type of issue?', options: ['Heavy / stiff', 'Pulling to side', 'Vibrating', 'Noisy']),
    _DiagQuestion(key: 'speed', text: 'At what speed?', options: ['All speeds', 'High speed', 'Low speed / parking']),
    _DiagQuestion(key: 'when', text: 'When turning?', options: ['Always', 'Full lock only', 'One specific direction']),
  ],
};

// ── Main flow widget ───────────────────────────────────────────────────────────

class RequestCreationFlow extends ConsumerStatefulWidget {
  const RequestCreationFlow({
    super.key,
    this.initialStep = 0,
    this.preselectedType,
    this.preselectedVehicleId,
  });

  final int initialStep;
  final String? preselectedType;   // 'service' | 'repair'
  final String? preselectedVehicleId;

  @override
  ConsumerState<RequestCreationFlow> createState() => _RequestCreationFlowState();
}

class _RequestCreationFlowState extends ConsumerState<RequestCreationFlow> {
  static const int _totalSteps = 6; // 0–5

  late int _step;
  String? _requestType;
  Vehicle? _selectedVehicle;

  // ── Service path state ──────────────────────────────────────────────────────
  String? _serviceCategory;
  String? _specificService;
  String? _schedule;
  DateTime? _scheduledDateTime;
  final _serviceNotesCtrl = TextEditingController();

  // ── Repair path state ───────────────────────────────────────────────────────
  String? _mainProblem;
  final Map<String, String> _diagAnswers = {};
  final _repairNotesCtrl = TextEditingController();

  // ── Inline vehicle add form ─────────────────────────────────────────────────
  bool _showVehicleForm = false;
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String _fuelType = 'Petrol';
  bool _vehicleFormValid = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _requestType = widget.preselectedType;

    if (widget.preselectedVehicleId != null) {
      final vehicles = ref.read(vehicleProvider);
      try {
        _selectedVehicle = vehicles.firstWhere((v) => v.id == widget.preselectedVehicleId);
      } catch (_) {}
    }

    _makeCtrl.addListener(_revalidateForm);
    _modelCtrl.addListener(_revalidateForm);
    _yearCtrl.addListener(_revalidateForm);
  }

  void _revalidateForm() {
    final valid = _makeCtrl.text.trim().isNotEmpty &&
        _modelCtrl.text.trim().isNotEmpty &&
        _yearCtrl.text.trim().isNotEmpty;
    if (valid != _vehicleFormValid) setState(() => _vehicleFormValid = valid);
  }

  @override
  void dispose() {
    _serviceNotesCtrl.dispose();
    _repairNotesCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
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
        return _requestType == 'service' ? _serviceCategory != null : _mainProblem != null;
      case 3:
        if (_requestType == 'service') return _specificService != null;
        // Repair: if "Other issue" selected, no diag questions — always continuable
        if (_mainProblem == 'Other issue') return true;
        return _diagAnswers.isNotEmpty;
      case 4:
        return _requestType == 'service' ? _schedule != null : true;
      case 5:
        return true;
      default:
        return false;
    }
  }

  void _goNext() {
    if (_showVehicleForm) return; // must save form first
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_showVehicleForm) {
      setState(() => _showVehicleForm = false);
      return;
    }
    if (_step > widget.initialStep) {
      // When going back from specific service, clear it
      if (_step == 3 && _requestType == 'service') {
        setState(() {
          _specificService = null;
          _step--;
        });
        return;
      }
      // When going back from category/problem, clear downstream
      if (_step == 2) {
        setState(() {
          _serviceCategory = null;
          _specificService = null;
          _mainProblem = null;
          _diagAnswers.clear();
          _step--;
        });
        return;
      }
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _saveVehicle() {
    final make = _makeCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final year = int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year;
    if (make.isEmpty || model.isEmpty) return;

    final vehicle = Vehicle(
      id: 'v_${DateTime.now().millisecondsSinceEpoch}',
      brand: make,
      model: model,
      year: year,
      fuelType: _fuelType,
      transmission: 'Auto',
      bodyType: 'Sedan',
    );

    ref.read(vehicleProvider.notifier).addVehicle(vehicle);
    setState(() {
      _selectedVehicle = vehicle;
      _showVehicleForm = false;
      _makeCtrl.clear();
      _modelCtrl.clear();
      _yearCtrl.clear();
    });
  }

  // ── Submission ──────────────────────────────────────────────────────────────

  void _submit() {
    String description;
    String? manualCategory;

    if (_requestType == 'service') {
      final parts = <String>[
        'Service Request: ${_specificService ?? _serviceCategory ?? 'General service'}',
        if (_schedule != null) 'Schedule: $_schedule',
        if (_scheduledDateTime != null)
          'Preferred date: ${_scheduledDateTime!.day}/${_scheduledDateTime!.month}/${_scheduledDateTime!.year}',
        if (_serviceNotesCtrl.text.trim().isNotEmpty) _serviceNotesCtrl.text.trim(),
      ];
      description = parts.join('. ');
      manualCategory = _serviceCategoryToJob(_serviceCategory ?? '');
    } else {
      final diagLines = _diagAnswers.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      final parts = <String>[
        'Main issue: ${_mainProblem ?? 'Unknown'}',
        if (diagLines.isNotEmpty) diagLines,
        if (_repairNotesCtrl.text.trim().isNotEmpty) _repairNotesCtrl.text.trim(),
      ];
      description = parts.join('. ');
      manualCategory = _problemToJob(_mainProblem ?? '');
    }

    Navigator.of(context).pop();

    ref.read(jobProvider.notifier).submitRequest(
          description: description,
          carType: _selectedVehicle?.displayName ?? 'Unknown vehicle',
          location: 'Nairobi, Kenya',
          manualCategory: manualCategory,
        );
  }

  String _serviceCategoryToJob(String cat) {
    switch (cat) {
      case 'Engine Service': return 'Engine';
      case 'Brake Service': return 'Brake';
      case 'Tire Service': return 'Tire';
      case 'Electrical Service': return 'Electrical';
      case 'Full Inspection': return 'Diagnostics';
      default: return 'General';
    }
  }

  String _problemToJob(String p) {
    switch (p) {
      case "Won't start": return 'Engine';
      case 'Overheating': return 'Engine';
      case 'Strange sound': return 'Engine';
      case 'Smoke': return 'Engine';
      case 'Brake issue': return 'Brake';
      case 'Electrical issue': return 'Electrical';
      case 'Steering issue': return 'Suspension';
      default: return 'General';
    }
  }

  // ── Titles ──────────────────────────────────────────────────────────────────

  String get _stepTitle {
    switch (_step) {
      case 0: return 'What do you need?';
      case 1: return 'Which vehicle?';
      case 2:
        return _requestType == 'service' ? 'What type of service?' : "What's the main issue?";
      case 3:
        return _requestType == 'service' ? 'Which service specifically?' : 'Tell us more';
      case 4:
        return _requestType == 'service' ? 'When do you need it?' : 'Add photos or video';
      case 5: return 'Any extra details?';
      default: return '';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0: return 'Helps us match you with the right mechanic.';
      case 1: return 'Select the vehicle that needs attention.';
      case 2:
        return _requestType == 'service'
            ? 'Pick the service area.'
            : 'Choose the closest description.';
      case 3:
        return _requestType == 'service'
            ? 'Select the exact service you need.'
            : 'Answer what you can — it helps the mechanic prepare.';
      case 4:
        return _requestType == 'service'
            ? 'When should the mechanic arrive?'
            : 'Optional — photos speed up diagnosis.';
      case 5: return 'Optional — anything the mechanic should know?';
      default: return '';
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dotsTotal = _totalSteps - widget.initialStep;
    final dotsCurrent = _step - widget.initialStep;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            (_step == widget.initialStep && !_showVehicleForm)
                ? Icons.close_rounded
                : Icons.arrow_back_rounded,
            color: AppColors.textDark,
          ),
          onPressed: _goBack,
        ),
        title: _StepDots(current: dotsCurrent, total: dotsTotal),
      ),
      body: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey('$_step-$_showVehicleForm'),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    if (!_showVehicleForm) ...[
                      Text(
                        _stepTitle,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stepSubtitle,
                        style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
                      ),
                      const SizedBox(height: 22),
                    ],
                    _buildStep(),
                  ],
                ),
              ),
            ),
          ),
          if (!_showVehicleForm)
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
    if (_showVehicleForm) return _buildInlineVehicleForm();

    switch (_step) {
      case 0: return _buildTypeStep();
      case 1: return _buildVehicleStep();
      case 2:
        return _requestType == 'service'
            ? _buildServiceCategoryStep()
            : _buildMainProblemStep();
      case 3:
        return _requestType == 'service'
            ? _buildSpecificServiceStep()
            : _buildDiagnosticStep();
      case 4:
        return _requestType == 'service' ? _buildScheduleStep() : _buildMediaStep();
      case 5: return _buildNotesStep();
      default: return const SizedBox();
    }
  }

  // ── Step 0: Type selection ──────────────────────────────────────────────────

  Widget _buildTypeStep() {
    return Column(
      children: [
        _TypeCard(
          title: 'Service Request',
          subtitle: 'Scheduled maintenance & routine care',
          examples: const ['Oil change', 'Brake service', 'Tire rotation', 'Inspection'],
          icon: Icons.build_circle_outlined,
          color: AppColors.success,
          selected: _requestType == 'service',
          onTap: () {
            setState(() {
              _requestType = 'service';
              _mainProblem = null;
              _diagAnswers.clear();
            });
            Future.delayed(const Duration(milliseconds: 230), () {
              if (mounted && _step == 0) setState(() => _step = 1);
            });
          },
        ),
        const SizedBox(height: 14),
        _TypeCard(
          title: 'Repair / Problem',
          subtitle: "Something's wrong — get it diagnosed",
          examples: const ["Won't start", 'Overheating', 'Strange noise', 'Brake issue'],
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          selected: _requestType == 'repair',
          onTap: () {
            setState(() {
              _requestType = 'repair';
              _serviceCategory = null;
              _specificService = null;
              _schedule = null;
            });
            Future.delayed(const Duration(milliseconds: 230), () {
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
        if (vehicles.isEmpty)
          _EmptyVehiclePrompt(onAdd: () => setState(() => _showVehicleForm = true))
        else ...[
          ...vehicles.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VehicleCard(
                  vehicle: v,
                  selected: _selectedVehicle?.id == v.id,
                  onTap: () => setState(() => _selectedVehicle = v),
                ),
              )),
          _AddVehicleButton(onTap: () => setState(() => _showVehicleForm = true)),
        ],
      ],
    );
  }

  // ── Inline vehicle add form ─────────────────────────────────────────────────

  Widget _buildInlineVehicleForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Your Vehicle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                Text(
                  'Quick setup — takes 30 seconds',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        _FormField(label: 'Make', hint: 'e.g. Toyota, Nissan, Honda', controller: _makeCtrl),
        const SizedBox(height: 14),
        _FormField(label: 'Model', hint: 'e.g. Corolla, X-Trail, Civic', controller: _modelCtrl),
        const SizedBox(height: 14),
        _FormField(
          label: 'Year',
          hint: 'e.g. 2018',
          controller: _yearCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        ),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fuel Type',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Row(
              children: Vehicle.fuelTypes.map((ft) {
                final selected = _fuelType == ft;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _fuelType = ft),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primarySurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.divider,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        ft,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? AppColors.primary : AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _vehicleFormValid ? _saveVehicle : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Save Vehicle & Continue'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => setState(() => _showVehicleForm = false),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  // ── Step 2 (Service): Service category ─────────────────────────────────────

  Widget _buildServiceCategoryStep() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemCount: _serviceCategories.length,
          itemBuilder: (_, i) {
            final cat = _serviceCategories[i];
            final selected = _serviceCategory == cat.name;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _serviceCategory = cat.name;
                  _specificService = null;
                });
                Future.delayed(const Duration(milliseconds: 220), () {
                  if (mounted && _step == 2) setState(() => _step = 3);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? cat.color.withValues(alpha: 0.07) : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? cat.color : AppColors.divider,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? cat.color : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cat.description,
                      style: const TextStyle(fontSize: 10, color: AppColors.textGrey, height: 1.3),
                    ),
                    if (selected) ...[
                      const SizedBox(height: 4),
                      Icon(Icons.check_circle_rounded, color: cat.color, size: 14),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Step 3 (Service): Specific service ─────────────────────────────────────

  Widget _buildSpecificServiceStep() {
    final cat = _serviceCategories.firstWhere(
      (c) => c.name == _serviceCategory,
      orElse: () => _serviceCategories.last,
    );

    return Column(
      children: [
        // Category breadcrumb
        _BreadcrumbChip(
          label: cat.name,
          icon: cat.icon,
          color: cat.color,
          onTap: () => setState(() {
            _serviceCategory = null;
            _specificService = null;
            _step = 2;
          }),
        ),
        const SizedBox(height: 16),
        ...cat.services.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SelectableListTile(
                label: s,
                selected: _specificService == s,
                color: cat.color,
                onTap: () {
                  setState(() => _specificService = s);
                  Future.delayed(const Duration(milliseconds: 220), () {
                    if (mounted && _step == 3) setState(() => _step = 4);
                  });
                },
              ),
            )),
      ],
    );
  }

  // ── Step 2 (Repair): Main problem ───────────────────────────────────────────

  Widget _buildMainProblemStep() {
    return Column(
      children: _repairProblems.map((p) {
        final selected = _mainProblem == p.name;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _mainProblem = p.name;
                _diagAnswers.clear();
              });
              Future.delayed(const Duration(milliseconds: 220), () {
                if (mounted && _step == 2) setState(() => _step = 3);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? p.color.withValues(alpha: 0.06) : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? p.color : AppColors.divider,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(p.icon, color: p.color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: selected ? p.color : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.subtitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, color: p.color, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 3 (Repair): Diagnostic questions ───────────────────────────────────

  Widget _buildDiagnosticStep() {
    final questions = _diagData[_mainProblem] ?? [];
    final problem = _repairProblems.firstWhere(
      (p) => p.name == _mainProblem,
      orElse: () => _repairProblems.last,
    );

    if (questions.isEmpty) {
      return Column(
        children: [
          _BreadcrumbChip(
            label: _mainProblem ?? '',
            icon: problem.icon,
            color: problem.color,
            onTap: () => setState(() {
              _mainProblem = null;
              _diagAnswers.clear();
              _step = 2;
            }),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Column(
              children: [
                Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 32),
                SizedBox(height: 10),
                Text(
                  'Describe the issue in the notes',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap Continue to add details on the next screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BreadcrumbChip(
          label: _mainProblem ?? '',
          icon: problem.icon,
          color: problem.color,
          onTap: () => setState(() {
            _mainProblem = null;
            _diagAnswers.clear();
            _step = 2;
          }),
        ),
        const SizedBox(height: 18),
        ...questions.map((q) {
          final answered = _diagAnswers[q.key];
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _DiagQuestionCard(
              question: q,
              selected: answered,
              onSelect: (val) => setState(() => _diagAnswers[q.key] = val),
            ),
          );
        }),
        if (_diagAnswers.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Answer at least one question to continue.',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Step 4 (Service): Schedule ──────────────────────────────────────────────

  Widget _buildScheduleStep() {
    return Column(
      children: [
        _ScheduleCard(
          title: 'Immediate',
          subtitle: 'I need help right now',
          icon: Icons.flash_on_rounded,
          color: AppColors.error,
          selected: _schedule == 'Immediate',
          onTap: () {
            setState(() {
              _schedule = 'Immediate';
              _scheduledDateTime = null;
            });
            Future.delayed(const Duration(milliseconds: 220), () {
              if (mounted && _step == 4) setState(() => _step = 5);
            });
          },
        ),
        const SizedBox(height: 12),
        _ScheduleCard(
          title: 'Today',
          subtitle: 'Anytime today works for me',
          icon: Icons.today_rounded,
          color: AppColors.warning,
          selected: _schedule == 'Today',
          onTap: () {
            setState(() {
              _schedule = 'Today';
              _scheduledDateTime = null;
            });
            Future.delayed(const Duration(milliseconds: 220), () {
              if (mounted && _step == 4) setState(() => _step = 5);
            });
          },
        ),
        const SizedBox(height: 12),
        _ScheduleDateCard(
          selected: _schedule == 'Scheduled',
          selectedDate: _scheduledDateTime,
          onTap: () async {
            final now = DateTime.now();
            final date = await showDatePicker(
              context: context,
              initialDate: now.add(const Duration(days: 1)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 30)),
            );
            if (date == null || !mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: const TimeOfDay(hour: 9, minute: 0),
            );
            if (!mounted) return;
            final dt = time == null
                ? date
                : DateTime(date.year, date.month, date.day, time.hour, time.minute);
            setState(() {
              _schedule = 'Scheduled';
              _scheduledDateTime = dt;
            });
          },
        ),
      ],
    );
  }

  // ── Step 4 (Repair): Media ──────────────────────────────────────────────────

  Widget _buildMediaStep() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MediaButton(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                subtitle: 'Take a photo now',
                color: AppColors.primary,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Camera upload — coming soon. Use notes to describe.'),
                    duration: Duration(seconds: 3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MediaButton(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                subtitle: 'Choose from photos',
                color: const Color(0xFF6366F1),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo library — coming soon. Use notes to describe.'),
                    duration: Duration(seconds: 3),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.success, size: 16),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Photos help the mechanic arrive prepared — saving you time and money.',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('or skip for now', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
      ],
    );
  }

  // ── Step 5: Notes ───────────────────────────────────────────────────────────

  Widget _buildNotesStep() {
    final ctrl = _requestType == 'service' ? _serviceNotesCtrl : _repairNotesCtrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card
        _SummaryCard(
          vehicle: _selectedVehicle,
          type: _requestType,
          serviceName: _requestType == 'service'
              ? (_specificService ?? _serviceCategory)
              : _mainProblem,
          schedule: _schedule,
          diagCount: _diagAnswers.length,
        ),
        const SizedBox(height: 22),
        TextField(
          controller: ctrl,
          maxLines: 5,
          maxLength: 400,
          decoration: InputDecoration(
            hintText: _requestType == 'service'
                ? 'e.g. Only use genuine Toyota oil. Car is at the gate.'
                : "e.g. It started after I drove through a flooded road. The sound gets louder when turning right.",
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
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
            contentPadding: const EdgeInsets.all(14),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.5),
        ),
      ],
    );
  }
}

// ── Reusable sub-widgets ───────────────────────────────────────────────────────

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
          width: i == current ? 22 : 6,
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.isLastStep, required this.enabled, required this.onTap});
  final bool isLastStep;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(isLastStep ? 'Find Mechanic' : 'Continue'),
        ),
      ),
    );
  }
}

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
          border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const SizedBox(height: 1),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: color, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: examples.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.selected, required this.onTap});
  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_car_rounded,
                  color: selected ? AppColors.primary : AppColors.textGrey, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.displayName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(vehicle.subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

class _EmptyVehiclePrompt extends StatelessWidget {
  const _EmptyVehiclePrompt({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                child: const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 14),
              const Text('No vehicles yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text('Add your vehicle to get started', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _AddVehicleButton(onTap: onAdd),
      ],
    );
  }
}

class _AddVehicleButton extends StatelessWidget {
  const _AddVehicleButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Add a Vehicle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
  });
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
      ],
    );
  }
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(width: 6),
            Icon(Icons.close_rounded, color: color.withValues(alpha: 0.6), size: 14),
          ],
        ),
      ),
    );
  }
}

class _SelectableListTile extends StatelessWidget {
  const _SelectableListTile({
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
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : AppColors.textDark,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DiagQuestionCard extends StatelessWidget {
  const _DiagQuestionCard({
    required this.question,
    required this.selected,
    required this.onSelect,
  });
  final _DiagQuestion question;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final answered = selected != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: answered ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
          width: answered ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (answered)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 14)
              else
                const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textGrey, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  question.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: answered ? AppColors.textDark : AppColors.textGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: question.options.map((opt) {
              final isSelected = selected == opt;
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primarySurface : AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ScheduleDateCard extends StatelessWidget {
  const _ScheduleDateCard({
    required this.selected,
    required this.selectedDate,
    required this.onTap,
  });
  final bool selected;
  final DateTime? selectedDate;
  final VoidCallback onTap;

  String get _dateLabel {
    if (selectedDate == null) return 'Pick a date & time';
    final d = selectedDate!;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} · $hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule for later',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dateLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? AppColors.primary : AppColors.textGrey,
                      fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: selected ? AppColors.primary : AppColors.textGrey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  const _MediaButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.vehicle,
    required this.type,
    required this.serviceName,
    required this.schedule,
    required this.diagCount,
  });
  final Vehicle? vehicle;
  final String? type;
  final String? serviceName;
  final String? schedule;
  final int diagCount;

  @override
  Widget build(BuildContext context) {
    final isService = type == 'service';
    final typeColor = isService ? AppColors.success : AppColors.error;
    final typeLabel = isService ? 'Service Request' : 'Repair Request';
    final typeIcon = isService ? Icons.build_circle_outlined : Icons.warning_amber_rounded;

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
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textGrey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          if (vehicle != null) _SummaryRow(
            icon: Icons.directions_car_rounded, color: AppColors.primary, text: vehicle!.displayName),
          const SizedBox(height: 8),
          _SummaryRow(icon: typeIcon, color: typeColor, text: typeLabel),
          if (serviceName != null) ...[
            const SizedBox(height: 8),
            _SummaryRow(icon: Icons.label_outline_rounded, color: typeColor, text: serviceName!),
          ],
          if (schedule != null) ...[
            const SizedBox(height: 8),
            _SummaryRow(icon: Icons.schedule_rounded, color: AppColors.primary, text: schedule!),
          ],
          if (!isService && diagCount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.quiz_outlined,
              color: const Color(0xFF6366F1),
              text: '$diagCount diagnostic answer${diagCount == 1 ? '' : 's'} recorded',
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4)),
        ),
      ],
    );
  }
}
