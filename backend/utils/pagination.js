/**
 * Parses ?page, ?limit, ?sort, ?order from a query string.
 * Returns Supabase range offsets plus sort options.
 *
 * Defaults: page=1, limit=20, sort=created_at, order=desc
 * Limit is capped at 100 to prevent runaway queries.
 */
function parsePagination(query = {}) {
  const page      = Math.max(1, parseInt(query.page)  || 1);
  const limit     = Math.min(100, Math.max(1, parseInt(query.limit) || 20));
  const from      = (page - 1) * limit;
  const to        = from + limit - 1;
  const sortCol   = query.sort  || 'created_at';
  const ascending = (query.order || 'desc').toLowerCase() === 'asc';
  return { page, limit, from, to, sortCol, ascending };
}

module.exports = { parsePagination };
