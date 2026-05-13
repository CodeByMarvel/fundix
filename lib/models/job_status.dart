// Customer-facing lifecycle — maps 1:1 to the 8-stage flow
enum CustomerRequestStatus {
  idle,

  // Stage 1: Request Creation
  searching,

  // Stage 2: Smart Dispatch
  mechanicsResponding,
  mechanicSelected,

  // Stage 3: En Route
  enRoute,
  awaitingArrivalConfirm, // mechanic pressed "Arrived", customer confirms

  // Stage 4: Dual-confirm start
  awaitingServiceStart, // mechanic tapped "Start", waiting on customer

  // Stage 5: Service Active (dynamic timer)
  serviceActive,

  // Stage 6: Work Proof
  awaitingWorkProof, // mechanic submitting proof before ending

  // Stage 7: Dual-confirm end
  verificationPending, // customer must confirm within X minutes
  autoConfirmCountdown, // customer didn't respond — auto-confirm timer running

  // Stage 8: Review
  awaitingReview,
  completed,
  cancelled,
}

// Mechanic-facing lifecycle
enum MechanicJobStatus {
  idle,
  received, // dispatched, 15–30s acceptance window open
  accepted,
  enRoute,
  arrived,
  awaitingStartConfirm, // waiting for customer to confirm start
  serviceActive,
  submittingWorkProof,
  awaitingCustomerConfirm, // waiting for customer to confirm end
  completed,
}

extension CustomerRequestStatusX on CustomerRequestStatus {
  bool get isActive =>
      this != CustomerRequestStatus.idle &&
      this != CustomerRequestStatus.completed &&
      this != CustomerRequestStatus.cancelled;

  String get displayLabel {
    switch (this) {
      case CustomerRequestStatus.idle:
        return 'No active request';
      case CustomerRequestStatus.searching:
        return 'Finding mechanics…';
      case CustomerRequestStatus.mechanicsResponding:
        return 'Mechanics are responding…';
      case CustomerRequestStatus.mechanicSelected:
        return 'Confirming mechanic…';
      case CustomerRequestStatus.enRoute:
        return 'Mechanic on the way';
      case CustomerRequestStatus.awaitingArrivalConfirm:
        return 'Mechanic arrived — confirm?';
      case CustomerRequestStatus.awaitingServiceStart:
        return 'Confirm service start';
      case CustomerRequestStatus.serviceActive:
        return 'Service in progress';
      case CustomerRequestStatus.awaitingWorkProof:
        return 'Mechanic finishing up…';
      case CustomerRequestStatus.verificationPending:
        return 'Confirm work is done';
      case CustomerRequestStatus.autoConfirmCountdown:
        return 'Auto-confirming soon…';
      case CustomerRequestStatus.awaitingReview:
        return 'Leave a review';
      case CustomerRequestStatus.completed:
        return 'Completed';
      case CustomerRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get requiresCustomerAction =>
      this == CustomerRequestStatus.awaitingArrivalConfirm ||
      this == CustomerRequestStatus.awaitingServiceStart ||
      this == CustomerRequestStatus.verificationPending ||
      this == CustomerRequestStatus.awaitingReview;
}
