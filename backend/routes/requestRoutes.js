const express = require('express');
const router = express.Router();
const { getRequests, createRequest, completeRequest, disputeRequest, confirmComplete, inspectionComplete } = require('../controllers/requestController');
const { verifyToken } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

router.get('/',                       verifyToken, requireRole('customer'), getRequests);
router.post('/',                      verifyToken, requireRole('customer'), createRequest);
// Both customer and mechanic can mark complete (either party confirmation)
router.patch('/:id/complete',         verifyToken, completeRequest);
router.post('/:id/inspection-complete', verifyToken, requireRole('mechanic'), inspectionComplete);
router.post('/:id/dispute',             verifyToken, requireRole('customer'), disputeRequest);
router.post('/:id/confirm-complete',    verifyToken, requireRole('customer'), confirmComplete);

module.exports = router;
