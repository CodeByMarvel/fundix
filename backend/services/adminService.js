const supabase = require('../firebase/firebaseConfig');
const { parsePagination } = require('../utils/pagination');

// ── Tier mapping ──────────────────────────────────────────────────────────────
// Tier 1 = Mobile Technician ('mobile'), Tier 2 = Garage Partner ('garage')
function tierToType(tier) {
  const n = Number(tier);
  if (n === 1) return 'mobile';
  if (n === 2) return 'garage';
  throw Object.assign(new Error('Tier must be 1 (Mobile Technician) or 2 (Garage Partner)'), { status: 400 });
}

// ── Shared error helper ───────────────────────────────────────────────────────
function throwIfNotFound(error, name = 'Record') {
  if (!error) return;
  if (error.code === 'PGRST116') {
    throw Object.assign(new Error(`${name} not found`), { status: 404 });
  }
  throw error;
}

// Statuses that represent a job in flight (not yet terminal)
const ACTIVE_STATUSES = ['dispatching', 'offers_sent', 'mechanic_selected', 'accepted', 'in_progress'];


// ══════════════════════════════════════════════════════════════════════════════
// SECTION A — Mechanic Management
// ══════════════════════════════════════════════════════════════════════════════

// Original — preserved for listPending endpoint
async function getPendingMechanics() {
  const { data, error } = await supabase
    .from('mechanics')
    .select('*, profiles(name, phone, avatar_url)')
    .eq('application_status', 'pending')
    .order('updated_at', { ascending: false });
  if (error) throw error;
  return data;
}

// A1 — full profile by id
async function getMechanicById(mechanicId) {
  const { data, error } = await supabase
    .from('mechanics')
    .select('*, profiles(id, name, phone, avatar_url, role, created_at)')
    .eq('id', mechanicId)
    .single();
  throwIfNotFound(error, 'Mechanic');
  return data;
}

// A2 — all mechanics, paginated (replaces original getAllMechanics)
async function getAllMechanics(query = {}) {
  const { from, to, sortCol, ascending } = parsePagination(query);
  const { data, error, count } = await supabase
    .from('mechanics')
    .select('*, profiles(name, phone, avatar_url)', { count: 'exact' })
    .order(sortCol, { ascending })
    .range(from, to);
  if (error) throw error;
  return { data, total: count };
}

// A3 — approved mechanics, filterable by tier & level
async function getApprovedMechanics(query = {}) {
  const { from, to, sortCol, ascending } = parsePagination(query);

  let q = supabase
    .from('mechanics')
    .select('*, profiles(name, phone, avatar_url)', { count: 'exact' })
    .eq('application_status', 'approved')
    .eq('is_active', true);

  if (query.tier) q = q.eq('mechanic_type', tierToType(query.tier));
  if (query.level) {
    const lvl = parseInt(query.level);
    if (lvl < 1 || lvl > 3) throw Object.assign(new Error('level must be 1–3'), { status: 400 });
    q = q.eq('level', lvl);
  }

  const { data, error, count } = await q.order(sortCol, { ascending }).range(from, to);
  if (error) throw error;
  return { data, total: count };
}

// A4 — rejected applications, paginated
async function getRejectedMechanics(query = {}) {
  const { from, to, sortCol, ascending } = parsePagination(query);
  const { data, error, count } = await supabase
    .from('mechanics')
    .select('*, profiles(name, phone, avatar_url)', { count: 'exact' })
    .eq('application_status', 'rejected')
    .order(sortCol, { ascending })
    .range(from, to);
  if (error) throw error;
  return { data, total: count };
}

