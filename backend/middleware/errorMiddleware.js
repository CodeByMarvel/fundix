function errorHandler(err, req, res, next) {
  const status = err.status || 500;
  if (process.env.NODE_ENV !== 'production') console.error(err);
  // Never leak internal error details (DB schema, Supabase messages) to clients in production
  const message = status < 500 ? err.message : 'Internal server error';
  res.status(status).json({ error: message });
}

module.exports = { errorHandler };
