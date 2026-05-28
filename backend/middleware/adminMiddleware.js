const crypto = require('crypto');

function requireAdmin(req, res, next) {
  // req.user must already be set by verifyToken — admin routes chain both
  if (!req.user) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const secret = req.headers['x-admin-secret'];
  const expected = process.env.ADMIN_SECRET;

  if (!secret || !expected) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  // Timing-safe comparison prevents brute-force timing attacks
  const secretBuf = Buffer.from(secret);
  const expectedBuf = Buffer.from(expected);
  const lengthMatch = secretBuf.length === expectedBuf.length;
  const safeLen = Math.max(secretBuf.length, expectedBuf.length);
  const a = Buffer.concat([secretBuf, Buffer.alloc(safeLen - secretBuf.length)]);
  const b = Buffer.concat([expectedBuf, Buffer.alloc(safeLen - expectedBuf.length)]);

  if (!lengthMatch || !crypto.timingSafeEqual(a, b)) {
    return res.status(403).json({ error: 'Admin access required' });
  }

  next();
}

module.exports = { requireAdmin };
