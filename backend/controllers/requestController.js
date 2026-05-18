const { createServiceRequest, fetchRequests } = require('../services/requestService');

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

module.exports = { getRequests, createRequest };
