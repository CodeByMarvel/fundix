enum MechanicType { garage, mobile }

enum MechanicTier {
  tier1, // Mobile Technician — freelance/mobile-based
  tier2, // Garage Partner — fixed workshop operator
}

enum MechanicLevel {
  level1, // Basic Verified — identity confirmed
  level2, // Trusted Professional — operationally reliable
  level3, // Preferred Professional — highly trusted
}

extension MechanicTierExt on MechanicTier {
  String get displayName => switch (this) {
        MechanicTier.tier1 => 'Mobile Technician',
        MechanicTier.tier2 => 'Garage Partner',
      };

  String get shortLabel => switch (this) {
        MechanicTier.tier1 => 'Tier 1',
        MechanicTier.tier2 => 'Tier 2',
      };
}

extension MechanicLevelExt on MechanicLevel {
  String get displayName => switch (this) {
        MechanicLevel.level1 => 'Basic Verified',
        MechanicLevel.level2 => 'Trusted Professional',
        MechanicLevel.level3 => 'Preferred Professional',
      };
}
