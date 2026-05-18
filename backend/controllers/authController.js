const { loginUser } = require('../auth/login');
const { signupUser } = require('../auth/signup');

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
    const result = await signupUser(email, password, role);
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
}

module.exports = { login, signup };
