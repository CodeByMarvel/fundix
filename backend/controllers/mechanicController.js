const {
  getMechanicProfile,
  setAvailability,
  setOperatingStatus,
  updateLocation,
  upgradeToGarage,
  submitApplication,
  getAvailableJobs,
  acceptJob,
} = require('../services/mechanicService');

async function getProfile(req, res, next) {
  try {
    const profile = await getMechanicProfile(req.user.uid);
    res.json(profile);
  } catch (err) {
    next(err);
  }
}

// PATCH /mechanics/availability
// Body: { isOnline: boolean, lat?: number, lng?: number }
async function patchAvailability(req, res, next) {
  try {
    const { isOnline, lat, lng } = req.body;
    if (typeof isOnline !== 'boolean') {
      return res.status(400).json({ error: 'isOnline must be a boolean' });
    }
    const position = isOnline ? { lat, lng } : null;
    const result = await setAvailability(req.user.uid, isOnline, position);
    res.json(result);
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
}

// PATCH /mechanics/status
// Body: { operatingStatus: 'open_now' | 'busy' | 'appointment_only' }
async function patchStatus(req, res, next) {
  try {
    const { operatingStatus } = req.body;
    const result = await setOperatingStatus(req.user.uid, operatingStatus);
    res.json(result);
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
}

// PATCH /mechanics/location
// Body: { lat: number, lng: number }
async function patchLocation(req, res, next) {
  try {
    const { lat, lng } = req.body;
    if (typeof lat !== 'number' || typeof lng !== 'number') {
      return res.status(400).json({ error: 'lat and lng must be numbers' });
    }
    const result = await updateLocation(req.user.uid, lat, lng);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

// POST /mechanics/upgrade-to-garage
async function postUpgradeToGarage(req, res, next) {
  try {
    const result = await upgradeToGarage(req.user.uid);
    res.json(result);
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
}

// POST /mechanics/apply  (any authenticated user — role is still 'customer' at this point)
async function postApply(req, res, next) {
  try {
    const result = await submitApplication(req.user.uid, req.body);
    res.status(201).json(result);
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
}

// GET /mechanics/jobs
// Returns all pending requests where the customer has already paid (escrow funded).
async function getJobs(req, res, next) {
  try {
    const jobs = await getAvailableJobs(req.user.uid);
    res.json(jobs);
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
}

// POST /mechanics/jobs/:id/accept
// Mechanic claims a funded request — activates escrow, assigns themselves.
async function postAcceptJob(req, res, next) {
  try {
    const result = await acceptJob(req.user.uid, req.params.id);
    res.json(result);
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
}

module.exports = { getProfile, patchAvailability, patchStatus, patchLocation, postUpgradeToGarage, postApply, getJobs, postAcceptJob };
