const supabase = require('../firebase/firebaseConfig');

/**
 * Fetch a mechanic's full profile row, joined with their profile name.
 */
async function getMechanicProfile(mechanicId) {
  const { data, error } = await supabase
    .from('mechanics')
    .select('*, profiles(name, phone)')
    .eq('id', mechanicId)
    .single();
  if (error) throw error;
  return data;
}

/**
 * Toggle the mechanic's online/offline status and update their live GPS position.
 * When going offline, position is cleared so they drop out of proximity queries.
 *
 * @param {string} mechanicId
 * @param {boolean} isOnline
 * @param {{ lat: number, lng: number }|null} position  - Required when going online
 */
async function setAvailability(mechanicId, isOnline, position) {
  const patch = { is_online: isOnline };

  if (isOnline) {
    if (!position || typeof position.lat !== 'number' || typeof position.lng !== 'number') {
      throw Object.assign(new Error('GPS position required when going online'), { status: 400 });
    }
    patch.current_lat = position.lat;
    patch.current_lng = position.lng;
    // current_location is kept in sync by the DB trigger
  } else {
    patch.current_lat = null;
    patch.current_lng = null;
  }

  const { data, error } = await supabase
    .from('mechanics')
    .update(patch)
    .eq('id', mechanicId)
    .select('id, is_online, operating_status, current_lat, current_lng')
    .single();

  if (error) throw error;
  return data;
}

/**
 * Update the mechanic's operating status chip value.
 * is_online must already be true — the status is meaningless while offline.
 */
async function setOperatingStatus(mechanicId, operatingStatus) {
  const VALID = ['open_now', 'busy', 'appointment_only'];
  if (!VALID.includes(operatingStatus)) {
    throw Object.assign(new Error(`Invalid operating_status: ${operatingStatus}`), { status: 400 });
  }

  const { data, error } = await supabase
    .from('mechanics')
    .update({ operating_status: operatingStatus })
    .eq('id', mechanicId)
    .select('id, operating_status')
    .single();

  if (error) throw error;
  return data;
}

/**
 * Update mechanic's live GPS while they are online (called periodically by the app).
 */
async function updateLocation(mechanicId, lat, lng) {
  const { data, error } = await supabase
    .from('mechanics')
    .update({ current_lat: lat, current_lng: lng })
    .eq('id', mechanicId)
    .eq('is_online', true) // only update if actually online
    .select('id, current_lat, current_lng')
    .single();

  if (error) throw error;
  return data;
}

/**
 * Upgrade a mobile mechanic to garage type.
 * One-directional: garage → mobile is blocked at the DB constraint level too.
 */
async function upgradeToGarage(mechanicId) {
  // Verify current type before upgrading
  const { data: current, error: fetchErr } = await supabase
    .from('mechanics')
    .select('mechanic_type')
    .eq('id', mechanicId)
    .single();

  if (fetchErr) throw fetchErr;
  if (current.mechanic_type === 'garage') {
    throw Object.assign(new Error('Already a garage mechanic'), { status: 409 });
  }

  const { data, error } = await supabase
    .from('mechanics')
    .update({ mechanic_type: 'garage', verified: false }) // verified resets; ops must re-approve
    .eq('id', mechanicId)
    .select('id, mechanic_type, verified')
    .single();

  if (error) throw error;
  return data;
}

module.exports = { getMechanicProfile, setAvailability, setOperatingStatus, updateLocation, upgradeToGarage };
