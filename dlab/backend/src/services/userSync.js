import { pool } from '../db/pool.js';

// Columns matching updated users table:
//   id UUID, supabase_uid, email, name, phone, avatar,
//   auth_provider (enum: 'email'|'google'),
//   is_active, is_blocked, is_deleted, last_login_at, created_at, updated_at

const RETURNING_COLS = `
  id, supabase_uid, email, name, phone, avatar,
  auth_provider::text AS auth_provider,
  is_active, is_blocked, last_login_at, created_at, updated_at
`;

/**
 * Upserts a user row using Supabase UID as the unique key.
 * Called after successful sign-in / OTP verification.
 */
export async function upsertUserFromSupabase({ supabaseUser, profile }) {
  const supabaseUid = supabaseUser.id;
  const email       = supabaseUser.email ?? null;

  if (!email) {
    throw new Error('Supabase token does not contain email');
  }

  const rawProvider  = profile.provider ?? supabaseUser.app_metadata?.provider ?? 'email';
  const authProvider = rawProvider.includes('google') ? 'google' : 'email';

  const name   = profile.fullName ?? supabaseUser.user_metadata?.full_name   ?? null;
  const avatar = profile.avatarUrl ?? supabaseUser.user_metadata?.avatar_url ?? null;
  const phone  = profile.phone ?? null;

  const client = await pool.connect();
  try {
    const sql = `
      INSERT INTO users (
        supabase_uid, email, name, phone, avatar,
        auth_provider, last_login_at, updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6::auth_provider_enum, NOW(), NOW())
      ON CONFLICT (supabase_uid)
      DO UPDATE SET
        email         = EXCLUDED.email,
        name          = COALESCE(EXCLUDED.name,   users.name),
        phone         = COALESCE(EXCLUDED.phone,  users.phone),
        avatar        = COALESCE(EXCLUDED.avatar, users.avatar),
        auth_provider = EXCLUDED.auth_provider,
        last_login_at = NOW(),
        updated_at    = NOW()
      RETURNING ${RETURNING_COLS};
    `;
    const result = await client.query(sql, [supabaseUid, email, name, phone, avatar, authProvider]);
    return result.rows[0];
  } finally {
    client.release();
  }
}

/**
 * Fetches a user row from PostgreSQL by Supabase UID.
 * Updates last_login_at as a side-effect.
 * Returns null if no user is found.
 */
export async function getUserBySupabaseUid(supabaseUid) {
  const client = await pool.connect();
  try {
    const result = await client.query(
      `UPDATE users
          SET last_login_at = NOW(), updated_at = NOW()
        WHERE supabase_uid = $1
        RETURNING ${RETURNING_COLS}`,
      [supabaseUid],
    );
    return result.rows[0] ?? null;
  } finally {
    client.release();
  }
}
