// Fundix Operational Zone System
// Every job must be classified into one of these four zones before dispatch.
// The zone drives which mechanic tier can handle the job — not the other way around.

enum JobZone {
  // Tier 2 only — fixed registered automotive workspace
  garageWorkshop,

  // Tier 1 only — public/semi-controlled safe environments
  controlledMobile,

  // Emergency-only — immobile vehicle, verifiable location, stabilisation only
  highwayEmergency,

  // Blocked by default — unverifiable, unsafe, or informal locations
  restricted,
}

// Sub-types within Controlled Mobile Zone (Tier 1 approved environments)
enum MobileZoneType {
  commercialArea,    // malls, office parks, supermarkets, parking complexes
  residentialEstate, // gated communities, apartment compounds, managed estates
  fuelStation,       // petrol stations, service stations
}

extension JobZoneLabel on JobZone {
  String get label {
    switch (this) {
      case JobZone.garageWorkshop:  return 'Garage Zone';
      case JobZone.controlledMobile: return 'Controlled Mobile Zone';
      case JobZone.highwayEmergency: return 'Highway Emergency Zone';
      case JobZone.restricted:       return 'Restricted Zone';
    }
  }

  String get description {
    switch (this) {
      case JobZone.garageWorkshop:
        return 'Fixed registered workshop — full tools, accountable environment';
      case JobZone.controlledMobile:
        return 'Safe public location — mall, estate, or fuel station';
      case JobZone.highwayEmergency:
        return 'Emergency stabilisation only — no complex repairs';
      case JobZone.restricted:
        return 'Location blocked — cannot be verified or safely serviced';
    }
  }
}

extension MobileZoneLabel on MobileZoneType {
  String get label {
    switch (this) {
      case MobileZoneType.commercialArea:    return 'Commercial Areas';
      case MobileZoneType.residentialEstate: return 'Residential Estates';
      case MobileZoneType.fuelStation:       return 'Fuel Stations';
    }
  }

  String get examples {
    switch (this) {
      case MobileZoneType.commercialArea:    return 'Malls, office parks, supermarkets, parking complexes';
      case MobileZoneType.residentialEstate: return 'Gated communities, apartments, managed estates';
      case MobileZoneType.fuelStation:       return 'Petrol stations, service stations';
    }
  }
}
