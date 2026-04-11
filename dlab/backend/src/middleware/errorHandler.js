export function errorHandler(err, req, res, next) {
  // Always log the full error server-side (visible in pm2 logs).
  console.error('[errorHandler]', err);

  // In non-production, send the real message back so the client can debug.
  const isDev = process.env.NODE_ENV !== 'production';
  res.status(500).json({
    message: isDev ? (err?.message ?? 'Internal Server Error') : 'Internal Server Error',
    ...(isDev && err?.detail  ? { detail: err.detail }   : {}),
    ...(isDev && err?.code    ? { code:   err.code }     : {}),
    ...(isDev && err?.hint    ? { hint:   err.hint }     : {}),
  });
}
