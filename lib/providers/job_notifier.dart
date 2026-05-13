import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../models/app_user.dart';
import '../models/mechanic_offer.dart';
import '../models/auto_tagger.dart';

@immutable
class JobState {
  final CustomerRequestStatus customerStatus;
  final MechanicJobStatus mechanicJobStatus;
  final Job? activeJob;
  final List<MechanicOffer> pendingOffers;
  final bool isProcessing;

  const JobState({
    this.customerStatus = CustomerRequestStatus.idle,
    this.mechanicJobStatus = MechanicJobStatus.idle,
    this.activeJob,
    this.pendingOffers = const [],
    this.isProcessing = false,
  });

  bool get hasActiveJob => customerStatus.isActive && activeJob != null;

  JobState copyWith({
    CustomerRequestStatus? customerStatus,
    MechanicJobStatus? mechanicJobStatus,
    Job? activeJob,
    List<MechanicOffer>? pendingOffers,
    bool? isProcessing,
  }) {
    return JobState(
      customerStatus: customerStatus ?? this.customerStatus,
      mechanicJobStatus: mechanicJobStatus ?? this.mechanicJobStatus,
      activeJob: activeJob ?? this.activeJob,
      pendingOffers: pendingOffers ?? this.pendingOffers,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class JobNotifier extends StateNotifier<JobState> {
  JobNotifier() : super(const JobState());

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 1 — Request Creation
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> submitRequest({
    required String description,
    required String carType,
    required String location,
    String? manualCategory, // override auto-tag if user selected manually
  }) async {
    final category = manualCategory ?? AutoTagger.detect(description);
    final minMinutes = AutoTagger.minimumMinutesFor(category);

    final job = Job(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      customer: MockUsers.customer,
      problemDescription: description,
      carType: carType.isEmpty ? 'Unknown vehicle' : carType,
      serviceCategory: category,
      location: location.isEmpty ? 'Nairobi, Kenya' : location,
      minimumServiceMinutes: minMinutes,
      customerStatus: CustomerRequestStatus.searching,
      mechanicStatus: MechanicJobStatus.idle,
      createdAt: DateTime.now(),
      updates: [
        JobUpdate(
          message: 'Request submitted · Auto-tagged: $category',
          timestamp: DateTime.now(),
        ),
      ],
    );

    state = state.copyWith(
      customerStatus: CustomerRequestStatus.searching,
      isProcessing: true,
      activeJob: job,
    );

    // ─── STAGE 2: Smart Dispatch — rank top 3 mechanics ─────────────────────
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    state = state.copyWith(
      customerStatus: CustomerRequestStatus.mechanicsResponding,
      pendingOffers: _rankedOffers(category),
      isProcessing: false,
    );

    // Auto-assign best (highest rating) after 15s if customer doesn't pick
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted) return;
      if (state.customerStatus != CustomerRequestStatus.mechanicsResponding) return;
      if (state.pendingOffers.isEmpty) return;
      selectMechanic(state.pendingOffers.first); // first = highest ranked
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 2 — Customer picks (or auto-assigned)
  // ───────────────────────────────────────────────────────────────────────────

  void selectMechanic(MechanicOffer offer) {
    if (state.customerStatus != CustomerRequestStatus.mechanicsResponding) return;

    _transition(
      customerStatus: CustomerRequestStatus.mechanicSelected,
      mechanicJobStatus: MechanicJobStatus.received,
      message: 'Dispatched to ${offer.name}',
      assignedOffer: offer,
      clearOffers: true,
    );

    // Simulate mechanic accepting within window (2s for demo)
    // In production: mechanic manually accepts in their app
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (state.mechanicJobStatus != MechanicJobStatus.received) return;
      mechanicAcceptsJob();
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 3 — Mechanic En Route
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicAcceptsJob() {
    if (state.mechanicJobStatus != MechanicJobStatus.received) return;
    final name = state.activeJob?.assignedOffer?.name ?? 'Mechanic';
    _transition(
      customerStatus: CustomerRequestStatus.enRoute,
      mechanicJobStatus: MechanicJobStatus.enRoute,
      message: '$name accepted · On the way',
    );
  }

  // Mechanic presses "Arrived" button
  void mechanicArrived() {
    if (state.mechanicJobStatus != MechanicJobStatus.enRoute) return;
    _transition(
      customerStatus: CustomerRequestStatus.awaitingArrivalConfirm,
      mechanicJobStatus: MechanicJobStatus.arrived,
      message: 'Mechanic arrived — confirm to proceed',
    );
  }

  // Customer confirms arrival
  void customerConfirmsArrival() {
    if (state.customerStatus != CustomerRequestStatus.awaitingArrivalConfirm) return;
    _transition(
      customerStatus: CustomerRequestStatus.awaitingServiceStart,
      mechanicJobStatus: MechanicJobStatus.awaitingStartConfirm,
      message: 'Arrival confirmed',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 4 — Dual-confirm Start (prevents fake/delayed starts)
  // ───────────────────────────────────────────────────────────────────────────

  // Mechanic taps "Start Service"
  void mechanicStartsService() {
    if (state.mechanicJobStatus != MechanicJobStatus.awaitingStartConfirm) return;
    _transition(
      customerStatus: CustomerRequestStatus.awaitingServiceStart,
      mechanicJobStatus: MechanicJobStatus.serviceActive,
      message: 'Mechanic started — waiting for your confirmation',
    );
  }

  // Customer confirms start
  void customerConfirmsStart() {
    if (state.customerStatus != CustomerRequestStatus.awaitingServiceStart) return;
    _transition(
      customerStatus: CustomerRequestStatus.serviceActive,
      mechanicJobStatus: MechanicJobStatus.serviceActive,
      message: 'Service started — both confirmed',
      serviceStartedNow: true,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 6 — Work Proof (before mechanic can end)
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicSubmitsWorkProof({
    String? note,
    bool checklistConfirmed = false,
  }) {
    if (state.mechanicJobStatus != MechanicJobStatus.serviceActive) return;

    final proof = WorkProof(
      mechanicNote: note,
      checklistConfirmed: checklistConfirmed,
      submittedAt: DateTime.now(),
    );

    final updatedJob = state.activeJob?.copyWith(
      workProof: proof,
      customerStatus: CustomerRequestStatus.awaitingWorkProof,
      mechanicStatus: MechanicJobStatus.submittingWorkProof,
      updates: [
        ...?state.activeJob?.updates,
        JobUpdate(
          message: 'Work proof submitted',
          timestamp: DateTime.now(),
        ),
      ],
    );

    state = state.copyWith(
      customerStatus: CustomerRequestStatus.awaitingWorkProof,
      mechanicJobStatus: MechanicJobStatus.submittingWorkProof,
      activeJob: updatedJob,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 7 — Dual-confirm End
  // ───────────────────────────────────────────────────────────────────────────

  // Mechanic presses "End Service"
  void mechanicEndsService() {
    if (state.mechanicJobStatus != MechanicJobStatus.submittingWorkProof) return;
    _transition(
      customerStatus: CustomerRequestStatus.verificationPending,
      mechanicJobStatus: MechanicJobStatus.awaitingCustomerConfirm,
      message: 'Work complete — please confirm',
    );

    // Auto-confirm after 10 minutes if customer doesn't respond
    // (10s in mock for demo purposes)
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (state.customerStatus != CustomerRequestStatus.verificationPending) return;
      _autoConfirmCompletion();
    });
  }

  // Customer confirms work is done
  void customerConfirmsCompletion() {
    if (state.customerStatus != CustomerRequestStatus.verificationPending &&
        state.customerStatus != CustomerRequestStatus.autoConfirmCountdown) {
      return;
    }
    _transition(
      customerStatus: CustomerRequestStatus.awaitingReview,
      mechanicJobStatus: MechanicJobStatus.completed,
      message: 'Service confirmed complete',
    );
  }

  void _autoConfirmCompletion() {
    _transition(
      customerStatus: CustomerRequestStatus.awaitingReview,
      mechanicJobStatus: MechanicJobStatus.completed,
      message: 'Auto-confirmed after no response',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 8 — Smart Review (feeds fraud detection)
  // ───────────────────────────────────────────────────────────────────────────

  void submitReview({
    required int stars,
    required bool issueResolved,
    required bool wasProfessional,
    String? comment,
  }) {
    if (state.customerStatus != CustomerRequestStatus.awaitingReview) return;

    final review = JobReview(
      stars: stars,
      issueResolved: issueResolved,
      wasProfessional: wasProfessional,
      comment: comment,
      submittedAt: DateTime.now(),
    );

    final updatedJob = state.activeJob?.copyWith(
      review: review,
      customerStatus: CustomerRequestStatus.completed,
      mechanicStatus: MechanicJobStatus.completed,
      updates: [
        ...?state.activeJob?.updates,
        JobUpdate(message: 'Review submitted', timestamp: DateTime.now()),
      ],
    );

    state = JobState(
      customerStatus: CustomerRequestStatus.completed,
      mechanicJobStatus: MechanicJobStatus.completed,
      activeJob: updatedJob,
    );
  }

  void skipReview() {
    if (state.customerStatus != CustomerRequestStatus.awaitingReview) return;
    _transition(
      customerStatus: CustomerRequestStatus.completed,
      mechanicJobStatus: MechanicJobStatus.completed,
      message: 'Review skipped',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Misc
  // ───────────────────────────────────────────────────────────────────────────

  void cancelRequest() {
    _transition(
      customerStatus: CustomerRequestStatus.cancelled,
      mechanicJobStatus: MechanicJobStatus.idle,
      message: 'Request cancelled',
    );
  }

  void reset() => state = const JobState();

  // ───────────────────────────────────────────────────────────────────────────
  // Private
  // ───────────────────────────────────────────────────────────────────────────

  void _transition({
    required CustomerRequestStatus customerStatus,
    required MechanicJobStatus mechanicJobStatus,
    required String message,
    MechanicOffer? assignedOffer,
    bool clearOffers = false,
    bool serviceStartedNow = false,
  }) {
    final now = DateTime.now();
    final currentJob = state.activeJob;
    final updatedJob = currentJob?.copyWith(
      customerStatus: customerStatus,
      mechanicStatus: mechanicJobStatus,
      assignedOffer: assignedOffer,
      serviceStartedAt: serviceStartedNow ? now : null,
      updates: [
        ...currentJob.updates,
        JobUpdate(message: message, timestamp: now),
      ],
    );

    state = JobState(
      customerStatus: customerStatus,
      mechanicJobStatus: mechanicJobStatus,
      activeJob: updatedJob ?? state.activeJob,
      pendingOffers: clearOffers ? const [] : state.pendingOffers,
    );
  }

  // Ranked by: skill match > rating > distance (Stage 2 smart dispatch)
  List<MechanicOffer> _rankedOffers(String category) {
    final offers = [
      MechanicOffer(
        mechanicId: 'mech_001',
        name: 'John Mwangi',
        rating: 4.9,
        reviewCount: 234,
        distanceKm: 1.2,
        etaMinutes: 8,
        skills: [category, 'Engine', 'Oil Change'],
        priceEstimate: 1200,
      ),
      MechanicOffer(
        mechanicId: 'mech_002',
        name: 'Peter Otieno',
        rating: 4.7,
        reviewCount: 156,
        distanceKm: 1.8,
        etaMinutes: 12,
        skills: [category, 'Tire', 'Diagnostics'],
        priceEstimate: 1000,
      ),
      MechanicOffer(
        mechanicId: 'mech_003',
        name: 'Samuel Njoroge',
        rating: 4.8,
        reviewCount: 89,
        distanceKm: 2.4,
        etaMinutes: 15,
        skills: ['Battery', 'Electrical', category],
        priceEstimate: 900,
      ),
    ];

    // Sort: skill match first, then by rating desc
    offers.sort((a, b) {
      final aHasSkill = a.skills.contains(category) ? 0 : 1;
      final bHasSkill = b.skills.contains(category) ? 0 : 1;
      if (aHasSkill != bHasSkill) return aHasSkill - bHasSkill;
      return b.rating.compareTo(a.rating);
    });

    return offers;
  }
}

final jobProvider = StateNotifierProvider<JobNotifier, JobState>((ref) {
  return JobNotifier();
});
