const supabase = require('../firebase/firebaseConfig');
const { askLLM } = require('../llm/openaiService');
const { buildDiagnosisPrompt } = require('../llm/prompts');
const { parseDiagnosisResponse } = require('../llm/parser');

async function createServiceRequest(uid, data) {
  // Whitelist allowed fields — never spread raw req.body into the DB
  const { vehicleInfo, symptoms, location } = data;
  const { data: row, error } = await supabase
    .from('requests')
    .insert({ customer_id: uid, vehicle_info: vehicleInfo, symptoms, location, status: 'pending', created_at: new Date() })
    .select()
    .single();
  if (error) throw error;
  return { id: row.id, vehicleInfo, symptoms, location };
}

async function fetchRequests(uid) {
  const { data, error } = await supabase
    .from('requests')
    .select('*')
    .eq('customer_id', uid)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}

async function runDiagnosis(symptoms, vehicleInfo) {
  const prompt = buildDiagnosisPrompt(symptoms, vehicleInfo);
  const raw = await askLLM(prompt);
  return parseDiagnosisResponse(raw);
}

module.exports = { createServiceRequest, fetchRequests, runDiagnosis };
