const supabase = require('../firebase/firebaseConfig');

async function signupUser(email, password, role = 'customer') {
  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: false, // user must verify their email before signing in
  });
  if (error) throw error;

  const uid = data.user.id;
  await supabase.from('users').insert({ id: uid, email, role, created_at: new Date() });
  return { uid, email, role };
}

module.exports = { signupUser };
