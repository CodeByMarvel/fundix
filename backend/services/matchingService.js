const supabase = require('../firebase/firebaseConfig');

const MECHANIC_TYPE_FOR_ZONE = {
  garage_workshop:   'garage',
  controlled_mobile: 'mobile',
  highway_emergency: 'mobile', // emergency dispatch goes to mobile mechanics
};

/**
 * Find online mechanics who can handle a job in the given zone.
 *
 * Uses PostGIS ST_DWithin for proximity — this is an indexed spatial query
 * against mechanics.current_location, fast at scale.
 *
 * Falls back to haversine in JS if the RPC isn't available yet (dev mode).
 *
 * @param {{ lat: number, lng: number }} location  - Customer's position
 * @param {string} zoneType                        - From ZONE_TYPES
 * @param {number} radiusKm                        - Search radius (default 15 km)
 * @returns {Promise<Array>}  Mechanics sorted by distance ascending
 */
async function findNearbyMechanics(location, zoneType, radiusKm = 15) {
  const { lat, lng } = location;
  const mechanicType = MECHANIC_TYPE_FOR_ZONE[zoneType];

  if (!mechanicType) return [];

  // PostGIS path: ST_DWithin on the indexed geography column.
  // ST_DWithin(geography, geography, meters) — convert km to m.
  const { data: mechanics, error } = await supabase.rpc('nearby_mechanics', {
    p_lat:          lat,
    p_lng:          lng,
    p_radius_m:     radiusKm * 1000,
    p_mechanic_type: mechanicType,
  });

  if (!error && mechanics) {
    return mechanics;
  }

  // Dev fallback: JS-side haversine filter when the RPC isn't seeded yet.
  // Remove this once the Supabase function is deployed.
  return fallbackNearbyMechanics(lat, lng, mechanicType, radiusKm);
}

/**
 * Assign a mechanic to a request and advance the request status.
 * Called after the customer selects an offer.
 */
async function assignMechanic(requestId, mechanicId) {
  const { data, error } = await supabase
    .from('requests')
    .update({ mechanic_id: mechanicId, status: 'mechanic_selected', updated_at: new Date() })
    .eq('id', requestId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// ── Dev fallback ───────────────────────────────────────────────────────────────

async function fallbackNearbyMechanics(lat, lng, mechanicType, radiusKm) {
  const { data: mechanics, error } = await supabase
    .from('mechanics')
    .select('id, mechanic_type, is_online, current_lat, current_lng, rating, review_count, job_count, profiles(name)')
    .eq('is_online', true)
    .eq('mechanic_type', mechanicType)
    .not('current_lat', 'is', null)
    .not('current_lng', 'is', null);

  if (error) throw error;

  return mechanics
    .map(m => ({ ...m, distance_km: haversineKm(lat, lng, m.current_lat, m.current_lng) }))
    .filter(m => m.distance_km <= radiusKm)
    .sort((a, b) => a.distance_km - b.distance_km);
}

function haversineKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

function toRad(deg) { return deg * (Math.PI / 180); }

module.exports = { findNearbyMechanics, assignMechanic };
