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
  final String? diagnosisNotes;
  final String? repairComplexity;
  final double? generatedQuote;

  const JobState({
    this.customerStatus = CustomerRequestStatus.idle,
    this.mechanicJobStatus = MechanicJobStatus.idle,
    this.activeJob,
    this.pendingOffers = const [],
    this.isProcessing = false,
    this.diagnosisNotes,
    this.repairComplexity,
    this.generatedQuote,
  });

  bool get hasActiveJob => customerStatus.isActive && activeJob != null;

  JobState copyWith({
    CustomerRequestStatus? customerStatus,
    MechanicJobStatus? mechanicJobStatus,
    Job? activeJob,
    List<MechanicOffer>? pendingOffers,
    bool? isProcessing,
    String? diagnosisNotes,
    String? repairComplexity,
    double? generatedQuote,
  }) {
    return JobState(
      customerStatus: customerStatus ?? this.customerStatus,
      mechanicJobStatus: mechanicJobStatus ?? this.mechanicJobStatus,
      activeJob: activeJob ?? this.activeJob,
      pendingOffers: pendingOffers ?? this.pendingOffers,
      isProcessing: isProcessing ?? this.isProcessing,
      diagnosisNotes: diagnosisNotes ?? this.diagnosisNotes,
      repairComplexity: repairComplexity ?? this.repairComplexity,
      generatedQuote: generatedQuote ?? this.generatedQuote,
    );
  }
}

