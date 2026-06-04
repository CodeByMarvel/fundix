const cron = require('node-cron');
const supabase = require('../firebase/firebaseConfig');
const { b2cPayment, normalisePhone } = require('./mpesaService');

// Buffer in minutes — override via env var (default 2 for dev/testing)
const RELEASE_BUFFER_MINUTES = parseInt(process.env.ESCROW_RELEASE_BUFFER_MINUTES || '2', 10);

// ── Auto-release a single escrow row ─────────────────────────────────────────
async function releaseEscrow(escrow) {
  try {
    if (escrow.balance_held <= 0) {
      console.warn(`[escrow] Skipping release for escrow ${escrow.id}: zero balance`);
      return;
    }
    if (!escrow.mechanic_phone) {
      // Phone was never captured at job acceptance — money is stuck, needs admin intervention
      console.error(
        `[escrow] PAYOUT BLOCKED — escrow ${escrow.id} (request ${escrow.request_id}) ` +
        `has no mechanic phone. KES ${escrow.balance_held} is stuck. ` +
        `Admin must set mechanic phone and manually release via /admin/payments/${escrow.request_id}/release`
      );
      return;
    }

    const phone = normalisePhone(escrow.mechanic_phone);
    await b2cPayment(phone, escrow.balance_held, escrow.request_id, 'Fundix auto-release payout');

    await supabase
      .from('job_escrow')
      .update({ status: 'released', released_at: new Date().toISOString(), released_via: 'auto' })
      .eq('id', escrow.id);

    console.log(`[escrow] Auto-released escrow ${escrow.id} — KES ${escrow.balance_held} → ${phone}`);
  } catch (err) {
    console.error(`[escrow] Auto-release failed for escrow ${escrow.id}:`, err.message);
    // Don't throw — let the cron continue with other escrows
  }
}

// ── Find and release all overdue pending_release escrows ─────────────────────
async function processDueReleases() {
  const { data: escrows, error } = await supabase
    .from('job_escrow')
    .select('id, request_id, mechanic_phone, balance_held')
    .eq('status', 'pending_release')
    .eq('disputed', false)
    .lt('auto_release_at', new Date().toISOString());

  if (error) {
    console.error('[escrow] Failed to query due releases:', error.message);
    return;
  }

  if (!escrows || escrows.length === 0) return;

  console.log(`[escrow] Processing ${escrows.length} due release(s)...`);
  await Promise.all(escrows.map(releaseEscrow));
}

// ── Manual release with B2C payout (called by admin endpoint) ────────────────
async function manualRelease(requestId) {
  const { data: escrow, error } = await supabase
    .from('job_escrow')
    .select('id, mechanic_phone, balance_held, status')
    .eq('request_id', requestId)
    .single();

  if (error || !escrow) throw Object.assign(new Error('Escrow not found'), { status: 404 });

  if (escrow.status === 'released') {
    throw Object.assign(new Error('Already released'), { status: 409 });
  }
  if (escrow.balance_held <= 0) {
    throw Object.assign(new Error('No balance to release'), { status: 400 });
  }

  await releaseEscrow(escrow);
  return { released: true, amount: escrow.balance_held };
}

// ── Start the cron scheduler ──────────────────────────────────────────────────
// Runs every minute — fast enough for a 2-minute buffer without hammering the DB
function startAutoReleaseScheduler() {
  cron.schedule('* * * * *', () => {
    processDueReleases().catch(err =>
      console.error('[escrow cron] Unhandled error:', err.message)
    );
  });
  console.log(`[escrow] Auto-release scheduler started — buffer: ${RELEASE_BUFFER_MINUTES} min`);
}

// ── Helper used by job completion handler ────────────────────────────────────
function getReleaseBufferMinutes() {
  return RELEASE_BUFFER_MINUTES;
}

module.exports = { startAutoReleaseScheduler, manualRelease, getReleaseBufferMinutes };
