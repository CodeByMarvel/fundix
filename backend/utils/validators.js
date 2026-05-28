function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email);
}

// Returns null if strong enough, or a descriptive error string.
function passwordStrengthError(password) {
  if (typeof password !== 'string') return 'Password is required';
  if (password.length < 8) return 'Password must be at least 8 characters';
  if (!/[A-Z]/.test(password)) return 'Password must contain at least one uppercase letter';
  if (!/[a-z]/.test(password)) return 'Password must contain at least one lowercase letter';
  if (!/[0-9]/.test(password)) return 'Password must contain at least one number';
  return null;
}

function isValidPhone(phone) {
  return /^(\+254|0)[17]\d{8}$/.test(phone);
}

function requireFields(obj, fields) {
  const missing = fields.filter((f) => !obj[f]);
  if (missing.length) throw Object.assign(new Error(`Missing: ${missing.join(', ')}`), { status: 400 });
}

module.exports = { isValidEmail, isValidPhone, requireFields, passwordStrengthError };
