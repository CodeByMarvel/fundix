const {
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
} = require('../services/adminService');

// ── Shared response helper ────────────────────────────────────────────────────
// Handles the two error shapes we throw: { status, message } and raw Supabase errors.
function handle(res, next, promise) {
  return promise
    .then(data => res.json(data))
    .catch(err => {
      if (err.status) return res.status(err.status).json({ error: err.message });
      next(err);
    });
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION A — Mechanic Management
// ══════════════════════════════════════════════════════════════════════════════

async function listPending(req, res, next) {
  return handle(res, next, getPendingMechanics());
}

async function listAll(req, res, next) {
  return handle(res, next, getAllMechanics(req.query));
}

async function getMechanic(req, res, next) {
  return handle(res, next, getMechanicById(req.params.id));
}

async function listApproved(req, res, next) {
  return handle(res, next, getApprovedMechanics(req.query));
}

async function listRejected(req, res, next) {
  return handle(res, next, getRejectedMechanics(req.query));
}

async function approve(req, res, next) {
  const { level = 1, tier } = req.body;
  return handle(res, next, approveMechanic(req.params.id, level, tier));
}

async function reject(req, res, next) {
  const { reason } = req.body;
  return handle(res, next, rejectMechanic(req.params.id, reason));
}

async function updateLevel(req, res, next) {
  const { level } = req.body;
  if (level === undefined) return res.status(400).json({ error: 'level is required' });
  return handle(res, next, setMechanicLevel(req.params.id, level));
}

async function updateTier(req, res, next) {
  const { tier } = req.body;
  if (tier === undefined) return res.status(400).json({ error: 'tier is required (1 or 2)' });
  return handle(res, next, setMechanicTier(req.params.id, tier));
}

async function deleteMechanic(req, res, next) {
  return handle(res, next, deactivateMechanic(req.params.id));
}

async function mechanicStats(req, res, next) {
  return handle(res, next, getMechanicStats());
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION B — Customer Management
// ══════════════════════════════════════════════════════════════════════════════

async function listAllCustomers(req, res, next) {
  return handle(res, next, listCustomers(req.query));
}

async function getCustomer(req, res, next) {
  return handle(res, next, getCustomerById(req.params.id));
}

async function banCustomerHandler(req, res, next) {
  const { reason } = req.body;
  if (!reason) return res.status(400).json({ error: 'reason is required' });
  return handle(res, next, banCustomer(req.params.id, reason));
}

async function unbanCustomerHandler(req, res, next) {
  return handle(res, next, unbanCustomer(req.params.id));
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION C — Request / Job Management
// ══════════════════════════════════════════════════════════════════════════════

async function listAllRequests(req, res, next) {
  return handle(res, next, listRequests(req.query));
}

async function getRequest(req, res, next) {
  return handle(res, next, getRequestById(req.params.id));
}

async function cancelRequestHandler(req, res, next) {
  return handle(res, next, cancelRequest(req.params.id));
}

async function requestStats(req, res, next) {
  return handle(res, next, getRequestStats());
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION D — Payments & Escrow
// ══════════════════════════════════════════════════════════════════════════════

async function listAllPayments(req, res, next) {
  return handle(res, next, listPayments(req.query));
}

async function getPayment(req, res, next) {
  return handle(res, next, getPaymentByRequest(req.params.requestId));
}

async function releasePayment(req, res, next) {
  const { amount, description } = req.body;
  return handle(res, next, releaseEscrow(req.params.requestId, amount, description));
}

async function refundPayment(req, res, next) {
  const { amount, description } = req.body;
  return handle(res, next, refundEscrow(req.params.requestId, amount, description));
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION E — Zones
// ══════════════════════════════════════════════════════════════════════════════

async function listAllZones(req, res, next) {
  return handle(res, next, listZones(req.query));
}

async function createZoneHandler(req, res, next) {
  return createZone(req.body)
    .then(zone => res.status(201).json(zone))
    .catch(err => {
      if (err.status) return res.status(err.status).json({ error: err.message });
      next(err);
    });
}

async function updateZoneHandler(req, res, next) {
  return handle(res, next, updateZone(req.params.id, req.body));
}

async function deleteZoneHandler(req, res, next) {
  return handle(res, next, deactivateZone(req.params.id));
}


// ══════════════════════════════════════════════════════════════════════════════
// SECTION F — Dashboard
// ══════════════════════════════════════════════════════════════════════════════

async function dashboard(req, res, next) {
  return handle(res, next, getDashboardSummary());
}


module.exports = {
  // A
  listPending, listAll, getMechanic, listApproved, listRejected,
  approve, reject, updateLevel, updateTier, deleteMechanic, mechanicStats,
  // B
  listAllCustomers, getCustomer, banCustomerHandler, unbanCustomerHandler,
  // C
  listAllRequests, getRequest, cancelRequestHandler, requestStats,
  // D
  listAllPayments, getPayment, releasePayment, refundPayment,
  // E
  listAllZones, createZoneHandler, updateZoneHandler, deleteZoneHandler,
  // F
  dashboard,
};
