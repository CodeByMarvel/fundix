function formatDate(date) {
  return new Date(date).toISOString();
}

function formatPhone(phone) {
  const digits = phone.replace(/\D/g, '');
  return digits.startsWith('0') ? `+254${digits.slice(1)}` : `+${digits}`;
}

module.exports = { formatDate, formatPhone };
