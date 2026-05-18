const { runDiagnosis } = require('../services/requestService');

async function diagnose(req, res, next) {
  try {
    const { symptoms, vehicleInfo } = req.body;
    const result = await runDiagnosis(symptoms, vehicleInfo);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

module.exports = { diagnose };
