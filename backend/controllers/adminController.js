const {
  getPendingMechanics,
  getAllMechanics,
  approveMechanic,
  rejectMechanic,
  setMechanicLevel,
} = require('../services/adminService');

async function listPending(req, res, next) {
  try {
    const mechanics = await getPendingMechanics();
    res.json(mechanics);
  } catch (err) {
    next(err);
  }
}

async function listAll(req, res, next) {
  try {
    const mechanics = await getAllMechanics();
    res.json(mechanics);
  } catch (err) {
    next(err);
  }
}

// PATCH /admin/mechanics/:id/approve
// Body: { level?: 1|2|3 }  (defaults to 1)
async function approve(req, res, next) {
  try {
    const { level = 1 } = req.body;
    const result = await approveMechanic(req.params.id, level);
    res.json(result);
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
}

// PATCH /admin/mechanics/:id/reject
async function reject(req, res, next) {
  try {
    const result = await rejectMechanic(req.params.id);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

// PATCH /admin/mechanics/:id/level
// Body: { level: 1|2|3 }
async function updateLevel(req, res, next) {
  try {
    const { level } = req.body;
    if (level === undefined) {
      return res.status(400).json({ error: 'level is required' });
    }
    const result = await setMechanicLevel(req.params.id, level);
    res.json(result);
  } catch (err) {
    if (err.status) return res.status(err.status).json({ error: err.message });
    next(err);
  }
}

module.exports = { listPending, listAll, approve, reject, updateLevel };
