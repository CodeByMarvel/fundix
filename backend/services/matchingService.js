async function findNearbyMechanics(location, radius = 10) {
  // query Firestore for mechanics within radius (km)
  throw new Error('Not implemented');
}

async function assignMechanic(requestId, mechanicId) {
  // update request document with assigned mechanic
  throw new Error('Not implemented');
}

module.exports = { findNearbyMechanics, assignMechanic };
