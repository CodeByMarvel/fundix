async function loginUser(email, password) {
  // Supabase sign-in is handled client-side (Flutter).
  // This backend validates the JWT sent from the app via verifyToken middleware.
  throw new Error('Use verifyToken middleware — client handles sign-in');
}

module.exports = { loginUser };
