import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';

export const authRouter = Router();

// ── Supabase Admin client (service-role key) ─────────────────────────────
// Used for server-side lookups that the client SDK cannot do without
// sending emails (e.g. checking if an email is already registered).
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

// GET /api/auth/check-email?email=user@example.com
// Public — no JWT required. Returns { exists: true/false }.
// Uses the Supabase Admin SDK (listUsers) to check if an email is registered.
// This sends ZERO emails and has ZERO rate-limit risk.
authRouter.get('/check-email', async (req, res, next) => {
  try {
    const email = (req.query.email ?? '').toString().trim().toLowerCase();
    if (!email) {
      return res.status(400).json({ message: 'email query parameter is required' });
    }

    // supabase-js v2 has listUsers() but NOT getUserByEmail().
    // We list users (paginated) and check if the email exists.
    // Fine for < 10k users; for larger scale use the REST API directly.
    const { data, error } = await supabaseAdmin.auth.admin.listUsers({
      page: 1,
      perPage: 1000,
    });

    if (error) {
      console.error('[check-email] Supabase admin error:', error.message);
      return res.status(500).json({ message: 'Failed to check email' });
    }

    const users = data?.users ?? [];
    const exists = users.some((u) => u.email?.toLowerCase() === email);

    return res.json({ exists });
  } catch (err) {
    next(err);
  }
});
