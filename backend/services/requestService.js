const { db } = require('../firebase/firestoreService');
const { askLLM } = require('../llm/openaiService');
const { buildDiagnosisPrompt } = require('../llm/prompts');
const { parseDiagnosisResponse } = require('../llm/parser');

async function createServiceRequest(uid, data) {
  const ref = await db.collection('requests').add({
    customerId: uid,
    ...data,
    status: 'pending',
    createdAt: new Date(),
  });
  return { id: ref.id, ...data };
}

async function fetchRequests(uid) {
  const snapshot = await db
    .collection('requests')
    .where('customerId', '==', uid)
    .orderBy('createdAt', 'desc')
    .get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

async function runDiagnosis(symptoms, vehicleInfo) {
  const prompt = buildDiagnosisPrompt(symptoms, vehicleInfo);
  const raw = await askLLM(prompt);
  return parseDiagnosisResponse(raw);
}

module.exports = { createServiceRequest, fetchRequests, runDiagnosis };
