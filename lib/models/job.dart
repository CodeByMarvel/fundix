import 'package:flutter/foundation.dart';
import 'job_status.dart';
import 'app_user.dart';
import 'mechanic_offer.dart';

@immutable
class JobUpdate {
  final String message;
  final DateTime timestamp;
  const JobUpdate({required this.message, required this.timestamp});
}

@immutable
class WorkProof {
  final String? mechanicNote;
  final bool checklistConfirmed;
  final DateTime submittedAt;

  const WorkProof({
    this.mechanicNote,
    required this.checklistConfirmed,
    required this.submittedAt,
  });
}

@immutable
class JobReview {
  final int stars; // 1–5
  final bool issueResolved;
  final bool wasProfessional;
  final String? comment;
  final DateTime submittedAt;

  const JobReview({
    required this.stars,
    required this.issueResolved,
    required this.wasProfessional,
    this.comment,
    required this.submittedAt,
  });
}

@immutable
class Job {
  final String id;
  final AppUser customer;
  final MechanicOffer? assignedOffer;
  final String problemDescription;
  final String carType;
  final String serviceCategory; // auto-tagged from description
  final String location;
  final int minimumServiceMinutes; // Stage 5: dynamic timer
  final CustomerRequestStatus customerStatus;
  final MechanicJobStatus mechanicStatus;
  final DateTime createdAt;
  final DateTime? serviceStartedAt;
  final WorkProof? workProof; // Stage 6
  final JobReview? review; // Stage 8
  final List<JobUpdate> updates;

  const Job({
    required this.id,
    required this.customer,
    this.assignedOffer,
    required this.problemDescription,
    required this.carType,
    required this.serviceCategory,
    required this.location,
    required this.minimumServiceMinutes,
    required this.customerStatus,
    required this.mechanicStatus,
    required this.createdAt,
    this.serviceStartedAt,
    this.workProof,
    this.review,
    required this.updates,
  });

  Job copyWith({
    MechanicOffer? assignedOffer,
    String? problemDescription,
    String? carType,
    String? serviceCategory,
    String? location,
    int? minimumServiceMinutes,
    CustomerRequestStatus? customerStatus,
    MechanicJobStatus? mechanicStatus,
    DateTime? serviceStartedAt,
    WorkProof? workProof,
    JobReview? review,
    List<JobUpdate>? updates,
  }) {
    return Job(
      id: id,
      customer: customer,
      assignedOffer: assignedOffer ?? this.assignedOffer,
      problemDescription: problemDescription ?? this.problemDescription,
      carType: carType ?? this.carType,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      location: location ?? this.location,
      minimumServiceMinutes:
          minimumServiceMinutes ?? this.minimumServiceMinutes,
      customerStatus: customerStatus ?? this.customerStatus,
      mechanicStatus: mechanicStatus ?? this.mechanicStatus,
      createdAt: createdAt,
      serviceStartedAt: serviceStartedAt ?? this.serviceStartedAt,
      workProof: workProof ?? this.workProof,
      review: review ?? this.review,
      updates: updates ?? this.updates,
    );
  }
}
