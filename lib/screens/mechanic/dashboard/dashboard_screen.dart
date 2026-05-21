import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/mechanic_availability_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/job_notifier.dart';
import '../../../providers/earnings_provider.dart';
import '../../../models/job_status.dart';
import '../../../services/mechanic_api_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _toggling = false;

  Future<void> _handleToggle(bool goOnline) async {
    if (_toggling) return;
    setState(() => _toggling = true);

    try {
      double? lat, lng;

      if (goOnline) {
        // Ensure fresh GPS before going online
        await ref.read(locationProvider.notifier).requestLocation();
        final loc = ref.read(locationProvider);
        if (loc.hasLocation) {
          lat = loc.latitude;
          lng = loc.longitude;
        }
      }

      await MechanicApiService.setAvailability(goOnline, lat: lat, lng: lng);
      if (!mounted) return;
      ref.read(mechanicIsOnlineProvider.notifier).state = goOnline;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(mechanicIsOnlineProvider);
    final jobState = ref.watch(jobProvider);
    final hasActiveJob = jobState.mechanicJobStatus != MechanicJobStatus.idle;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySurface,
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _OnlineToggle(
            isOnline: isOnline,
            loading: _toggling,
            onToggle: _handleToggle,
          ),
          if (hasActiveJob) ...[
            const SizedBox(height: 16),
            _ActiveJobBanner(jobState: jobState),
          ],
          const SizedBox(height: 20),
          _TodayStats(isOnline: isOnline),
          const SizedBox(height: 20),
          const _RatingCard(),
          const SizedBox(height: 20),
          const _RecentActivitySection(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Online / Offline toggle
// ─────────────────────────────────────────────────────────────────────────────

class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({
    required this.isOnline,
    required this.onToggle,
    this.loading = false,
  });

  final bool isOnline;
  final ValueChanged<bool> onToggle;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
              : [const Color(0xFF6B7280), const Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.success : AppColors.textGrey)
                .withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: isOnline
                            ? [
                                BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    blurRadius: 6)
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? "You're Online" : "You're Offline",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isOnline
                      ? 'Accepting new job requests'
                      : 'Tap to start receiving jobs',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: loading ? null : () => onToggle(!isOnline),
            child: loading
                ? const SizedBox(
                    width: 64,
                    height: 34,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 64,
                    height: 34,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: isOnline
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active job banner (links to Jobs tab visually)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveJobBanner extends ConsumerWidget {
  const _ActiveJobBanner({required this.jobState});
  final JobState jobState;

  String get _label {
    switch (jobState.mechanicJobStatus) {
      case MechanicJobStatus.received:
        return 'New job request — respond now';
      case MechanicJobStatus.enRoute:
        return 'En route to customer';
      case MechanicJobStatus.inspecting:
        return 'Inspecting vehicle';
      case MechanicJobStatus.quoteReady:
        return 'Quote ready to send';
      case MechanicJobStatus.awaitingQuoteApproval:
        return 'Waiting for quote approval';
      case MechanicJobStatus.inRepair:
        return 'Repair in progress';
      case MechanicJobStatus.awaitingCustomerVerification:
        return 'Waiting for customer to verify';
      case MechanicJobStatus.disputed:
        return 'Job under review';
      default:
        return 'Active job';
    }
  }

  // Received → Incoming tab (0); any active stage → Active tab (1)
  int get _jobsSubTab =>
      jobState.mechanicJobStatus == MechanicJobStatus.received ? 0 : 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(mechanicJobsTabIndexProvider.notifier).state = _jobsSubTab;
        ref.read(mechanicShellIndexProvider.notifier).state = 1;
      },
      child: Container(
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
              child: Text(_label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
            const Text('View →',
                style: TextStyle(fontSize: 12, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's stats
// ─────────────────────────────────────────────────────────────────────────────

class _TodayStats extends ConsumerWidget {
  const _TodayStats({required this.isOnline});
  final bool isOnline;

  String _kes(double amount) {
    final n = amount.round();
    if (n >= 1000) {
      return 'KES ${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return 'KES $n';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(earningsProvider);
    final jobs = earnings.jobsToday;
    final total = earnings.totalToday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today\'s Stats',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: -0.2)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.handyman_rounded,
                label: 'Jobs Done',
                value: '$jobs',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Earned',
                value: _kes(total),
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.timer_rounded,
                label: 'Online',
                value: '0h',
                color: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.star_rounded,
                color: AppColors.warning, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Rating',
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                SizedBox(height: 2),
                Text('—',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ],
            ),
          ),
          const Text('0 reviews',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Activity',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: -0.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Center(
            child: Text('No activity yet',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
          ),
        ),
      ],
    );
  }
}
