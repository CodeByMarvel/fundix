const supabase = require('../firebase/firebaseConfig');

// Zone type constants — mirror the Dart JobZone enum and DB check constraint
const ZONE_TYPES = {
  GARAGE_WORKSHOP:    'garage_workshop',
  CONTROLLED_MOBILE:  'controlled_mobile',
  HIGHWAY_EMERGENCY:  'highway_emergency',
  RESTRICTED:         'restricted',
};

const MOBILE_SUBTYPES = {
  COMMERCIAL_AREA:     'commercial_area',
  RESIDENTIAL_ESTATE:  'residential_estate',
  FUEL_STATION:        'fuel_station',
};

// Valid declared types the client is allowed to send
const VALID_DECLARED_TYPES = new Set([
  'garage_workshop',
  'commercial_area',
  'residential_estate',
  'fuel_station',
  'highway_emergency',
]);

/**
 * Classify a customer's location into a JobZone.
 *
 * Flow:
 *   1. Validate coordinates are within the Nairobi service area.
 *   2. Run a PostGIS ST_Contains query against the zones table — the first
 *      matching zone wins (zones are seeded and maintained by ops).
 *   3. If no zone boundary matches, fall back to the client-declared type
 *      (customer told us "I'm at a mall"). This is the MVP path while zone
 *      boundaries are being seeded; remove the fallback once coverage is full.
 *   4. If nothing matches, return restricted.
 *
 * @param {number} lat
 * @param {number} lng
 * @param {string|undefined} declaredType  - Optional hint from the client
 * @returns {{ zone_type: string, mobile_zone_subtype?: string, source: string }}
 */
async function classifyLocation(lat, lng, declaredType) {
  if (!isValidCoordinate(lat, lng)) {
    return { zone_type: ZONE_TYPES.RESTRICTED, source: 'invalid_coordinates' };
  }

  if (!isWithinServiceArea(lat, lng)) {
    return { zone_type: ZONE_TYPES.RESTRICTED, source: 'outside_service_area' };
  }

  // PostGIS lookup — uses the spatial index on zones.boundary
  // ST_Contains(boundary, point) returns true when the point is inside the polygon.
  // Supabase exposes PostGIS via rpc; the function is defined in SCHEMA.sql comments.
  const { data: matchedZones, error } = await supabase.rpc('classify_point', {
    p_lat: lat,
    p_lng: lng,
  });

  if (!error && matchedZones && matchedZones.length > 0) {
    const zone = matchedZones[0];
    return {
      zone_type: zone.zone_type,
      mobile_zone_subtype: zone.mobile_zone_subtype ?? undefined,
      source: 'postgis',
    };
  }

  // MVP fallback: trust the client's declared type while PostGIS zones are being seeded.
  // The client must send one of the VALID_DECLARED_TYPES; anything else → restricted.
  if (declaredType && VALID_DECLARED_TYPES.has(declaredType)) {
    if (declaredType === 'garage_workshop') {
      return { zone_type: ZONE_TYPES.GARAGE_WORKSHOP, source: 'declared' };
    }
    if (declaredType === 'highway_emergency') {
      return { zone_type: ZONE_TYPES.HIGHWAY_EMERGENCY, source: 'declared' };
    }
    // All remaining valid types are mobile sub-types
    return {
      zone_type: ZONE_TYPES.CONTROLLED_MOBILE,
      mobile_zone_subtype: declaredType,
      source: 'declared',
    };
  }

  return { zone_type: ZONE_TYPES.RESTRICTED, source: 'unclassifiable' };
}

/**
 * Returns true if coordinates are plausible numbers in a geographic range.
 */
function isValidCoordinate(lat, lng) {
  return (
    typeof lat === 'number' && typeof lng === 'number' &&
    lat >= -90 && lat <= 90 &&
    lng >= -180 && lng <= 180
  );
}

/**
 * Rough bounding box for the Nairobi metro service area.
 * Replace with a PostGIS service_area table row when ops defines it precisely.
 */
function isWithinServiceArea(lat, lng) {
  return lat >= -1.5 && lat <= -1.1 && lng >= 36.6 && lng <= 37.1;
}

module.exports = { classifyLocation, ZONE_TYPES, MOBILE_SUBTYPES };
