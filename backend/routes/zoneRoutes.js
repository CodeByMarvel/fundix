const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const { classify } = require('../controllers/zoneController');

// Zone classification requires auth so anonymous clients can't probe boundaries
router.post('/classify', verifyToken, classify);

module.exports = router;
