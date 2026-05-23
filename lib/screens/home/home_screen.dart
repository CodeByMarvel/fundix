import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_notifier.dart';
import '../../providers/vehicle_provider.dart';
import '../../models/job_status.dart';
import '../../models/vehicle.dart';
import '../request_flow/request_creation_flow.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(jobProvider);
    final vehicles = ref.watch(vehicleProvider);
    final user = ref.watch(authProvider).user;
    final selectedId = ref.watch(selectedVehicleIdProvider);
    final selectedVehicle = vehicles.isEmpty
        ? null
        : vehicles.firstWhere((v) => v.id == selectedId,
            orElse: () => vehicles.first);
    final activeVehicleId = jobState.activeVehicleId;
    final singleCarBlocked = jobState.hasActiveJob && vehicles.length == 1;
    final firstName = (user?.name ?? '').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            // ── Header ──────────────────────────────────────────────────────
            _Header(greeting: _greeting(), firstName: firstName),
            const SizedBox(height: 16),

            // ── Vehicle card ─────────────────────────────────────────────────
            if (vehicles.isEmpty)
              _AddVehiclePrompt(onTap: () => openRequestFlow(context))
            else
              _VehicleCard(
                vehicle: selectedVehicle!,
                onTap: () => showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => _VehicleSwitcherSheet(
                    vehicles: vehicles,
                    selectedId: selectedId,
                    activeVehicleId: activeVehicleId,
                    onSelect: (id) =>
                        ref.read(selectedVehicleIdProvider.notifier).state = id,
                    onAddVehicle: () => openRequestFlow(context),
                  ),
                ),
              ),
            const SizedBox(height: 14),

            // ── Active job banner ────────────────────────────────────────────
            if (jobState.hasActiveJob) ...[
              _ActiveJobBanner(status: jobState.customerStatus),
              const SizedBox(height: 14),
            ],

            // ── Action cards ─────────────────────────────────────────────────
            const _SectionLabel('Quick actions'),
            const SizedBox(height: 10),

            if (singleCarBlocked)
              _BlockedCard()
            else ...[
              // Emergency SOS
              _EmergencyCard(
                onTap: () => openRequestFlow(
                  context,
                  preselectedUrgency: 'emergency',
                  preselectedVehicleId: selectedVehicle?.id,
                ),
              ),
              const SizedBox(height: 10),

              // Fix + Service (2-column)
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: 'Fix an Issue',
                      subtitle: "Something's wrong with your vehicle",
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.error,
                      onTap: () => openRequestFlow(
                        context,
                        preselectedUrgency: 'today',
                        preselectedType: 'repair',
                        preselectedVehicleId: selectedVehicle?.id,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionCard(
                      title: 'Service My Car',
                      subtitle: 'Routine maintenance & inspections',
                      icon: Icons.build_circle_outlined,
                      color: AppColors.success,
                      onTap: () => openRequestFlow(
                        context,
                        preselectedUrgency: 'today',
                        preselectedType: 'service',
                        preselectedVehicleId: selectedVehicle?.id,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Schedule for later
              _ScheduleCard(
                onTap: () => openRequestFlow(
                  context,
                  preselectedUrgency: 'scheduled',
                  preselectedVehicleId: selectedVehicle?.id,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Recent requests ──────────────────────────────────────────────
            const _SectionLabel('Recent requests'),
            const SizedBox(height: 10),
            const _RecentPlaceholder(),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.firstName});
  final String greeting;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FUNDI-X',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(text: greeting),
                    if (firstName.isNotEmpty) ...[
                      const TextSpan(text: ', '),
                      TextSpan(
                        text: firstName,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.textGrey, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Vehicle card ──────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onTap});
  final Vehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: const BoxDecoration(
                  color: AppColors.primarySurface, shape: BoxShape.circle),
              child: const Icon(Icons.directions_car_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active vehicle',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 1),
                  Text(vehicle.displayName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Switch',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  SizedBox(width: 3),
                  Icon(Icons.swap_horiz_rounded,
                      size: 13, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add vehicle prompt ────────────────────────────────────────────────────────

class _AddVehiclePrompt extends StatelessWidget {
  const _AddVehiclePrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add your vehicle',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                  SizedBox(height: 1),
                  Text('Required to request a mechanic',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Active job banner ─────────────────────────────────────────────────────────

class _ActiveJobBanner extends StatelessWidget {
  const _ActiveJobBanner({required this.status});
  final CustomerRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.displayLabel,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ),
          const Text('View',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.primary, size: 16),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.textLight,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Emergency SOS card ────────────────────────────────────────────────────────

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency SOS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Broken down? Get a mechanic dispatched to you right now.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── 2-column action card ──────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.2),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textGrey, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Schedule card ─────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule a Service',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        letterSpacing: -0.2),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Book a garage appointment for a specific date',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textGrey, height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Blocked card ──────────────────────────────────────────────────────────────

class _BlockedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.build_circle_outlined,
                color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehicle currently in service',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                SizedBox(height: 4),
                Text(
                  'New requests are unavailable while your car is being serviced. Add another vehicle or wait until the current job is done.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textGrey, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vehicle switcher bottom sheet ─────────────────────────────────────────────

class _VehicleSwitcherSheet extends StatelessWidget {
  const _VehicleSwitcherSheet({
    required this.vehicles,
    required this.selectedId,
    required this.onSelect,
    required this.onAddVehicle,
    this.activeVehicleId,
  });

  final List<Vehicle> vehicles;
  final String? selectedId;
  final String? activeVehicleId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddVehicle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Switch Vehicle',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 16),
          ...vehicles.map((v) {
            final inService = v.id == activeVehicleId;
            final isSelected = v.id == selectedId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: inService
                    ? null
                    : () {
                        onSelect(v.id);
                        Navigator.pop(context);
                      },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: inService
                        ? AppColors.background
                        : (isSelected
                            ? AppColors.primarySurface
                            : AppColors.surface),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: inService
                          ? AppColors.divider
                          : (isSelected
                              ? AppColors.primary
                              : AppColors.divider),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car_rounded,
                          color: inService
                              ? AppColors.textGrey
                              : (isSelected
                                  ? AppColors.primary
                                  : AppColors.textGrey),
                          size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.displayName,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: inService
                                        ? AppColors.textGrey
                                        : AppColors.textDark)),
                            const SizedBox(height: 2),
                            Text(
                              inService ? 'Currently in service' : v.subtitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: inService
                                      ? AppColors.warning
                                      : AppColors.textGrey,
                                  fontWeight: inService
                                      ? FontWeight.w500
                                      : FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      if (inService)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('In service',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning)),
                        )
                      else if (isSelected)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onAddVehicle();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 12),
                  Text('Add New Vehicle',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent requests placeholder ───────────────────────────────────────────────

class _RecentPlaceholder extends StatelessWidget {
  const _RecentPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, size: 32, color: AppColors.textLight),
          SizedBox(height: 8),
          Text('No recent requests',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey)),
          SizedBox(height: 3),
          Text('Your service history will appear here',
              style: TextStyle(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