// Original — preserved, extended to also flip the user's auth role
async function approveMechanic(mechanicId, level = 1, tier) {
  if (level < 1 || level > 3) {
    throw Object.assign(new Error('Level must be between 1 and 3'), { status: 400 });
  }

  const patch = { application_status: 'approved', level };
  if (tier != null) patch.mechanic_type = tierToType(tier);

  const { data, error } = await supabase
    .from('mechanics')
    .update(patch)
    .eq('id', mechanicId)
    .select('id, application_status, level, mechanic_type')
    .single();
  throwIfNotFound(error, 'Mechanic');

  // Flip the user's role in profiles table and Supabase auth metadata
  // so the Flutter app routes them to MechanicShell on next session refresh
  await supabase.from('profiles').update({ role: 'mechanic' }).eq('id', mechanicId);
  await supabase.auth.admin.updateUserById(mechanicId, {
    user_metadata: { role: 'mechanic' },
  });

  return data;
}

// Original — preserved, extended with rejection reason
async function rejectMechanic(mechanicId, reason) {
  const { data, error } = await supabase
    .from('mechanics')
    .update({
      application_status: 'rejected',
      ...(reason ? { rejection_reason: reason } : {}),
    })
    .eq('id', mechanicId)
    .select('id, application_status, rejection_reason')
    .single();
  throwIfNotFound(error, 'Mechanic');
  return data;
}

// Original — preserved
async function setMechanicLevel(mechanicId, level) {
  if (level < 1 || level > 3) {
    throw Object.assign(new Error('Level must be between 1 and 3'), { status: 400 });
  }
  const { data, error } = await supabase
    .from('mechanics')
    .update({ level })
    .eq('id', mechanicId)
    .select('id, level, application_status')
    .single();
  throwIfNotFound(error, 'Mechanic');
  return data;
}

// A5 — update tier (mechanic_type)
async function setMechanicTier(mechanicId, tier) {
  const mechanicType = tierToType(tier);
  const { data, error } = await supabase
    .from('mechanics')
    .update({ mechanic_type: mechanicType })
    .eq('id', mechanicId)
    .select('id, mechanic_type, level, application_status')
    .single();
  throwIfNotFound(error, 'Mechanic');
  return data;
}

// A6 — soft-delete (requires migration 002 for is_active column)
async function deactivateMechanic(mechanicId) {
  const { data, error } = await supabase
    .from('mechanics')
    .update({ is_active: false, is_online: false })
    .eq('id', mechanicId)
    .select('id, is_active, application_status')
    .single();
  throwIfNotFound(error, 'Mechanic');
  return data;
}

