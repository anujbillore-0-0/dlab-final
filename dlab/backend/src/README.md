# dlab-backend

Express + Supabase Auth + PostgreSQL.

## Setup

1) Copy `.env.example` to `.env` and fill values.
2) Set `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` from Supabase Dashboard → Settings → API.
3) Ensure the VPS Postgres has the `users` table (see `schema.sql` in project root).

## Endpoints

- `GET  /health` — server health check
- `GET  /health/db` — PostgreSQL connectivity check
- `GET  /api/auth/check-email?email=...` — check if email exists (public, no JWT)
- `POST /api/auth/sync-user` (Authorization: Bearer \<Supabase JWT\>)
- `GET  /api/auth/me` (Authorization: Bearer \<Supabase JWT\>)

## Notes

- Do **not** commit `.env` or any secret keys.
- Use the Supabase JWT from Flutter in the `Authorization` header.
