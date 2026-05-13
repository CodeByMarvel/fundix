import 'package:flutter/foundation.dart';

@immutable
class MechanicOffer {
  final String mechanicId;
  final String name;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final int etaMinutes;
  final List<String> skills;
  final int priceEstimate; // KES

  const MechanicOffer({
    required this.mechanicId,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.etaMinutes,
    required this.skills,
    required this.priceEstimate,
  });
}
