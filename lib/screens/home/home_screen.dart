import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/job_notifier.dart';
import '../../providers/vehicle_provider.dart';
import '../../models/job_status.dart';
import '../../models/vehicle.dart';
import '../request_flow/request_creation_flow.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(jobProvider);
    final vehicles = ref.watch(vehicleProvider);
    final selectedId = ref.watch(selectedVehicleIdProvider);
    final selectedVehicle = vehicles.isEmpty
        ? null
        : vehicles.firstWhere(
            (v) => v.id == selectedId,
            orElse: () => vehicles.first,
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          children: [
            // ── Greeting row ───────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning,',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w400),
                    ),
                    Text(
                      'Marvel',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySurface,
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.primary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Vehicle selector ────────────────────────────────────────────
            if (selectedVehicle != null)
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => _VehicleSwitcherSheet(
                    vehicles: vehicles,
                    selectedId: selectedId,
                    onSelect: (id) =>
                        ref.read(selectedVehicleIdProvider.notifier).state = id,
                    onAddVehicle: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Adding vehicles coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    ),
                  ),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          color: AppColors.primarySurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_car_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your vehicle',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                  letterSpacing: 0.3),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              selectedVehicle.displayName,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Switch',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.swap_horiz_rounded,
                                size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // ── Active job banner ───────────────────────────────────────────
            if (jobState.hasActiveJob) ...[
              _ActiveRequestBanner(status: jobState.customerStatus),
              const SizedBox(height: 20),
            ],

            // ── Service type heading ────────────────────────────────────────
            const Text(
              'What do you need?',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.3),
            ),
            const SizedBox(height: 14),

            // ── Repair card ─────────────────────────────────────────────────
            _ServiceTypeCard(
              title: 'Repair Issue',
              subtitle: "Something's wrong with your vehicle",
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              onTap: () => openRequestFlow(
                context,
                preselectedType: 'repair',
                preselectedVehicleId: selectedVehicle?.id,
              ),
            ),
            const SizedBox(height: 12),

            // ── Routine card ────────────────────────────────────────────────
            _ServiceTypeCard(
              title: 'Routine Service',
              subtitle: 'Scheduled maintenance & inspections',
              icon: Icons.build_circle_outlined,
              color: AppColors.success,
              onTap: () => openRequestFlow(
                context,
                preselectedType: 'routine',
                preselectedVehicleId: selectedVehicle?.id,
              ),
            ),
            const SizedBox(height: 28),

            // ── Recent requests ─────────────────────────────────────────────
            const Text(
              'Recent Requests',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.2),
            ),
            const SizedBox(height: 12),
            const _RecentPlaceholder(),
          ],
        ),
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
  });

  final List<Vehicle> vehicles;
  final String? selectedId;
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
          const Text(
            'Switch Vehicle',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          ...vehicles.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    onSelect(v.id);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: v.id == selectedId
                          ? AppColors.primarySurface
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: v.id == selectedId
                            ? AppColors.primary
                            : AppColors.divider,
                        width: v.id == selectedId ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_rounded,
                          color: v.id == selectedId
                              ? AppColors.primary
                              : AppColors.textGrey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.displayName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                v.subtitle,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                        if (v.id == selectedId)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              )),
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
                  Text(
                    'Add New Vehicle',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active job banner ─────────────────────────────────────────────────────────

class _ActiveRequestBanner extends StatelessWidget {
  const _ActiveRequestBanner({required this.status});
  final CustomerRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
}

// ── Service type card ─────────────────────────────────────────────────────────

class _ServiceTypeCard extends StatelessWidget {
  const _ServiceTypeCard({
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textGrey, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textLight),
          ],
        ),
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
          Icon(Icons.history_rounded, size: 36, color: AppColors.textLight),
          SizedBox(height: 8),
          Text(
            'No recent requests',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey),
          ),
          SizedBox(height: 4),
          Text(
            'Your service history will appear here',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
