const express = require('express');
const router = express.Router();
const { getRequests, createRequest } = require('../controllers/requestController');
const { verifyToken } = require('../middleware/authMiddleware');

router.get('/', verifyToken, getRequests);
router.post('/', verifyToken, createRequest);

module.exports = router;
