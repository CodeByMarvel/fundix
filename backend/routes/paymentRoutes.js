const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const {
  initiatePayment,
  mpesaCallback,
  b2cResult,
  b2cTimeout,
} = require('../controllers/paymentController');

// Customer-initiated STK push
router.post('/stkpush', verifyToken, initiatePayment);

// Safaricom webhook callbacks — no auth, must always respond 200
router.post('/mpesa/callback', mpesaCallback);
router.post('/b2c/result',     b2cResult);
router.post('/b2c/timeout',    b2cTimeout);

module.exports = router;
