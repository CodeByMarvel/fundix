const { loginUser } = require('../auth/login');
const { signupUser } = require('../auth/signup');
const { isValidEmail, requireFields } = require('../utils/validators');

const ALLOWED_ROLES = ['customer'];

async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    const result = await loginUser(email, password);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

async function signup(req, res, next) {
  try {
    const { email, password, role } = req.body;

    requireFields(req.body, ['email', 'password']);
    if (!isValidEmail(email)) return res.status(400).json({ error: 'Invalid email address' });
    if (typeof password !== 'string' || password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }

    const safeRole = ALLOWED_ROLES.includes(role) ? role : 'customer';
    const result = await signupUser(email, password, safeRole);
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
}

module.exports = { login, signup };