class JobNotifier extends StateNotifier<JobState> {
  JobNotifier() : super(const JobState());

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 1 — Request Creation (Customer)
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> submitRequest({
    required String description,
    required String carType,
    required String location,
    String? manualCategory,
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

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    state = state.copyWith(
      customerStatus: CustomerRequestStatus.mechanicsResponding,
      pendingOffers: _rankedOffers(category),
      isProcessing: false,
    );

    // Auto-assign top mechanic after 15s if customer doesn't pick
    Future.delayed(const Duration(seconds: 15), () {
      if (!mounted) return;
      if (state.customerStatus != CustomerRequestStatus.mechanicsResponding) return;
      if (state.pendingOffers.isEmpty) return;
      selectMechanic(state.pendingOffers.first);
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
    // Mechanic manually accepts in their app — no auto-accept
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 2b — Mechanic accepts or rejects incoming request
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

  void mechanicRejectsJob() {
    if (state.mechanicJobStatus != MechanicJobStatus.received) return;
    final category = state.activeJob?.serviceCategory ?? 'General';

    final updatedJob = state.activeJob?.copyWith(
      mechanicStatus: MechanicJobStatus.idle,
      updates: [
        ...?state.activeJob?.updates,
        JobUpdate(
          message: 'Mechanic declined · Dispatching next available',
          timestamp: DateTime.now(),
        ),
      ],
    );

    state = JobState(
      customerStatus: CustomerRequestStatus.mechanicsResponding,
      mechanicJobStatus: MechanicJobStatus.idle,
      activeJob: updatedJob,
      pendingOffers: _rankedOffers(category),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 3 — Mechanic navigates; presses Confirm Arrival → inspection starts
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicArrived() {
    if (state.mechanicJobStatus != MechanicJobStatus.enRoute) return;
    _transition(
      customerStatus: CustomerRequestStatus.awaitingArrivalConfirm,
      mechanicJobStatus: MechanicJobStatus.inspecting,
      message: 'Mechanic arrived · Inspection started',
    );
  }

  // Customer confirms they can see the mechanic (customer-side action)
  void customerConfirmsArrival() {
    if (state.customerStatus != CustomerRequestStatus.awaitingArrivalConfirm) return;
    _transition(
      customerStatus: CustomerRequestStatus.awaitingServiceStart,
      mechanicJobStatus: state.mechanicJobStatus, // mechanic already inspecting
      message: 'Arrival confirmed · Mechanic inspecting vehicle',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 4 — Inspection: mechanic writes diagnosis and submits
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicSubmitsDiagnosis({
    required String notes,
    required String complexity, // 'minor' | 'moderate' | 'major'
  }) {
    if (state.mechanicJobStatus != MechanicJobStatus.inspecting) return;

    final quote = _generateQuote(complexity);
    final updatedJob = state.activeJob?.copyWith(
      mechanicStatus: MechanicJobStatus.quoteReady,
      updates: [
        ...?state.activeJob?.updates,
        JobUpdate(
          message: 'Diagnosis submitted · $complexity complexity · KES ${quote.toStringAsFixed(0)} estimated',
          timestamp: DateTime.now(),
        ),
      ],
    );

    state = state.copyWith(
      mechanicJobStatus: MechanicJobStatus.quoteReady,
      diagnosisNotes: notes,
      repairComplexity: complexity,
      generatedQuote: quote,
      activeJob: updatedJob,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 5 — Mechanic sends quote; customer approves or rejects
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicSendsQuote() {
    if (state.mechanicJobStatus != MechanicJobStatus.quoteReady) return;
    _transition(
      customerStatus: CustomerRequestStatus.awaitingServiceStart,
      mechanicJobStatus: MechanicJobStatus.awaitingQuoteApproval,
      message: 'Quote sent to customer · KES ${state.generatedQuote?.toStringAsFixed(0) ?? '—'}',
    );
  }

  // Called when customer approves the quote
  void customerApprovesQuote() {
    if (state.mechanicJobStatus != MechanicJobStatus.awaitingQuoteApproval) return;
    _transition(
      customerStatus: CustomerRequestStatus.awaitingWorkProof,
      mechanicJobStatus: MechanicJobStatus.inRepair,
      message: 'Quote approved · Repair started',
      serviceStartedNow: true,
    );
  }

  // Customer confirms "start" on their screen — mapped to quote approval
  void customerConfirmsStart() {
    customerApprovesQuote();
  }

  // Called when customer rejects the quote
  void customerRejectsQuote() {
    if (state.mechanicJobStatus != MechanicJobStatus.awaitingQuoteApproval) return;
    _transition(
      customerStatus: CustomerRequestStatus.awaitingServiceStart,
      mechanicJobStatus: MechanicJobStatus.inspecting,
      message: 'Quote rejected by customer · Revising diagnosis',
    );
    state = state.copyWith(
      diagnosisNotes: null,
      repairComplexity: null,
      generatedQuote: null,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 6 — Repair in progress; mechanic marks complete
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicCompletesRepair() {
    if (state.mechanicJobStatus != MechanicJobStatus.inRepair) return;
    _transition(
      customerStatus: CustomerRequestStatus.verificationPending,
      mechanicJobStatus: MechanicJobStatus.awaitingCustomerVerification,
      message: 'Repair complete · Awaiting customer verification',
    );

    // Auto-confirm after 10 minutes if customer doesn't respond (10s in dev)
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (state.mechanicJobStatus != MechanicJobStatus.awaitingCustomerVerification) return;
      _autoConfirmCompletion();
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 7 — Customer verifies; confirmed or disputed
  // ───────────────────────────────────────────────────────────────────────────

  void customerConfirmsCompletion() {
    if (state.customerStatus != CustomerRequestStatus.verificationPending &&
        state.customerStatus != CustomerRequestStatus.autoConfirmCountdown) {
      return;
    }
    _transition(
      customerStatus: CustomerRequestStatus.awaitingReview,
      mechanicJobStatus: MechanicJobStatus.completed,
      message: 'Repair verified by customer · Payment processing',
    );
  }

  void customerDisputesRepair() {
    if (state.customerStatus != CustomerRequestStatus.verificationPending) return;
    _transition(
      customerStatus: CustomerRequestStatus.cancelled,
      mechanicJobStatus: MechanicJobStatus.disputed,
      message: 'Repair disputed · Admin reviewing',
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
  // STAGE 8 — Review (customer rates mechanic)
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
  // Private helpers
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
      diagnosisNotes: state.diagnosisNotes,
      repairComplexity: state.repairComplexity,
      generatedQuote: state.generatedQuote,
    );
  }

  double _generateQuote(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'minor':
        return 800;
      case 'major':
        return 6500;
      default: // moderate
        return 2500;
    }
  }

  // Ranked by: skill match > rating > distance
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
