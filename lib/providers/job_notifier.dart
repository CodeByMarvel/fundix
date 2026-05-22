import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../models/mechanic_offer.dart';
import '../models/auto_tagger.dart';
import '../services/request_service.dart';
import 'auth_provider.dart';
import 'location_provider.dart';
import 'mechanic_availability_provider.dart';

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
  final String? activeVehicleId;
  final String? error;

  const JobState({
    this.customerStatus = CustomerRequestStatus.idle,
    this.mechanicJobStatus = MechanicJobStatus.idle,
    this.activeJob,
    this.pendingOffers = const [],
    this.isProcessing = false,
    this.diagnosisNotes,
    this.repairComplexity,
    this.generatedQuote,
    this.activeVehicleId,
    this.error,
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
    String? activeVehicleId,
    String? error,
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
      activeVehicleId: activeVehicleId ?? this.activeVehicleId,
      error: error,
    );
  }
}

class JobNotifier extends StateNotifier<JobState> {
  JobNotifier(this._ref) : super(const JobState());
  final Ref _ref;

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 1 — Request Creation (Customer)
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> submitRequest({
    required String description,
    String? vehicleId,
    String? manualCategory,
    Map<String, dynamic>? vehicleInfo,
    String? urgency,
    String? serviceType,
    DateTime? scheduledAt,
  }) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    final category = manualCategory ?? AutoTagger.detect(description);
    final minMinutes = AutoTagger.minimumMinutesFor(category);

    // Ensure we have GPS — request it if not yet fetched
    var loc = _ref.read(locationProvider);
    if (!loc.hasLocation) {
      await _ref.read(locationProvider.notifier).requestLocation();
      loc = _ref.read(locationProvider);
    }

    // Fallback: Nairobi city centre when GPS is unavailable
    final lat = loc.latitude ?? -1.2864;
    final lng = loc.longitude ?? 36.8172;

    state = state.copyWith(
      customerStatus: CustomerRequestStatus.searching,
      isProcessing: true,
      error: null,
    );

