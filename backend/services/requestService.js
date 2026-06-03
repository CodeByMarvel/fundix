const supabase = require('../firebase/firebaseConfig');
const { askLLM } = require('../llm/openaiService');
const { buildDiagnosisPrompt } = require('../llm/prompts');
const { parseDiagnosisResponse } = require('../llm/parser');
const { classifyLocation, ZONE_TYPES } = require('./zoneService');

/**
 * Create a service request.
 *
 * Classifies the customer's GPS position into a zone server-side —
 * the client sends a declaredType hint but the server is authoritative.
 * Restricted zones are rejected before anything is written.
 *
 * @param {string} uid
 * @param {{ vehicleInfo, symptoms, location: { lat, lng, address, declaredType } }} data
 */
async function createServiceRequest(uid, data) {
  const { vehicleInfo, symptoms, location } = data;

  if (!location || typeof location.lat !== 'number' || typeof location.lng !== 'number') {
    throw Object.assign(new Error('Valid location with lat and lng is required'), { status: 400 });
  }

  // Server-side zone classification — client hint is accepted but not trusted alone
  const zoneResult = await classifyLocation(location.lat, location.lng, location.declaredType);

  if (zoneResult.zone_type === ZONE_TYPES.RESTRICTED) {
    throw Object.assign(
      new Error('This location cannot be serviced. Move to a verified safe zone and try again.'),
      { status: 422, zone_source: zoneResult.source }
    );
  }

  const { data: row, error } = await supabase
    .from('requests')
    .insert({
      customer_id:         uid,
      vehicle_info:        vehicleInfo,
      symptoms,
      location_lat:        location.lat,
      location_lng:        location.lng,
      location_address:    location.address ?? null,
      zone_type:           zoneResult.zone_type,
      mobile_zone_subtype: zoneResult.mobile_zone_subtype ?? null,
      status:              'pending',
      created_at:          new Date(),
    })
    .select()
    .single();

  if (error) throw error;

  return {
    id:                 row.id,
    vehicleInfo,
    symptoms,
    location:           { lat: location.lat, lng: location.lng, address: location.address },
    zone_type:          row.zone_type,
    mobile_zone_subtype: row.mobile_zone_subtype,
    status:             row.status,
  };
}

async function fetchRequests(uid) {
  const { data, error } = await supabase
    .from('requests')
    .select('*')
    .eq('customer_id', uid)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}

async function runDiagnosis(symptoms, vehicleInfo) {
  const prompt = buildDiagnosisPrompt(symptoms, vehicleInfo);
  const raw = await askLLM(prompt);
  return parseDiagnosisResponse(raw);
}

/**
 * Mechanic marks inspection done.
 * - Moves request status from 'accepted' → 'inspection_complete'.
 * - Starts the callout-fee auto-release buffer on the escrow.
 *   Customer can dispute within the buffer; otherwise funds release to mechanic automatically.
 */
async function completeInspection(mechanicId, requestId, bufferMinutes) {
  // Verify the request belongs to this mechanic
  const { data: request, error: reqErr } = await supabase
    .from('requests')
    .select('id, status, mechanic_id')
    .eq('id', requestId)
    .single();

  if (reqErr?.code === 'PGRST116') throw Object.assign(new Error('Request not found'), { status: 404 });
  if (reqErr) throw reqErr;

  if (request.mechanic_id !== mechanicId) {
    throw Object.assign(new Error('This job is not assigned to you'), { status: 403 });
  }
  if (request.status !== 'accepted') {
    throw Object.assign(
      new Error(`Cannot complete inspection — request is '${request.status}', expected 'accepted'`),
      { status: 409 }
    );
  }

  const { error } = await supabase.rpc('complete_inspection', {
    p_request_id:            requestId,
    p_release_after_minutes: bufferMinutes,
  });
  if (error) throw error;

  return {
    message: `Inspection complete. Callout fee releases automatically in ${bufferMinutes} minute(s) unless disputed.`,
    autoReleaseMinutes: bufferMinutes,
  };
}

module.exports = { createServiceRequest, fetchRequests, runDiagnosis, completeInspection };
