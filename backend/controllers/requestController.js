const { createServiceRequest, fetchRequests } = require('../services/requestService');
const supabase = require('../firebase/firebaseConfig');
const { getReleaseBufferMinutes } = require('../services/escrowReleaseService');

async function getRequests(req, res, next) {
  try {
    const requests = await fetchRequests(req.user.uid);
    res.json(requests);
  } catch (err) {
    next(err);
  }
}

async function createRequest(req, res, next) {
  try {
    const request = await createServiceRequest(req.user.uid, req.body);
    res.status(201).json(request);
  } catch (err) {
    next(err);
  }
}

// PATCH /requests/:id/complete
// Either party (customer or mechanic) can mark the job done.
// Starts the auto-release buffer countdown on the escrow.
async function completeRequest(req, res, next) {
  try {
    const { id } = req.params;
    const bufferMinutes = getReleaseBufferMinutes();

    const { error } = await supabase.rpc('complete_job', {
      p_request_id:            id,
      p_completed_by:          req.body.completedBy || 'customer',
      p_release_after_minutes: bufferMinutes,
    });
    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({
      message: `Job marked complete. Payment releases automatically in ${bufferMinutes} minute(s) unless disputed.`,
      autoReleaseMinutes: bufferMinutes,
    });
  } catch (err) {
    next(err);
  }
}

// POST /requests/:id/dispute
// Customer raises a dispute within the buffer window — pauses auto-release.
async function disputeRequest(req, res, next) {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    if (!reason) return res.status(400).json({ error: 'reason is required' });

    const { error } = await supabase.rpc('dispute_job', {
      p_request_id: id,
      p_reason:     reason,
    });
    if (error) return res.status(400).json({ error: error.message });

    res.json({ message: 'Dispute raised. Our team will review within 24 hours.' });
  } catch (err) {
    next(err);
  }
}

// POST /requests/:id/confirm-complete
// Customer confirms early — skips the buffer and releases immediately.
async function confirmComplete(req, res, next) {
  try {
    const { id } = req.params;

    const { error } = await supabase.rpc('confirm_job_complete', {
      p_request_id: id,
    });
    if (error) return res.status(400).json({ error: error.message });

    res.json({ message: 'Confirmed. Payment is being released to your mechanic.' });
  } catch (err) {
    next(err);
  }
}

module.exports = { getRequests, createRequest, completeRequest, disputeRequest, confirmComplete };
