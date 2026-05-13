import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/job_notifier.dart';
import '../../../providers/mechanic_availability_provider.dart';
import '../../../models/job_status.dart';
import '../../../models/job.dart';

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobProvider);
    final isOnline = ref.watch(mechanicIsOnlineProvider);

    // Auto-switch to Active tab when job moves past acceptance
    ref.listen<JobState>(jobProvider, (previous, next) {
      if (next.mechanicJobStatus != MechanicJobStatus.idle &&
          next.mechanicJobStatus != MechanicJobStatus.received) {
        _tabController.animateTo(1);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jobs'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textGrey,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: 'Incoming'),
                  Tab(text: 'Active'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IncomingTab(jobState: jobState, isOnline: isOnline),
          _ActiveTab(jobState: jobState),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Incoming tab
// ─────────────────────────────────────────────────────────────────────────────

class _IncomingTab extends ConsumerWidget {
  const _IncomingTab({required this.jobState, required this.isOnline});
  final JobState jobState;
  final bool isOnline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isOnline) {
      return const _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'You\'re offline',
        subtitle: 'Go Online from your Dashboard to receive job requests.',
      );
    }

    if (jobState.mechanicJobStatus == MechanicJobStatus.received &&
        jobState.activeJob != null) {
      return _IncomingJobCard(
        job: jobState.activeJob!,
        onAccept: () => ref.read(jobProvider.notifier).mechanicAcceptsJob(),
        onDecline: () => ref.read(jobProvider.notifier).cancelRequest(),
      );
    }

    return const _EmptyState(
      icon: Icons.inbox_rounded,
      title: 'No incoming requests',
      subtitle: 'You\'re online — new requests will appear here instantly.',
    );
  }
}

class _IncomingJobCard extends StatelessWidget {
  const _IncomingJobCard({
    required this.job,
    required this.onAccept,
    required this.onDecline,
  });

  final Job job;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgency header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.notifications_active_rounded,
                    color: AppColors.warning, size: 16),
                SizedBox(width: 8),
                Text('New job request',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Job details card
          Container(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(job.serviceCategory,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(width: 8),
                    Text(job.carType,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(job.problemDescription,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                        height: 1.4)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(job.location,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(
                        'Min. service time: ${job.minimumServiceMinutes} min',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primarySurface,
                      child: Icon(Icons.person_rounded,
                          size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(job.customer.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark)),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Accept / Decline
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('Accept Job'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active tab — controls for each mechanic stage
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveTab extends ConsumerWidget {
  const _ActiveTab({required this.jobState});
  final JobState jobState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobState.mechanicJobStatus == MechanicJobStatus.idle ||
        jobState.mechanicJobStatus == MechanicJobStatus.received) {
      return const _EmptyState(
        icon: Icons.handyman_rounded,
        title: 'No active job',
        subtitle:
            'Accept an incoming request and it will appear here with controls.',
      );
    }

    return _ActiveJobControls(
      jobState: jobState,
      onArrived: () => ref.read(jobProvider.notifier).mechanicArrived(),
      onStartService: () =>
          ref.read(jobProvider.notifier).mechanicStartsService(),
      onSubmitProof: () =>
          ref.read(jobProvider.notifier).mechanicSubmitsWorkProof(
                note: 'Work completed successfully',
                checklistConfirmed: true,
              ),
      onEndService: () =>
          ref.read(jobProvider.notifier).mechanicEndsService(),
    );
  }
}

class _ActiveJobControls extends StatelessWidget {
  const _ActiveJobControls({
    required this.jobState,
    required this.onArrived,
    required this.onStartService,
    required this.onSubmitProof,
    required this.onEndService,
  });

  final JobState jobState;
  final VoidCallback onArrived;
  final VoidCallback onStartService;
  final VoidCallback onSubmitProof;
  final VoidCallback onEndService;

  @override
  Widget build(BuildContext context) {
    final job = jobState.activeJob;
    final status = jobState.mechanicJobStatus;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Customer info
        if (job != null) _CustomerInfoCard(job: job),
        const SizedBox(height: 16),

        // Current status
        _MechanicStatusCard(status: status),
        const SizedBox(height: 16),

        // Action button for current stage
        _stageButton(status),

        const SizedBox(height: 16),
        if (job != null) _UpdatesTimeline(updates: job.updates),
      ],
    );
  }

  Widget _stageButton(MechanicJobStatus status) {
    switch (status) {
      case MechanicJobStatus.enRoute:
        return ElevatedButton.icon(
          onPressed: onArrived,
          icon: const Icon(Icons.location_on_rounded),
          label: const Text('I\'ve Arrived'),
        );
      case MechanicJobStatus.arrived:
        return ElevatedButton.icon(
          onPressed: onStartService,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Service'),
        );
      case MechanicJobStatus.awaitingStartConfirm:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: AppColors.warning, strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Waiting for customer to confirm start…',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );
      case MechanicJobStatus.serviceActive:
        return ElevatedButton.icon(
          onPressed: onSubmitProof,
          icon: const Icon(Icons.verified_rounded),
          label: const Text('Submit Work Proof'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success),
        );
      case MechanicJobStatus.submittingWorkProof:
        return ElevatedButton.icon(
          onPressed: onEndService,
          icon: const Icon(Icons.flag_rounded),
          label: const Text('End Service'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success),
        );
      case MechanicJobStatus.awaitingCustomerConfirm:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: AppColors.success, strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Waiting for customer confirmation…',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        );
      case MechanicJobStatus.completed:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 22),
              SizedBox(width: 8),
              Text('Job completed!',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                      fontSize: 15)),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }
}

class _MechanicStatusCard extends StatelessWidget {
  const _MechanicStatusCard({required this.status});
  final MechanicJobStatus status;

  String get _label {
    switch (status) {
      case MechanicJobStatus.accepted:
      case MechanicJobStatus.enRoute:
        return 'En route to customer';
      case MechanicJobStatus.arrived:
        return 'At customer location';
      case MechanicJobStatus.awaitingStartConfirm:
        return 'Start requested';
      case MechanicJobStatus.serviceActive:
        return 'Service active';
      case MechanicJobStatus.submittingWorkProof:
        return 'Work proof submitted';
      case MechanicJobStatus.awaitingCustomerConfirm:
        return 'Awaiting customer confirmation';
      case MechanicJobStatus.completed:
        return 'Completed';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(_label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard({required this.job});
  final Job job;

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
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySurface,
                child: Icon(Icons.person_rounded,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.customer.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    Text(job.location,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(job.serviceCategory,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(job.problemDescription,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  height: 1.4)),
        ],
      ),
    );
  }
}

class _UpdatesTimeline extends StatelessWidget {
  const _UpdatesTimeline({required this.updates});
  final List<JobUpdate> updates;

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        ...updates.reversed.take(5).map(
              (u) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5, right: 8),
                      child: CircleAvatar(
                          radius: 3,
                          backgroundColor: AppColors.primary),
                    ),
                    Expanded(
                      child: Text(u.message,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey)),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                  color: AppColors.primarySurface, shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}
