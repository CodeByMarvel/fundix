const { runDiagnosis } = require('../services/requestService');

const MAX_SYMPTOMS_LEN = 500;
const MAX_FIELD_LEN = 100;

async function diagnose(req, res, next) {
  try {
    const { symptoms, vehicleInfo } = req.body;

    if (!symptoms || typeof symptoms !== 'string') {
      return res.status(400).json({ error: 'symptoms is required' });
    }
    if (!vehicleInfo || typeof vehicleInfo !== 'object') {
      return res.status(400).json({ error: 'vehicleInfo is required' });
    }
    const { make, model, year } = vehicleInfo;
    if (!make || !model || !year) {
      return res.status(400).json({ error: 'vehicleInfo must include make, model, and year' });
    }

    const safeSymptoms = String(symptoms).slice(0, MAX_SYMPTOMS_LEN);
    const safeVehicle = {
      make: String(make).slice(0, MAX_FIELD_LEN),
      model: String(model).slice(0, MAX_FIELD_LEN),
      year: String(year).slice(0, MAX_FIELD_LEN),
    };

    const result = await runDiagnosis(safeSymptoms, safeVehicle);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

module.exports = { diagnose };
