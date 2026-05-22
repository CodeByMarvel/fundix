const supabase = require('../firebase/firebaseConfig');

async function verifyIdToken(idToken) {
  const { data, error } = await supabase.auth.getUser(idToken);
  if (error) throw error;

  const uid = data.user.id;
  const { data: userRow } = await supabase.from('profiles').select('role').eq('id', uid).single();
  return { uid, email: data.user.email, role: userRow?.role };
}

module.exports = { verifyIdToken };
