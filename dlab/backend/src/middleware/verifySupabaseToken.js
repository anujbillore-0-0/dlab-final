import { createClient } from '@supabase/supabase-js';

const supabaseUrl  = process.env.SUPABASE_URL;
const supabaseKey  = process.env.SUPABASE_SERVICE_ROLE_KEY; // service-role key for server-side ops

if (!supabaseUrl || !supabaseKey) {
  throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars');
}

const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

/**
 * Verifies a Supabase JWT from `Authorization: Bearer <token>`.
 * Attaches the decoded user as `req.supabaseUser`.
 */
export async function verifySupabaseToken(req, res, next) {
  const header = req.headers.authorization;
  const token  = header?.startsWith('Bearer ') ? header.slice('Bearer '.length) : null;

  if (!token) return res.status(401).json({ message: 'Unauthorized' });

  try {
    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data?.user) {
      return res.status(401).json({ message: 'Invalid or expired token' });
    }

    req.supabaseUser = data.user;
    return next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid token' });
  }
}
