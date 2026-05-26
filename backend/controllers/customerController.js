const {
  getCustomerProfile,
  updateCustomerProfile,
  getVehicles,
  addVehicle,
  deleteVehicle,
} = require('../services/customerService');

async function getProfile(req, res, next) {
  try {
    const profile = await getCustomerProfile(req.user.uid);
    res.json(profile);
  } catch (err) {
    next(err);
  }
}

// PATCH /customers/profile
// Body: { name?: string, phone?: string }
async function patchProfile(req, res, next) {
  try {
    const { name, phone } = req.body;
    const result = await updateCustomerProfile(req.user.uid, { name, phone });
    res.json(result);
  } catch (err) {
    next(err);
  }
}

// GET /customers/vehicles
async function listVehicles(req, res, next) {
  try {
    const vehicles = await getVehicles(req.user.uid);
    res.json(vehicles);
  } catch (err) {
    next(err);
  }
}

// POST /customers/vehicles
// Body: { brand, model, year, fuel_type, transmission, body_type, engine?, plate_number?, nickname? }
async function createVehicle(req, res, next) {
  try {
    const { brand, model, year, fuel_type, transmission, body_type, engine, plate_number, nickname } = req.body;
    if (!brand || !model || !year) {
      return res.status(400).json({ error: 'brand, model, and year are required' });
    }
    const vehicle = await addVehicle(req.user.uid, {
      brand,
      model,
      year: Number(year),
      fuel_type: fuel_type ?? 'Petrol',
      transmission: transmission ?? 'Auto',
      body_type: body_type ?? 'Sedan',
      engine,
      plate_number,
      nickname,
    });
    res.status(201).json(vehicle);
  } catch (err) {
    next(err);
  }
}

// DELETE /customers/vehicles/:id
async function removeVehicle(req, res, next) {
  try {
    await deleteVehicle(req.user.uid, req.params.id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { getProfile, patchProfile, listVehicles, createVehicle, removeVehicle };
