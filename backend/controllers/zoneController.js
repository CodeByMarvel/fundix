const { classifyLocation } = require('../services/zoneService');

// POST /zones/classify
// Body: { lat: number, lng: number, declaredType?: string }
async function classify(req, res, next) {
  try {
    const { lat, lng, declaredType } = req.body;

    if (typeof lat !== 'number' || typeof lng !== 'number') {
      return res.status(400).json({ error: 'lat and lng must be numbers' });
    }

    const result = await classifyLocation(lat, lng, declaredType);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

module.exports = { classify };
