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
      return _IncomingRequestCard(
        job: jobState.activeJob!,
        onAccept: () => ref.read(jobProvider.notifier).mechanicAcceptsJob(),
        onDecline: () => ref.read(jobProvider.notifier).mechanicRejectsJob(),
      );
    }

    return const _EmptyState(
      icon: Icons.inbox_rounded,
      title: 'Waiting for requests',
      subtitle: 'You\'re online — new job requests will appear here instantly.',
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  const _IncomingRequestCard({
    required this.job,
    required this.onAccept,
    required this.onDecline,
  });

  final Job job;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  bool get _isRepair => job.serviceCategory != 'Oil Change' &&
      job.serviceCategory != 'Tire Change' &&
      job.serviceCategory != 'Battery';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Urgency banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: AppColors.warning, size: 16),
              SizedBox(width: 8),
              Text('New job request — respond now',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Request type + category
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_isRepair ? AppColors.error : AppColors.success)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isRepair ? 'Repair' : 'Service',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isRepair
                              ? AppColors.error
                              : AppColors.success),
                    ),
                  ),
                  const Spacer(),
                  Text(job.carType,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
              const SizedBox(height: 12),

              // Customer location
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(job.location,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),

              // Problem description
              const Text('Customer Description',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text(job.problemDescription,
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Photos / Videos
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Photos / Videos',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text('Not provided by customer',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // AI possible causes (repairs only)
        if (_isRepair)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF6366F1), size: 15),
                    ),
                    const SizedBox(width: 8),
                    const Text('AI — Possible Causes',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1))),
                  ],
                ),
                const SizedBox(height: 10),
                ..._aiCauses(job.serviceCategory).map(
                  (cause) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5, right: 8),
                          child: CircleAvatar(
                              radius: 3,
                              backgroundColor: Color(0xFF6366F1)),
                        ),
                        Expanded(
                          child: Text(cause,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Customer info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primarySurface,
                child: Icon(Icons.person_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(job.customer.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 13, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text('Min ${job.minimumServiceMinutes} min',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
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
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: const Text('Accept Job'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _aiCauses(String category) {
    switch (category) {
      case 'Engine':
        return [
          'Worn spark plugs causing misfires',
          'Clogged fuel injectors reducing fuel delivery',
          'Faulty oxygen sensor affecting air-fuel ratio',
        ];
      case 'Electrical':
        return [
          'Weak or failing battery (below 12.4V)',
          'Corroded terminal connections',
          'Faulty alternator not charging battery',
        ];
      case 'Brake':
        return [
          'Worn brake pads below minimum thickness',
          'Warped rotors from heat cycles',
          'Low brake fluid or hydraulic leak',
        ];
      default:
        return [
          'Component wear from regular use',
          'Fluid leak causing system failure',
          'Sensor malfunction triggering warning light',
        ];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active tab — routes to the correct stage widget
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveTab extends ConsumerWidget {
  const _ActiveTab({required this.jobState});
  final JobState jobState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = jobState.mechanicJobStatus;

    if (status == MechanicJobStatus.idle ||
        status == MechanicJobStatus.received) {
      return const _EmptyState(
        icon: Icons.handyman_rounded,
        title: 'No active job',
        subtitle: 'Accept an incoming request and it will appear here.',
      );
    }

    final job = jobState.activeJob;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (job != null) _CustomerInfoCard(job: job),
        const SizedBox(height: 16),
        _stageWidget(context, ref, status, jobState),
        const SizedBox(height: 16),
        if (job != null && job.updates.isNotEmpty)
          _UpdatesTimeline(updates: job.updates),
      ],
    );
  }

  Widget _stageWidget(BuildContext context, WidgetRef ref,
      MechanicJobStatus status, JobState jobState) {
    final notifier = ref.read(jobProvider.notifier);

    switch (status) {
      case MechanicJobStatus.enRoute:
        return _NavigationCard(
          job: jobState.activeJob!,
          onConfirmArrival: () => notifier.mechanicArrived(),
        );

      case MechanicJobStatus.inspecting:
        return _InspectionForm(
          onSubmit: (notes, complexity) =>
              notifier.mechanicSubmitsDiagnosis(notes: notes, complexity: complexity),
        );

      case MechanicJobStatus.quoteReady:
        return _QuoteReviewCard(
          diagnosisNotes: jobState.diagnosisNotes ?? '',
          complexity: jobState.repairComplexity ?? 'moderate',
          quote: jobState.generatedQuote ?? 0,
          onSend: () => notifier.mechanicSendsQuote(),
        );

      case MechanicJobStatus.awaitingQuoteApproval:
        return _AwaitingQuoteCard(
          quote: jobState.generatedQuote ?? 0,
        );

      case MechanicJobStatus.inRepair:
        return _RepairCard(
          onComplete: () => notifier.mechanicCompletesRepair(),
        );

      case MechanicJobStatus.awaitingCustomerVerification:
        return _AwaitingVerificationCard();

      case MechanicJobStatus.disputed:
        return const _DisputedCard();

      case MechanicJobStatus.completed:
        return _CompletedCard(quote: jobState.generatedQuote ?? 0);

      default:
        return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage cards
// ─────────────────────────────────────────────────────────────────────────────

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({required this.job, required this.onConfirmArrival});
  final Job job;
  final VoidCallback onConfirmArrival;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map placeholder
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_rounded, color: AppColors.primary, size: 36),
                SizedBox(height: 8),
                Text('Route to customer',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Communication buttons
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.phone_rounded,
                label: 'Call',
                color: AppColors.success,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                color: AppColors.primary,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: onConfirmArrival,
          icon: const Icon(Icons.location_on_rounded),
          label: const Text('Confirm Arrival'),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }
}

class _InspectionForm extends ConsumerStatefulWidget {
  const _InspectionForm({required this.onSubmit});
  final void Function(String notes, String complexity) onSubmit;

  @override
  ConsumerState<_InspectionForm> createState() => _InspectionFormState();
}

class _InspectionFormState extends ConsumerState<_InspectionForm> {
  final _notesController = TextEditingController();
  String _complexity = 'moderate';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _notesController.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StageBanner(
          icon: Icons.search_rounded,
          color: AppColors.primary,
          label: 'Inspection Phase',
          subtitle: 'Examine the vehicle and document your findings.',
        ),
        const SizedBox(height: 16),

        // Diagnosis notes
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Diagnosis Notes',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'Describe the issue, root cause, and what needs to be done…',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textGrey),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Repair complexity
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Repair Complexity',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ComplexityChip(
                    label: 'Minor',
                    value: 'minor',
                    selected: _complexity == 'minor',
                    color: AppColors.success,
                    onTap: () => setState(() => _complexity = 'minor'),
                  ),
                  const SizedBox(width: 8),
                  _ComplexityChip(
                    label: 'Moderate',
                    value: 'moderate',
                    selected: _complexity == 'moderate',
                    color: AppColors.warning,
                    onTap: () => setState(() => _complexity = 'moderate'),
                  ),
                  const SizedBox(width: 8),
                  _ComplexityChip(
                    label: 'Major',
                    value: 'major',
                    selected: _complexity == 'major',
                    color: AppColors.error,
                    onTap: () => setState(() => _complexity = 'major'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Photo upload placeholder
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.divider, style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_a_photo_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload Proof Photos',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text('Optional but recommended',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Add'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: _canSubmit
              ? () => widget.onSubmit(
                  _notesController.text.trim(), _complexity)
              : null,
          style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52)),
          child: const Text('Submit Diagnosis'),
        ),
      ],
    );
  }
}

class _ComplexityChip extends StatelessWidget {
  const _ComplexityChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? color : AppColors.textGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuoteReviewCard extends StatelessWidget {
  const _QuoteReviewCard({
    required this.diagnosisNotes,
    required this.complexity,
    required this.quote,
    required this.onSend,
  });

  final String diagnosisNotes;
  final String complexity;
  final double quote;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StageBanner(
          icon: Icons.receipt_long_rounded,
          color: AppColors.warning,
          label: 'Review Quote',
          subtitle: 'Auto-generated based on diagnosis and complexity.',
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuoteRow(label: 'Complexity', value: _capitalise(complexity)),
              const SizedBox(height: 8),
              _QuoteRow(label: 'Labour', value: 'KES ${(quote * 0.6).toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              _QuoteRow(label: 'Parts (est.)', value: 'KES ${(quote * 0.4).toStringAsFixed(0)}'),
              const SizedBox(height: 10),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  Text('KES ${quote.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Diagnosis',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(diagnosisNotes,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: onSend,
          icon: const Icon(Icons.send_rounded),
          label: const Text('Send Quote to Customer'),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52)),
        ),
      ],
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark)),
      ],
    );
  }
}

