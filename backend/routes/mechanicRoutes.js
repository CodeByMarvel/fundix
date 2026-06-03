const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');
const {
  getProfile,
  patchAvailability,
  patchStatus,
  patchLocation,
  postUpgradeToGarage,
  postApply,
  getJobs,
  postAcceptJob,
} = require('../controllers/mechanicController');

// Any authenticated user can apply to become a mechanic
router.post('/apply', verifyToken, postApply);

// All routes below require a verified mechanic account
router.use(verifyToken, requireRole('mechanic'));

router.get('/',                       getProfile);
router.patch('/availability',         patchAvailability);
router.patch('/status',               patchStatus);
router.patch('/location',             patchLocation);
router.post('/upgrade-to-garage',     postUpgradeToGarage);
router.get('/jobs',                   getJobs);
router.post('/jobs/:id/accept',       postAcceptJob);

module.exports = router;
