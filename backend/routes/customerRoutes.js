const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');
const { getProfile, patchProfile, listVehicles, createVehicle, removeVehicle } = require('../controllers/customerController');

router.use(verifyToken, requireRole('customer'));

router.get('/profile',          getProfile);
router.patch('/profile',        patchProfile);
router.get('/vehicles',         listVehicles);
router.post('/vehicles',        createVehicle);
router.delete('/vehicles/:id',  removeVehicle);

module.exports = router;
