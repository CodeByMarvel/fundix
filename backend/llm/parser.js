function parseDiagnosisResponse(raw) {
  try {
    const json = raw.match(/\{[\s\S]*\}/)?.[0];
    return JSON.parse(json);
  } catch {
    return { raw, parsed: false };
  }
}

module.exports = { parseDiagnosisResponse };
