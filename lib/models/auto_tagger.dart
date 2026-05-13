// Rule-based auto-tagging for problem descriptions.
// Routes requests to the right mechanics, not just the fastest ones.
class AutoTagger {
  static const _rules = <String, List<String>>{
    'Battery': ['battery', "won't start", 'dead', 'no power', 'wont start', 'jump start', 'jumper'],
    'Tire': ['tire', 'tyre', 'flat', 'puncture', 'burst', 'rim', 'wheel'],
    'Engine': ['engine', 'overheating', 'overheat', 'smoke', 'knocking', 'stalling', 'stall', 'rev'],
    'Oil Change': ['oil', 'service', 'filter', 'lubricant'],
    'Electrical': ['electrical', 'electric', 'light', 'wiring', 'short circuit', 'fuse', 'spark'],
    'Brakes': ['brake', 'braking', 'squeaking', 'grinding', 'stopping'],
    'Transmission': ['gear', 'gearbox', 'transmission', 'clutch', 'shift'],
    'AC / Cooling': ['ac', 'air con', 'cooling', 'radiator', 'coolant', 'temperature'],
  };

  static String detect(String description) {
    final lower = description.toLowerCase();
    for (final entry in _rules.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return 'Diagnostics';
  }

  // Minimum service time per category (minutes) — Stage 5 dynamic timer
  static int minimumMinutesFor(String category) {
    switch (category) {
      case 'Battery':
        return 5;
      case 'Tire':
        return 15;
      case 'Oil Change':
        return 20;
      case 'Engine':
        return 30;
      case 'Electrical':
        return 25;
      case 'Brakes':
        return 30;
      case 'Transmission':
        return 40;
      case 'AC / Cooling':
        return 25;
      default:
        return 20;
    }
  }

  static const List<String> allCategories = [
    'Battery',
    'Tire',
    'Engine',
    'Oil Change',
    'Electrical',
    'Brakes',
    'Transmission',
    'AC / Cooling',
    'Diagnostics',
  ];
}
