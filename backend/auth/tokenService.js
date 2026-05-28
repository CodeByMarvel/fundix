const supabase = require('../firebase/firebaseConfig');

async function verifyIdToken(idToken) {
  const { data, error } = await supabase.auth.getUser(idToken);
  if (error) throw error;

  const uid = data.user.id;
  const meta = data.user.user_metadata ?? {};

  // maybeSingle() returns null instead of throwing when the row doesn't exist.
  // This handles new users whose profile trigger hasn't fired yet — we fall back
  // to the role stored in their JWT metadata rather than returning 401.
  const { data: userRow } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', uid)
    .maybeSingle();

  const role = userRow?.role ?? meta.role ?? 'customer';
  return { uid, email: data.user.email, role, name: meta.name ?? null };
}

module.exports = { verifyIdToken };
