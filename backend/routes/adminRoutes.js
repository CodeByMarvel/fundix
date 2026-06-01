const express = require('express');
const router  = express.Router();

const { verifyToken }  = require('../middleware/authMiddleware');
const { requireAdmin } = require('../middleware/adminMiddleware');

const {
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
} = require('../controllers/adminController');

// Every admin route requires a valid Supabase JWT + the x-admin-secret header.
router.use(verifyToken, requireAdmin);

// ── F — Dashboard ─────────────────────────────────────────────────────────────
router.get('/dashboard', dashboard);

// ── A — Mechanic Management ───────────────────────────────────────────────────
// Static sub-paths (/pending, /approved, /rejected, /stats) MUST be registered
// before /:id so Express does not treat those words as mechanic IDs.
router.get('/mechanics/pending',           listPending);
router.get('/mechanics/approved',          listApproved);
router.get('/mechanics/rejected',          listRejected);
router.get('/mechanics/stats',             mechanicStats);
router.get('/mechanics',                   listAll);
router.get('/mechanics/:id',               getMechanic);

router.patch('/mechanics/:id/approve',     approve);
router.patch('/mechanics/:id/reject',      reject);
router.patch('/mechanics/:id/level',       updateLevel);
router.patch('/mechanics/:id/tier',        updateTier);
router.delete('/mechanics/:id',            deleteMechanic);

// ── B — Customer Management ───────────────────────────────────────────────────
router.get('/customers',                   listAllCustomers);
router.get('/customers/:id',               getCustomer);
router.patch('/customers/:id/ban',         banCustomerHandler);
router.patch('/customers/:id/unban',       unbanCustomerHandler);

// ── C — Request / Job Management ─────────────────────────────────────────────
// /requests/stats must come before /requests/:id
router.get('/requests/stats',              requestStats);
router.get('/requests',                    listAllRequests);
router.get('/requests/:id',                getRequest);
router.patch('/requests/:id/cancel',       cancelRequestHandler);

// ── D — Payments & Escrow ─────────────────────────────────────────────────────
router.get('/payments',                          listAllPayments);
router.get('/payments/:requestId',               getPayment);
router.patch('/payments/:requestId/release',     releasePayment);
router.patch('/payments/:requestId/refund',      refundPayment);

// ── E — Zones ─────────────────────────────────────────────────────────────────
router.get('/zones',                       listAllZones);
router.post('/zones',                      createZoneHandler);
router.patch('/zones/:id',                 updateZoneHandler);
router.delete('/zones/:id',                deleteZoneHandler);

module.exports = router;
