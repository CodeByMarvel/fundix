const express = require('express');
const router = express.Router();
const { getRequests, createRequest } = require('../controllers/requestController');
const { verifyToken } = require('../middleware/authMiddleware');
const { requireRole } = require('../middleware/roleMiddleware');

router.get('/', verifyToken, requireRole('customer'), getRequests);
router.post('/', verifyToken, requireRole('customer'), createRequest);

module.exports = router;
