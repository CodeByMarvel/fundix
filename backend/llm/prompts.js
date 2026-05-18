function sanitize(str) {
  // Strip characters commonly used for prompt injection
  return String(str).replace(/[`<>]/g, '').trim();
}

function buildDiagnosisPrompt(symptoms, vehicleInfo) {
  const make = sanitize(vehicleInfo.make);
  const model = sanitize(vehicleInfo.model);
  const year = sanitize(vehicleInfo.year);
  const safeSymptoms = sanitize(symptoms);

  return `You are a professional auto mechanic assistant for Fundix, a vehicle repair platform in Nairobi.

Vehicle: ${make} ${model} (${year})
Reported symptoms: ${safeSymptoms}

Provide a concise diagnosis with:
1. Most likely cause
2. Urgency level (low / medium / high)
3. Recommended service
4. Estimated repair time

Respond in JSON format only. Do not include any text outside the JSON object.`;
}

module.exports = { buildDiagnosisPrompt };
