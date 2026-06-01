const https = require('https');

const BASE_URL = process.env.MPESA_ENV === 'production'
  ? 'https://api.safaricom.co.ke'
  : 'https://sandbox.safaricom.co.ke';

// ── OAuth token (cached with 55-min TTL) ─────────────────────────────────────
let _tokenCache = null;
let _tokenExpiresAt = 0;

async function getAccessToken() {
  if (_tokenCache && Date.now() < _tokenExpiresAt) return _tokenCache;

  const creds = Buffer.from(
    `${process.env.MPESA_CONSUMER_KEY}:${process.env.MPESA_CONSUMER_SECRET}`
  ).toString('base64');

  const data = await _request(
    `${BASE_URL}/oauth/v1/generate?grant_type=client_credentials`,
    { method: 'GET', headers: { Authorization: `Basic ${creds}` } }
  );

  _tokenCache = data.access_token;
  _tokenExpiresAt = Date.now() + 55 * 60 * 1000; // 55 minutes
  return _tokenCache;
}

// ── STK Push (Lipa Na M-Pesa) ─────────────────────────────────────────────────
// phone: '254712345678' (no +, no leading 0)
// amount: integer KES
// requestId: used as AccountReference and to tie the callback back to the job
async function stkPush(phone, amount, requestId) {
  const token = await getAccessToken();
  const timestamp = _timestamp();
  const password = Buffer.from(
    `${process.env.MPESA_SHORTCODE}${process.env.MPESA_PASSKEY}${timestamp}`
  ).toString('base64');

  return _request(`${BASE_URL}/mpesa/stkpush/v1/processrequest`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      BusinessShortCode: process.env.MPESA_SHORTCODE,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: Math.ceil(amount),
      PartyA: phone,
      PartyB: process.env.MPESA_SHORTCODE,
      PhoneNumber: phone,
      CallBackURL: `${process.env.MPESA_CALLBACK_URL}/payments/mpesa/callback`,
      AccountReference: requestId,
      TransactionDesc: 'Fundix Service Payment',
    }),
  });
}

// ── B2C (Business to Customer — pay mechanic) ─────────────────────────────────
// phone: '254712345678'
// amount: integer KES
async function b2cPayment(phone, amount, requestId, remarks = 'Mechanic payout') {
  const token = await getAccessToken();

  return _request(`${BASE_URL}/mpesa/b2c/v3/paymentrequest`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      OriginatorConversationID: `fundix-${requestId}-${Date.now()}`,
      InitiatorName: process.env.MPESA_B2C_INITIATOR_NAME,
      SecurityCredential: process.env.MPESA_B2C_SECURITY_CREDENTIAL,
      CommandID: 'BusinessPayment',
      Amount: Math.ceil(amount),
      PartyA: process.env.MPESA_SHORTCODE,
      PartyB: phone,
      Remarks: remarks,
      QueueTimeOutURL: `${process.env.MPESA_CALLBACK_URL}/payments/b2c/timeout`,
      ResultURL: `${process.env.MPESA_CALLBACK_URL}/payments/b2c/result`,
      Occasion: requestId,
    }),
  });
}

// ── Normalise a Kenyan phone number to 254XXXXXXXXX ──────────────────────────
function normalisePhone(raw) {
  const digits = String(raw).replace(/\D/g, '');
  if (digits.startsWith('254') && digits.length === 12) return digits;
  if (digits.startsWith('0') && digits.length === 10) return '254' + digits.slice(1);
  if (digits.length === 9) return '254' + digits;
  throw Object.assign(new Error(`Invalid phone number: ${raw}`), { status: 400 });
}

// ── Internal helpers ──────────────────────────────────────────────────────────
function _timestamp() {
  return new Date()
    .toISOString()
    .replace(/[-T:.Z]/g, '')
    .slice(0, 14);
}

function _request(url, options) {
  return new Promise((resolve, reject) => {
    const body = options.body;
    const parsed = new URL(url);
    const reqOptions = {
      hostname: parsed.hostname,
      path: parsed.pathname + parsed.search,
      method: options.method || 'GET',
      headers: options.headers || {},
    };
    if (body) reqOptions.headers['Content-Length'] = Buffer.byteLength(body);

    const req = https.request(reqOptions, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(raw);
          if (res.statusCode >= 400) {
            reject(Object.assign(new Error(parsed.errorMessage || 'M-Pesa error'), {
              status: res.statusCode,
              mpesa: parsed,
            }));
          } else {
            resolve(parsed);
          }
        } catch {
          reject(new Error(`Non-JSON response: ${raw}`));
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

module.exports = { getAccessToken, stkPush, b2cPayment, normalisePhone };
