function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidPhone(phone) {
  return /^(\+254|0)[17]\d{8}$/.test(phone);
}

function requireFields(obj, fields) {
  const missing = fields.filter((f) => !obj[f]);
  if (missing.length) throw Object.assign(new Error(`Missing: ${missing.join(', ')}`), { status: 400 });
}

module.exports = { isValidEmail, isValidPhone, requireFields };
