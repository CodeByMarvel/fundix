async function estimatePrice(jobType, distance) {
  // calculate base price + distance fee
  throw new Error('Not implemented');
}

async function processPayment(requestId, amount) {
  // integrate M-Pesa or payment gateway here
  throw new Error('Not implemented');
}

module.exports = { estimatePrice, processPayment };
