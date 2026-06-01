const { stkPush, b2cPayment, normalisePhone } = require('../services/mpesaService');
const supabase = require('../firebase/firebaseConfig');

// POST /payments/stkpush
// Body: { requestId, phone }
// Initiates M-Pesa STK push for a job request. Creates the escrow row first if missing.
async function initiatePayment(req, res, next) {
  try {
    const { requestId, phone } = req.body;
    if (!requestId || !phone) {
      return res.status(400).json({ error: 'requestId and phone are required' });
    }

    const normPhone = normalisePhone(phone);

    // Fetch request to get the amount due
    const { data: request, error: reqErr } = await supabase
      .from('requests')
      .select('id, customer_id, call_out_fee, inspection_fee')
      .eq('id', requestId)
      .single();
    if (reqErr || !request) return res.status(404).json({ error: 'Request not found' });

    // Must be the customer who owns the request
    if (request.customer_id !== req.user.uid) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const travelFee     = Number(request.call_out_fee    || 0);
    const inspectionFee = Number(request.inspection_fee  || 0);
    const totalAmount   = travelFee + inspectionFee;

    if (totalAmount <= 0) {
      return res.status(400).json({ error: 'No amount to collect for this request' });
    }

    // Create escrow row (ignore conflict if it already exists)
    await supabase.rpc('initialise_escrow', {
      p_request_id:     requestId,
      p_customer_id:    request.customer_id,
      p_travel_fee:     travelFee,
      p_inspection_fee: inspectionFee,
    });

    const mpesaResponse = await stkPush(normPhone, totalAmount, requestId);

    res.json({
      message: 'Payment prompt sent to your phone',
      checkoutRequestId: mpesaResponse.CheckoutRequestID,
      amount: totalAmount,
    });
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
}

// POST /payments/mpesa/callback  (called by Safaricom, no auth)
// Safaricom posts the STK push result here
async function mpesaCallback(req, res) {
  try {
    const body = req.body?.Body?.stkCallback;
    if (!body) return res.json({ ResultCode: 0, ResultDesc: 'Accepted' });

    const resultCode  = body.ResultCode;
    const requestId   = body.AccountReference; // we set this to the requestId in stkPush
    const mpesaRef    = body.CallbackMetadata?.Item?.find(i => i.Name === 'MpesaReceiptNumber')?.Value;
    const amount      = body.CallbackMetadata?.Item?.find(i => i.Name === 'Amount')?.Value;

    if (resultCode === 0 && requestId && mpesaRef) {
      // Payment successful — fund the escrow
      await supabase.rpc('fund_escrow', {
        p_request_id: requestId,
        p_amount:     amount,
        p_mpesa_ref:  mpesaRef,
      });
    }
    // Always respond 200 to Safaricom or they'll retry
    res.json({ ResultCode: 0, ResultDesc: 'Accepted' });
  } catch {
    res.json({ ResultCode: 0, ResultDesc: 'Accepted' });
  }
}

// POST /payments/b2c/result  (called by Safaricom, no auth)
async function b2cResult(req, res) {
  try {
    const result = req.body?.Result;
    if (result?.ResultCode === 0) {
      const requestId = result.ReferenceData?.ReferenceItem?.Value; // Occasion field we set
      const transRef  = result.ResultParameters?.ResultParameter?.find(p => p.Key === 'TransactionReceipt')?.Value;
      if (requestId) {
        // Fetch escrow and mark as released with the M-Pesa reference
        const { data: escrow } = await supabase
          .from('job_escrow')
          .select('id, balance_held')
          .eq('request_id', requestId)
          .single();
        if (escrow) {
          await supabase.rpc('release_to_mechanic', {
            p_escrow_id:   escrow.id,
            p_amount:      escrow.balance_held,
            p_description: `B2C payout ref: ${transRef || 'unknown'}`,
          });
        }
      }
    }
    res.json({ ResultCode: 0, ResultDesc: 'Accepted' });
  } catch {
    res.json({ ResultCode: 0, ResultDesc: 'Accepted' });
  }
}

// POST /payments/b2c/timeout  (called by Safaricom on timeout, no auth)
async function b2cTimeout(req, res) {
  res.json({ ResultCode: 0, ResultDesc: 'Accepted' });
}

// POST /admin/payments/:requestId/release  (already in adminRoutes — this is the internal helper)
// Called from adminController when admin manually releases escrow; triggers B2C payout
async function triggerMechanicPayout(requestId) {
  const { data: escrow } = await supabase
    .from('job_escrow')
    .select('id, mechanic_id, mechanic_phone, balance_held')
    .eq('request_id', requestId)
    .single();

  if (!escrow || !escrow.mechanic_phone || escrow.balance_held <= 0) return;

  await b2cPayment(
    normalisePhone(escrow.mechanic_phone),
    escrow.balance_held,
    requestId,
    'Fundix job payout',
  );
}

module.exports = { initiatePayment, mpesaCallback, b2cResult, b2cTimeout, triggerMechanicPayout };