// A7 — aggregate counts
async function getMechanicStats() {
  const { data, error } = await supabase
    .from('mechanics')
    .select('application_status, mechanic_type, level');
  if (error) throw error;

  const total    = data.length;
  const pending  = data.filter(m => m.application_status === 'pending').length;
  const approved = data.filter(m => m.application_status === 'approved').length;
  const rejected = data.filter(m => m.application_status === 'rejected').length;
  const mobile   = data.filter(m => m.mechanic_type === 'mobile').length;
  const garage   = data.filter(m => m.mechanic_type === 'garage').length;
  const by_level = { 1: 0, 2: 0, 3: 0 };
  data.forEach(m => { if (m.level >= 1 && m.level <= 3) by_level[m.level]++; });

  return {
    total,
    by_status: { pending, approved, rejected },
    by_tier:   { mobile_technician: mobile, garage_partner: garage },
    by_level,
  };
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION B — Customer Management
// ══════════════════════════════════════════════════════════════════════════════

// B1 — paginated customer list (requires migration 002 for is_banned columns)
async function listCustomers(query = {}) {
  const { from, to, sortCol, ascending } = parsePagination(query);
  const { data, error, count } = await supabase
    .from('profiles')
    .select('id, name, phone, avatar_url, created_at, is_banned, banned_reason, banned_at', { count: 'exact' })
    .eq('role', 'customer')
    .order(sortCol, { ascending })
    .range(from, to);
  if (error) throw error;
  return { data, total: count };
}

// B2 — full customer detail, with vehicles and auth email
async function getCustomerById(customerId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, name, phone, avatar_url, created_at, is_banned, banned_reason, banned_at')
    .eq('id', customerId)
    .eq('role', 'customer')
    .single();
  throwIfNotFound(error, 'Customer');

  const [{ data: vehicles, error: ve }, authResult] = await Promise.all([
    supabase
      .from('vehicles')
      .select('*')
      .eq('owner_id', customerId)
      .order('created_at', { ascending: true }),
    supabase.auth.admin.getUserById(customerId).catch(() => ({ data: null })),
  ]);
  if (ve) throw ve;

  const email = authResult?.data?.user?.email ?? null;
  return { ...data, email, vehicles: vehicles ?? [] };
}

// B3 — ban customer
async function banCustomer(customerId, reason) {
  if (!reason || !reason.trim()) {
    throw Object.assign(new Error('A ban reason is required'), { status: 400 });
  }
  const { data, error } = await supabase
    .from('profiles')
    .update({
      is_banned:     true,
      banned_reason: reason.trim(),
      banned_at:     new Date().toISOString(),
    })
    .eq('id', customerId)
    .eq('role', 'customer')
    .select('id, is_banned, banned_reason, banned_at')
    .single();
  throwIfNotFound(error, 'Customer');
  return data;
}

// B4 — unban customer
async function unbanCustomer(customerId) {
  const { data, error } = await supabase
    .from('profiles')
    .update({ is_banned: false, banned_reason: null, banned_at: null })
    .eq('id', customerId)
    .eq('role', 'customer')
    .select('id, is_banned')
    .single();
  throwIfNotFound(error, 'Customer');
  return data;
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION C — Request / Job Management
// ══════════════════════════════════════════════════════════════════════════════

// C1 — list requests, filter by status
async function listRequests(query = {}) {
  const { from, to, sortCol, ascending } = parsePagination(query);

  let q = supabase
    .from('requests')
    .select(
      'id, status, price_estimate, created_at, updated_at, ' +
      'location_address, zone_type, customer_id, mechanic_id',
      { count: 'exact' }
    );

  if (query.status) {
    if (query.status === 'active') {
      q = q.in('status', ACTIVE_STATUSES);
    } else {
      q = q.eq('status', query.status);
    }
  }

  const { data, error, count } = await q.order(sortCol, { ascending }).range(from, to);
  if (error) throw error;
  return { data, total: count };
}

// C2 — full request detail with customer + mechanic + escrow
async function getRequestById(requestId) {
  const { data, error } = await supabase
    .from('requests')
    .select('*')
    .eq('id', requestId)
    .single();
  throwIfNotFound(error, 'Request');

  const [customerResult, mechanicResult, escrowResult] = await Promise.all([
    data.customer_id
      ? supabase.from('profiles').select('id, name, phone, avatar_url').eq('id', data.customer_id).maybeSingle()
      : Promise.resolve({ data: null }),
    data.mechanic_id
      ? supabase.from('mechanics').select('id, rating, level, mechanic_type, profiles(name, phone)').eq('id', data.mechanic_id).maybeSingle()
      : Promise.resolve({ data: null }),
    supabase.from('job_escrow').select('id, status, travel_fee, inspection_fee, balance_held, mpesa_reference').eq('request_id', requestId).maybeSingle(),
  ]);

  return {
    ...data,
    customer: customerResult.data,
    mechanic: mechanicResult.data,
    escrow:   escrowResult.data,
  };
}

// C3 — admin force-cancel (only non-terminal statuses)
const CANCELLABLE_STATUSES = ['pending', ...ACTIVE_STATUSES];

async function cancelRequest(requestId) {
  const { data: current, error: fe } = await supabase
    .from('requests')
    .select('id, status')
    .eq('id', requestId)
    .single();
  throwIfNotFound(fe, 'Request');

  if (!CANCELLABLE_STATUSES.includes(current.status)) {
    throw Object.assign(
      new Error(`Cannot cancel a request with status '${current.status}'`),
      { status: 409 }
    );
  }

  const { data, error } = await supabase
    .from('requests')
    .update({ status: 'cancelled' })
    .eq('id', requestId)
    .select('id, status, updated_at')
    .single();
  if (error) throw error;
  return data;
}

// C4 — aggregate counts + revenue from price_estimate on completed jobs
async function getRequestStats() {
  const { data, error } = await supabase
    .from('requests')
    .select('status, price_estimate');
  if (error) throw error;

  const by_status = {};
  let totalRevenue   = 0;
  let completedCount = 0;

  for (const r of data) {
    by_status[r.status] = (by_status[r.status] || 0) + 1;
    if (r.status === 'completed' && r.price_estimate) {
      totalRevenue += Number(r.price_estimate);
      completedCount++;
    }
  }

  return {
    total:              data.length,
    by_status,
    total_revenue_kes:  +totalRevenue.toFixed(2),
    avg_job_value_kes:  completedCount > 0 ? +(totalRevenue / completedCount).toFixed(2) : 0,
  };
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION D — Payments & Escrow
// ══════════════════════════════════════════════════════════════════════════════

// D — private helper: fetch escrow row for a request
async function _getEscrowByRequest(requestId) {
  const { data, error } = await supabase
    .from('job_escrow')
    .select('id, status, balance_held')
    .eq('request_id', requestId)
    .single();
  if (error) {
    if (error.code === 'PGRST116') {
      throw Object.assign(new Error('No escrow record found for this request'), { status: 404 });
    }
    throw error;
  }
  return data;
}

// D1 — list all job_escrow rows, filter by status
async function listPayments(query = {}) {
  const { from, to, sortCol, ascending } = parsePagination(query);

  let q = supabase
    .from('job_escrow')
    .select(
      'id, request_id, customer_id, mechanic_id, status, ' +
      'travel_fee, inspection_fee, balance_held, mpesa_reference, created_at, updated_at',
      { count: 'exact' }
    );

  if (query.status) q = q.eq('status', query.status);

  const { data, error, count } = await q.order(sortCol, { ascending }).range(from, to);
  if (error) throw error;
  return { data, total: count };
}

// D2 — full payment ledger for a request via existing RPC
async function getPaymentByRequest(requestId) {
  const { data, error } = await supabase.rpc('get_job_ledger', { p_request_id: requestId });
  if (error) throw error;

  if (!data || data.length === 0) {
    throw Object.assign(new Error('No escrow found for this request'), { status: 404 });
  }

  const first = data[0];
  return {
    escrow_id:       first.escrow_id,
    status:          first.status,
    travel_fee:      first.travel_fee,
    inspection_fee:  first.inspection_fee,
    balance_held:    first.balance_held,
    mpesa_reference: first.mpesa_reference,
    entries: data
      .filter(r => r.entry_type != null)
      .map(r => ({
        entry_type:  r.entry_type,
        amount:      r.amount,
        description: r.description,
        payment_ref: r.payment_ref,
        entry_time:  r.entry_time,
      })),
  };
}

// D3 — admin manual release to mechanic
async function releaseEscrow(requestId, amount, description) {
  const escrow = await _getEscrowByRequest(requestId);

  if (!['funded', 'active', 'partially_released'].includes(escrow.status)) {
    throw Object.assign(
      new Error(`Cannot release escrow with status '${escrow.status}'`),
      { status: 409 }
    );
  }

  const releaseAmount = amount ?? escrow.balance_held;
  if (releaseAmount <= 0) {
    throw Object.assign(new Error('Release amount must be greater than zero'), { status: 400 });
  }

  const { error } = await supabase.rpc('release_to_mechanic', {
    p_escrow_id:   escrow.id,
    p_amount:      releaseAmount,
    p_description: description ?? 'Admin manual release',
  });
  if (error) throw error;

  return { request_id: requestId, action: 'released', amount_released: releaseAmount };
}

// D4 — admin refund to customer
async function refundEscrow(requestId, amount, description) {
  const escrow = await _getEscrowByRequest(requestId);

  if (['released', 'refunded'].includes(escrow.status)) {
    throw Object.assign(
      new Error(`Cannot refund escrow with status '${escrow.status}'`),
      { status: 409 }
    );
  }

  const refundAmount = amount ?? escrow.balance_held;
  if (refundAmount <= 0) {
    throw Object.assign(new Error('Refund amount must be greater than zero'), { status: 400 });
  }

  const { error } = await supabase.rpc('refund_to_customer', {
    p_escrow_id:   escrow.id,
    p_amount:      refundAmount,
    p_description: description ?? 'Admin manual refund',
  });
  if (error) throw error;

  return { request_id: requestId, action: 'refunded', amount_refunded: refundAmount };
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION E — Zones
// ══════════════════════════════════════════════════════════════════════════════

// E1 — list zones
async function listZones(query = {}) {
  const { from, to, sortCol, ascending } = parsePagination(query);
  const { data, error, count } = await supabase
    .from('zones')
    .select('id, name, zone_type, mobile_zone_subtype, is_active, created_at', { count: 'exact' })
    .order(sortCol, { ascending })
    .range(from, to);
  if (error) throw error;
  return { data, total: count };
}

const VALID_ZONE_TYPES = ['garage_workshop', 'controlled_mobile', 'highway_emergency', 'restricted'];

// E2 — create zone
// body: { name, zone_type, mobile_zone_subtype?, boundary? }
// boundary is a GeoJSON Polygon geometry object; omit to create without a boundary.
async function createZone({ name, zone_type, mobile_zone_subtype = null, boundary }) {
  if (!name || !zone_type) {
    throw Object.assign(new Error('name and zone_type are required'), { status: 400 });
  }
  if (!VALID_ZONE_TYPES.includes(zone_type)) {
    throw Object.assign(
      new Error(`zone_type must be one of: ${VALID_ZONE_TYPES.join(', ')}`),
      { status: 400 }
    );
  }

  let zoneId;

  if (boundary) {
    // Use the RPC (defined in migration 002) which handles ST_GeomFromGeoJSON
    const { data: id, error } = await supabase.rpc('admin_create_zone', {
      p_name:                name,
      p_zone_type:           zone_type,
      p_mobile_zone_subtype: mobile_zone_subtype,
      p_boundary_geojson:    boundary,
    });
    if (error) throw error;
    zoneId = id;
  } else {
    const { data, error } = await supabase
      .from('zones')
      .insert({ name, zone_type, mobile_zone_subtype })
      .select('id')
      .single();
    if (error) throw error;
    zoneId = data.id;
  }

  const { data: zone, error: fe } = await supabase
    .from('zones')
    .select('id, name, zone_type, mobile_zone_subtype, is_active, created_at')
    .eq('id', zoneId)
    .single();
  if (fe) throw fe;
  return zone;
}

// E3 — update zone fields and/or boundary
async function updateZone(zoneId, patch) {
  const { name, zone_type, mobile_zone_subtype, boundary } = patch;

  if (boundary) {
    const { error } = await supabase.rpc('admin_update_zone', {
      p_id:                  zoneId,
      p_name:                name              ?? null,
      p_zone_type:           zone_type         ?? null,
      p_mobile_zone_subtype: mobile_zone_subtype ?? null,
      p_boundary_geojson:    boundary,
      p_is_active:           null,
    });
    if (error) throw error;
  } else {
    const update = {};
    if (name               !== undefined) update.name                = name;
    if (zone_type          !== undefined) update.zone_type           = zone_type;
    if (mobile_zone_subtype !== undefined) update.mobile_zone_subtype = mobile_zone_subtype;

    if (Object.keys(update).length > 0) {
      const { error } = await supabase.from('zones').update(update).eq('id', zoneId);
      if (error) throw error;
    }
  }

  const { data, error } = await supabase
    .from('zones')
    .select('id, name, zone_type, mobile_zone_subtype, is_active, created_at')
    .eq('id', zoneId)
    .single();
  throwIfNotFound(error, 'Zone');
  return data;
}

// E4 — deactivate zone (soft delete)
async function deactivateZone(zoneId) {
  const { data, error } = await supabase
    .from('zones')
    .update({ is_active: false })
    .eq('id', zoneId)
    .select('id, name, is_active')
    .single();
  throwIfNotFound(error, 'Zone');
  return data;
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION F — Dashboard Summary
// ══════════════════════════════════════════════════════════════════════════════

async function getDashboardSummary() {
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

  const [
    pendingResult,
    activeResult,
    escrowResult,
    newCustomersResult,
    revenueResult,
    topMechanicsResult,
  ] = await Promise.all([
    // pending mechanic applications
    supabase
      .from('mechanics')
      .select('id', { count: 'exact', head: true })
      .eq('application_status', 'pending'),

    // in-flight requests
    supabase
      .from('requests')
      .select('id', { count: 'exact', head: true })
      .in('status', ACTIVE_STATUSES),

    // funds currently held in escrow
    supabase
      .from('job_escrow')
      .select('balance_held')
      .in('status', ['funded', 'active', 'partially_released']),

    // new customer profiles in last 7 days
    supabase
      .from('profiles')
      .select('id', { count: 'exact', head: true })
      .eq('role', 'customer')
      .gte('created_at', sevenDaysAgo),

    // gross revenue last 7 days = sum of all deposit entries
    supabase
      .from('escrow_entries')
      .select('amount')
      .eq('entry_type', 'deposit')
      .gte('created_at', sevenDaysAgo),

    // top 5 mechanics by completed job count
    supabase
      .from('mechanics')
      .select('id, job_count, rating, level, mechanic_type, profiles(name, avatar_url)')
      .eq('application_status', 'approved')
      .order('job_count', { ascending: false })
      .limit(5),
  ]);

  const heldEscrowTotal = (escrowResult.data  || []).reduce((s, r) => s + Number(r.balance_held), 0);
  const revenue7dTotal  = (revenueResult.data  || []).reduce((s, r) => s + Number(r.amount),       0);

  return {
    pending_mechanics:     pendingResult.count        ?? 0,
    active_requests:       activeResult.count         ?? 0,
    held_escrow_total_kes: +heldEscrowTotal.toFixed(2),
    new_customers_7d:      newCustomersResult.count   ?? 0,
    revenue_7d_kes:        +revenue7dTotal.toFixed(2),
    top_mechanics: (topMechanicsResult.data || []).map(m => ({
      id:            m.id,
      name:          m.profiles?.name ?? null,
      job_count:     m.job_count,
      rating:        m.rating,
      level:         m.level,
      mechanic_type: m.mechanic_type,
    })),
  };
}


module.exports = {
  // A — Mechanic Management
  getPendingMechanics,
  getAllMechanics,
  getMechanicById,
  getApprovedMechanics,
  getRejectedMechanics,
  approveMechanic,
  rejectMechanic,
  setMechanicLevel,
  setMechanicTier,
  deactivateMechanic,
  getMechanicStats,
  // B — Customer Management
  listCustomers,
  getCustomerById,
  banCustomer,
  unbanCustomer,
  // C — Request Management
  listRequests,
  getRequestById,
  cancelRequest,
  getRequestStats,
  // D — Payments & Escrow
  listPayments,
  getPaymentByRequest,
  releaseEscrow,
  refundEscrow,
  // E — Zones
  listZones,
  createZone,
  updateZone,
  deactivateZone,
  // F — Dashboard
  getDashboardSummary,
};
