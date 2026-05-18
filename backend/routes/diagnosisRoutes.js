const express = require('express');
const router = express.Router();
const { diagnose } = require('../controllers/diagnosisController');
const { verifyToken } = require('../middleware/authMiddleware');

router.post('/', verifyToken, diagnose);

module.exports = router;
