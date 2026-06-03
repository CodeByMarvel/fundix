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

/**
 * Submit (or resubmit) a mechanic application.
 * Any authenticated user can call this — role is still 'customer' at this point.
 * On approval, adminService.approveMechanic() flips the role to 'mechanic'.
 */
async function submitApplication(userId, body) {
  const {
    tier, nationalId,
    kraPin, kraDocUrl,
    zones, radiusKm,
    garageName, garageAddress, googleMapsLink,
    idPhotoUrl, selfieUrl,
    toolsPhotoUrls, workspacePhotoUrls, exteriorPhotoUrls,
  } = body;

  if (!tier || !nationalId) {
    throw Object.assign(new Error('tier and nationalId are required'), { status: 400 });
  }
  const mechanicType = tier === 2 || tier === '2' ? 'garage' : 'mobile';

  // Store photos and document URLs in a flexible metadata object
  const applicationMetadata = {
    kra_doc_url:           kraDocUrl        || null,
    id_photo_url:          idPhotoUrl       || null,
    selfie_url:            selfieUrl        || null,
    tools_photo_urls:      toolsPhotoUrls   || [],
    workspace_photo_urls:  workspacePhotoUrls || [],
    exterior_photo_urls:   exteriorPhotoUrls  || [],
    submitted_at:          new Date().toISOString(),
  };

  const patch = {
    mechanic_type:        mechanicType,
    application_status:   'pending',
    application_metadata: applicationMetadata,
    service_zones:        zones        || [],
    work_radius_km:       radiusKm     || null,
    garage_name:          garageName   || null,
    garage_address:       garageAddress || null,
    google_maps_link:     googleMapsLink || null,
    updated_at:           new Date().toISOString(),
  };
  // Tier 2 uses a KRA PIN text; tier 1 uses a KRA document photo (URL in metadata)
  if (kraPin) patch.kra_pin = kraPin;

  // Check for an existing row — allow resubmission if previously rejected
  const { data: existing } = await supabase
    .from('mechanics')
    .select('id, application_status')
    .eq('id', userId)
    .maybeSingle();

  if (existing) {
    if (existing.application_status === 'approved') {
      throw Object.assign(new Error('Your application has already been approved'), { status: 409 });
    }
    if (existing.application_status === 'pending') {
      throw Object.assign(new Error('Your application is already under review'), { status: 409 });
    }
    // Rejected — allow resubmission
    const { data, error } = await supabase
      .from('mechanics')
      .update({ ...patch, rejection_reason: null })
      .eq('id', userId)
      .select('id, application_status')
      .single();
    if (error) throw error;
    return data;
  }

  // First-time application — insert new row
  const { data, error } = await supabase
    .from('mechanics')
    .insert({ id: userId, ...patch })
    .select('id, application_status')
    .single();
  if (error) throw error;
  return data;
}

/**
 * Return all pending, unassigned requests that have a funded escrow —
 * meaning the customer has already paid the callout fee and the job is ready to claim.
 *
 * Mobile technicians are excluded from garage-only zones.
 */
async function getAvailableJobs(mechanicId) {
  const { data: mechanic, error: me } = await supabase
    .from('mechanics')
    .select('mechanic_type')
    .eq('id', mechanicId)
    .single();
  if (me) throw me;

  // Inner join with job_escrow so only funded (paid) requests are shown
  let q = supabase
    .from('requests')
    .select(
      'id, vehicle_info, symptoms, location_lat, location_lng, location_address, ' +
      'zone_type, call_out_fee, inspection_fee, created_at, ' +
      'job_escrow!inner(status)'
    )
    .eq('status', 'pending')
    .is('mechanic_id', null)
    .eq('job_escrow.status', 'funded')
    .order('created_at', { ascending: false });

  if (mechanic.mechanic_type === 'mobile') {
    q = q.neq('zone_type', 'garage_workshop');
  }

  const { data, error } = await q;
  if (error) throw error;
  return data;
}

/**
 * Mechanic claims a pending, funded request.
 *
 * Guards:
 *  - Escrow must be 'funded' (customer paid).
 *  - Request must still be 'pending' (not yet claimed).
 *  - UPDATE uses .eq('status', 'pending') as an optimistic lock — if two mechanics
 *    race, only one gets the row and the other gets a 409.
 */
async function acceptJob(mechanicId, requestId) {
  // Confirm escrow is funded (customer paid)
  const { data: escrow } = await supabase
    .from('job_escrow')
    .select('id, status')
    .eq('request_id', requestId)
    .maybeSingle();

  if (!escrow) {
    throw Object.assign(new Error('Customer has not initiated payment for this request'), { status: 409 });
  }
  if (escrow.status !== 'funded') {
    throw Object.assign(new Error(`Cannot accept — escrow is '${escrow.status}', expected 'funded'`), { status: 409 });
  }

  // Confirm request is still claimable
  const { data: request, error: reqErr } = await supabase
    .from('requests')
    .select('id, status')
    .eq('id', requestId)
    .single();

  if (reqErr?.code === 'PGRST116') throw Object.assign(new Error('Request not found'), { status: 404 });
  if (reqErr) throw reqErr;

  if (request.status !== 'pending') {
    throw Object.assign(
      new Error(`Cannot accept a request with status '${request.status}'`),
      { status: 409 }
    );
  }

  // Fetch mechanic's phone — needed so auto-release cron can B2C them later
  const { data: profile } = await supabase
    .from('profiles')
    .select('phone')
    .eq('id', mechanicId)
    .maybeSingle();

  // Claim — optimistic lock: if another mechanic grabbed it first, 0 rows → PGRST116 → 409
  const { data: updated, error: updateErr } = await supabase
    .from('requests')
    .update({ mechanic_id: mechanicId, status: 'accepted' })
    .eq('id', requestId)
    .eq('status', 'pending')
    .select('id, status, mechanic_id')
    .single();

  if (updateErr?.code === 'PGRST116') {
    throw Object.assign(new Error('Request was just accepted by another mechanic'), { status: 409 });
  }
  if (updateErr) throw updateErr;

  // Activate escrow: records mechanic_id + phone, moves status funded → active
  const { error: activateErr } = await supabase.rpc('activate_escrow', {
    p_request_id:     requestId,
    p_mechanic_id:    mechanicId,
    p_mechanic_phone: profile?.phone ?? null,
  });
  if (activateErr) throw activateErr;

  return updated;
}

module.exports = {
  getMechanicProfile,
  setAvailability,
  setOperatingStatus,
  updateLocation,
  upgradeToGarage,
  submitApplication,
  getAvailableJobs,
  acceptJob,
};
