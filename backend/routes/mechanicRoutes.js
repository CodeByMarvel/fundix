const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const {
  getProfile,
  patchAvailability,
  patchStatus,
  patchLocation,
  postUpgradeToGarage,
} = require('../controllers/mechanicController');

// All mechanic routes require auth
router.use(verifyToken);

router.get('/',                    getProfile);
router.patch('/availability',      patchAvailability);
router.patch('/status',            patchStatus);
router.patch('/location',          patchLocation);
router.post('/upgrade-to-garage',  postUpgradeToGarage);

module.exports = router;