    try {
      final result = await RequestService.createRequest(
        vehicleInfo: vehicleInfo ?? {'displayName': 'Unknown vehicle'},
        symptoms: description,
        lat: lat,
        lng: lng,
        urgency: urgency,
        serviceType: serviceType,
        scheduledAt: scheduledAt,
      );

      if (!mounted) return;

      final job = Job(
        id: result['id'] as String,
        customer: user,
        problemDescription: description,
        carType: vehicleInfo?['displayName'] as String? ?? 'Unknown vehicle',
        serviceCategory: category,
        location: loc.hasLocation
            ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
            : 'Nairobi, Kenya',
        minimumServiceMinutes: minMinutes,
        customerStatus: CustomerRequestStatus.searching,
        mechanicStatus: MechanicJobStatus.idle,
        createdAt: DateTime.now(),
        updates: [
          JobUpdate(
            message: 'Request submitted · Searching for mechanics',
            timestamp: DateTime.now(),
          ),
        ],
      );

      state = state.copyWith(
        customerStatus: CustomerRequestStatus.searching,
        isProcessing: false,
        activeJob: job,
        activeVehicleId: vehicleId,
        pendingOffers: const [],
      );
    } catch (e) {
      if (!mounted) return;
      state = JobState(error: e.toString());
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 2 — Customer picks mechanic (dispatched via realtime)
  // ───────────────────────────────────────────────────────────────────────────

  void selectMechanic(MechanicOffer offer) {
    if (!_ref.read(mechanicIsOnlineProvider)) return;
    if (state.customerStatus != CustomerRequestStatus.mechanicsResponding) return;

    _transition(
      customerStatus: CustomerRequestStatus.mechanicSelected,
      mechanicJobStatus: MechanicJobStatus.received,
      message: 'Dispatched to ${offer.name}',
      assignedOffer: offer,
      clearOffers: true,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 2b — Mechanic accepts or rejects
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

    final updatedJob = state.activeJob?.copyWith(
      mechanicStatus: MechanicJobStatus.idle,
      updates: [
        ...?state.activeJob?.updates,
        JobUpdate(
          message: 'Mechanic declined · Searching for next available',
          timestamp: DateTime.now(),
        ),
      ],
    );

    // Go back to searching — realtime will push the next offer
    state = JobState(
      customerStatus: CustomerRequestStatus.searching,
      mechanicJobStatus: MechanicJobStatus.idle,
      activeJob: updatedJob,
      pendingOffers: const [],
      activeVehicleId: state.activeVehicleId,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 3 — En route; mechanic confirms arrival
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicArrived() {
    if (state.mechanicJobStatus != MechanicJobStatus.enRoute) return;
    _transition(
      customerStatus: CustomerRequestStatus.inspectionActive,
      mechanicJobStatus: MechanicJobStatus.inspecting,
      message: 'Mechanic arrived · Inspection started',
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 4 — Mechanic writes diagnosis
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicSubmitsDiagnosis({
    required String notes,
    required String complexity,
  }) {
    if (state.mechanicJobStatus != MechanicJobStatus.inspecting) return;

    final quote = _generateQuote(complexity);
    final updatedJob = state.activeJob?.copyWith(
      mechanicStatus: MechanicJobStatus.quoteReady,
      updates: [
        ...?state.activeJob?.updates,
        JobUpdate(
          message:
              'Diagnosis submitted · $complexity complexity · KES ${quote.toStringAsFixed(0)} estimated',
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
  // STAGE 5 — Quote sent; customer approves or rejects
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicSendsQuote() {
    if (state.mechanicJobStatus != MechanicJobStatus.quoteReady) return;
    _transition(
      customerStatus: CustomerRequestStatus.quoteReceived,
      mechanicJobStatus: MechanicJobStatus.awaitingQuoteApproval,
      message:
          'Quote sent · KES ${state.generatedQuote?.toStringAsFixed(0) ?? '—'}',
    );
  }

  void customerApprovesQuote() {
    if (state.mechanicJobStatus != MechanicJobStatus.awaitingQuoteApproval) return;
    _transition(
      customerStatus: CustomerRequestStatus.repairInProgress,
      mechanicJobStatus: MechanicJobStatus.inRepair,
      message: 'Quote approved · Repair started',
      serviceStartedNow: true,
    );
  }

  void customerRejectsQuote() {
    if (state.customerStatus != CustomerRequestStatus.quoteReceived) return;
    _transition(
      customerStatus: CustomerRequestStatus.awaitingRevision,
      mechanicJobStatus: MechanicJobStatus.inspecting,
      message: 'Quote rejected · Mechanic revising diagnosis',
    );
    state = state.copyWith(
      diagnosisNotes: null,
      repairComplexity: null,
      generatedQuote: null,
    );
  }

  void endWithInspectionFee() {
    if (state.customerStatus != CustomerRequestStatus.quoteReceived) return;
    const inspectionFee = 300.0;
    final now = DateTime.now();
    final updatedJob = state.activeJob?.copyWith(
      customerStatus: CustomerRequestStatus.paymentPending,
      mechanicStatus: MechanicJobStatus.completed,
      updates: [
        ...?state.activeJob?.updates,
        JobUpdate(
          message: 'Session ended at inspection · KES 300 inspection fee',
          timestamp: now,
        ),
      ],
    );
    state = JobState(
      customerStatus: CustomerRequestStatus.paymentPending,
      mechanicJobStatus: MechanicJobStatus.completed,
      activeJob: updatedJob ?? state.activeJob,
      generatedQuote: inspectionFee,
      activeVehicleId: state.activeVehicleId,
    );
    _processPayment();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 6 — Repair in progress
  // ───────────────────────────────────────────────────────────────────────────

  void mechanicCompletesRepair() {
    if (state.mechanicJobStatus != MechanicJobStatus.inRepair) return;
    _transition(
      customerStatus: CustomerRequestStatus.completionVerification,
      mechanicJobStatus: MechanicJobStatus.awaitingCustomerVerification,
      message: 'Repair complete · Awaiting customer verification',
    );

    Future.delayed(const Duration(minutes: 10), () {
      if (!mounted) return;
      if (state.mechanicJobStatus != MechanicJobStatus.awaitingCustomerVerification) {
        return;
      }
      _autoConfirmCompletion();
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 7 — Customer verifies; payment triggered
  // ───────────────────────────────────────────────────────────────────────────

  void customerConfirmsCompletion() {
    if (state.customerStatus != CustomerRequestStatus.completionVerification) return;
    _transition(
      customerStatus: CustomerRequestStatus.paymentPending,
      mechanicJobStatus: MechanicJobStatus.completed,
      message: 'Repair verified · M-Pesa STK push sent',
    );
    _processPayment();
  }

  void customerDisputesRepair() {
    if (state.customerStatus != CustomerRequestStatus.completionVerification) return;
    _transition(
      customerStatus: CustomerRequestStatus.disputed,
      mechanicJobStatus: MechanicJobStatus.disputed,
      message: 'Repair disputed · Admin reviewing',
    );
  }

  void _autoConfirmCompletion() {
    _transition(
      customerStatus: CustomerRequestStatus.paymentPending,
      mechanicJobStatus: MechanicJobStatus.completed,
      message: 'Auto-confirmed after no response · Payment processing',
    );
    _processPayment();
  }

  void _processPayment() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (state.customerStatus != CustomerRequestStatus.paymentPending) return;
      _transition(
        customerStatus: CustomerRequestStatus.awaitingReview,
        mechanicJobStatus: MechanicJobStatus.completed,
        message: 'Payment successful · Earnings credited to mechanic',
      );
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STAGE 8 — Customer rates mechanic
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
        JobUpdate(message: 'Review submitted · $stars ★', timestamp: DateTime.now()),
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
      activeVehicleId: state.activeVehicleId,
    );
  }

  double _generateQuote(String complexity) {
    switch (complexity.toLowerCase()) {
      case 'minor':
        return 800;
      case 'major':
        return 6500;
      default:
        return 2500;
    }
  }
}

final jobProvider = StateNotifierProvider<JobNotifier, JobState>((ref) {
  return JobNotifier(ref);
});
