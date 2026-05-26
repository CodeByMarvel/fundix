const supabase = require('../firebase/firebaseConfig');

async function getPendingMechanics() {
  const { data, error } = await supabase
    .from('mechanics')
    .select('*, profiles(name, phone, avatar_url)')
    .eq('application_status', 'pending')
    .order('updated_at', { ascending: false });
  if (error) throw error;
  return data;
}

async function getAllMechanics() {
  const { data, error } = await supabase
    .from('mechanics')
    .select('*, profiles(name, phone, avatar_url)')
    .order('updated_at', { ascending: false });
  if (error) throw error;
  return data;
}

async function approveMechanic(mechanicId, level = 1) {
  if (level < 1 || level > 3) {
    throw Object.assign(new Error('Level must be between 1 and 3'), { status: 400 });
  }
  const { data, error } = await supabase
    .from('mechanics')
    .update({ application_status: 'approved', level })
    .eq('id', mechanicId)
    .select('id, application_status, level')
    .single();
  if (error) throw error;
  return data;
}

async function rejectMechanic(mechanicId) {
  const { data, error } = await supabase
    .from('mechanics')
    .update({ application_status: 'rejected' })
    .eq('id', mechanicId)
    .select('id, application_status')
    .single();
  if (error) throw error;
  return data;
}

async function setMechanicLevel(mechanicId, level) {
  if (level < 1 || level > 3) {
    throw Object.assign(new Error('Level must be between 1 and 3'), { status: 400 });
  }
  const { data, error } = await supabase
    .from('mechanics')
    .update({ level })
    .eq('id', mechanicId)
    .select('id, level, application_status')
    .single();
  if (error) throw error;
  return data;
}

module.exports = {
  getPendingMechanics,
  getAllMechanics,
  approveMechanic,
  rejectMechanic,
  setMechanicLevel,
};
