// Customer-facing lifecycle
enum CustomerRequestStatus {
  idle,

  // Request submitted — finding mechanic
  searching,
  mechanicsResponding,
  mechanicSelected,

  // Mechanic on the way
  enRoute,

  // Mechanic at location, inspecting vehicle
  inspectionActive,

  // Pricing stage
  quoteReceived,    // customer reviews diagnosis + quote
  awaitingRevision, // customer rejected quote, mechanic revising

  // Repair
  repairInProgress,

  // Completion
  completionVerification, // mechanic done, customer verifying
  paymentPending,         // M-Pesa STK push triggered

  // End
  awaitingReview,
  completed,
  cancelled,
  disputed,
}

// Mechanic-facing lifecycle
enum MechanicJobStatus {
  idle,
  received,                     // incoming request
  enRoute,                      // navigating to customer
  inspecting,                   // physical inspection + writing diagnosis
  quoteReady,                   // diagnosis done, mechanic reviews quote
  awaitingQuoteApproval,        // quote sent to customer, waiting
  inRepair,                     // customer approved, repair in progress
  awaitingCustomerVerification, // repair marked done, waiting customer
  disputed,                     // customer disputed, admin reviewing
  completed,
}

extension CustomerRequestStatusX on CustomerRequestStatus {
  bool get isActive =>
      this != CustomerRequestStatus.idle &&
      this != CustomerRequestStatus.completed &&
      this != CustomerRequestStatus.cancelled &&
      this != CustomerRequestStatus.disputed;

  String get displayLabel {
    switch (this) {
      case CustomerRequestStatus.idle:
        return 'No active request';
      case CustomerRequestStatus.searching:
        return 'Finding mechanics…';
      case CustomerRequestStatus.mechanicsResponding:
        return 'Mechanics responding…';
      case CustomerRequestStatus.mechanicSelected:
        return 'Mechanic confirmed';
      case CustomerRequestStatus.enRoute:
        return 'Mechanic on the way';
      case CustomerRequestStatus.inspectionActive:
        return 'Inspection in progress';
      case CustomerRequestStatus.quoteReceived:
        return 'Quote ready — review now';
      case CustomerRequestStatus.awaitingRevision:
        return 'Awaiting revised quote…';
      case CustomerRequestStatus.repairInProgress:
        return 'Repair in progress';
      case CustomerRequestStatus.completionVerification:
        return 'Verify repair is complete';
      case CustomerRequestStatus.paymentPending:
        return 'Processing payment…';
      case CustomerRequestStatus.awaitingReview:
        return 'Leave a review';
      case CustomerRequestStatus.completed:
        return 'Completed';
      case CustomerRequestStatus.cancelled:
        return 'Cancelled';
      case CustomerRequestStatus.disputed:
        return 'Under review';
    }
  }

  bool get requiresCustomerAction =>
      this == CustomerRequestStatus.quoteReceived ||
      this == CustomerRequestStatus.completionVerification ||
      this == CustomerRequestStatus.awaitingReview;
}