class _AwaitingQuoteCard extends StatelessWidget {
  const _AwaitingQuoteCard({required this.quote});
  final double quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                color: AppColors.warning, strokeWidth: 2.5),
          ),
          const SizedBox(height: 14),
          const Text('Quote Sent to Customer',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning)),
          const SizedBox(height: 6),
          Text('KES ${quote.toStringAsFixed(0)} · Waiting for approval…',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textGrey, height: 1.4)),
        ],
      ),
    );
  }
}

class _RepairCard extends StatelessWidget {
  const _RepairCard({required this.onComplete});
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StageBanner(
          icon: Icons.build_rounded,
          color: AppColors.primary,
          label: 'Repair in Progress',
          subtitle: 'Post updates as you work. Mark complete when done.',
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_comment_outlined,
                label: 'Post Update',
                color: AppColors.primary,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.add_a_photo_outlined,
                label: 'Add Photo',
                color: AppColors.primary,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Request Revised Approval'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.warning,
            side: const BorderSide(color: AppColors.warning),
          ),
        ),
        const SizedBox(height: 10),

        ElevatedButton.icon(
          onPressed: onComplete,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Mark Repair Complete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}

class _AwaitingVerificationCard extends StatelessWidget {
  const _AwaitingVerificationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
                color: AppColors.success, strokeWidth: 2.5),
          ),
          SizedBox(height: 14),
          Text('Waiting for Customer Verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success)),
          SizedBox(height: 6),
          Text(
              'The customer is confirming the repair is complete.\nAuto-confirmed after 10 minutes if no response.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textGrey, height: 1.4)),
        ],
      ),
    );
  }
}

class _DisputedCard extends StatelessWidget {
  const _DisputedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gavel_rounded,
                color: AppColors.error, size: 26),
          ),
          const SizedBox(height: 14),
          const Text('Job Under Review',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error)),
          const SizedBox(height: 6),
          const Text(
              'The customer has disputed the repair.\nOur team is reviewing the evidence before releasing payment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textGrey, height: 1.4)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.headset_mic_rounded),
            label: const Text('Contact Support'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.quote});
  final double quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Job Completed!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success)),
          const SizedBox(height: 6),
          const Text('Payment processed · Earnings added to your wallet',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textGrey, height: 1.4)),
          if (quote > 0) ...[
            const SizedBox(height: 16),
            Text('+ KES ${quote.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StageBanner extends StatelessWidget {
  const _StageBanner({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  fontSize: 13, color: AppColors.textGrey, height: 1.4)),
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
        ...updates.reversed.take(6).map(
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
