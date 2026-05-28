const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const { login, signup } = require('../controllers/authController');

// 5 attempts per 15 min — brute-force protection for login
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many login attempts. Please wait 15 minutes and try again.' },
});

// 10 signups per hour per IP — blocks account-farming bots
const signupLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many accounts created from this IP. Please try again later.' },
});

router.post('/login', loginLimiter, login);
router.post('/signup', signupLimiter, signup);

module.exports = router;
