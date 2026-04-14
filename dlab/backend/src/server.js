import 'dotenv/config';
import express from 'express';
import cors from 'cors';

import { authRouter }      from './routes/auth.js';
import { couponsRouter } from './routes/coupons.js';
import { imageProxyRouter } from './routes/imageProxy.js';
import { notificationsRouter } from './routes/notifications.js';
import { errorHandler }    from './middleware/errorHandler.js';

const app = express();
const webhookEnabled = String(process.env.ENABLE_WEBHOOKS || '').toLowerCase() === 'true';

// Allowed origins from .env, plus any localhost origin (any port) for local dev.
const allowedOrigins = process.env.CORS_ORIGIN
  ? process.env.CORS_ORIGIN.split(',').map((o) => o.trim())
  : [];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, curl, Postman).
      if (!origin) return callback(null, true);

      // Allow any localhost origin regardless of port — needed for Flutter web dev.
      if (/^https?:\/\/localhost(:\d+)?$/.test(origin)) {
        return callback(null, true);
      }

      // Allow explicitly listed origins from .env.
      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      callback(new Error(`CORS: origin '${origin}' not allowed`));
    },
    credentials: true,
  }),
);
app.use(express.json({
  limit: '1mb',
  // Preserve raw buffer on req.rawBody for webhook HMAC verification.
  verify: (req, _res, buf) => { req.rawBody = buf; },
}));

app.get('/health', (req, res) => res.json({ ok: true }));

// DB connectivity check — hit this from a browser to verify PG is reachable.
app.get('/health/db', async (req, res) => {
  try {
    const { pool } = await import('./db/pool.js');
    const result = await pool.query('SELECT NOW() AS now');
    res.json({ ok: true, time: result.rows[0].now });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.use('/api/auth',         authRouter);
app.use('/api/coupons',      couponsRouter);
app.use('/api/image-proxy',  imageProxyRouter);
app.use('/api/notifications', notificationsRouter);

if (webhookEnabled) {
  try {
    const { webhookRouter } = await import('./routes/webhook.js');
    app.use('/api/webhooks', webhookRouter);
  } catch (err) {
    console.warn('[webhooks] ENABLE_WEBHOOKS=true but webhook route could not be loaded:', err?.message || err);
  }
}

// Global error handler — must be last middleware
app.use(errorHandler);

const port = Number(process.env.PORT || 3000);
app.listen(port, () => {
  // Avoid logging secrets
  console.log(`dlab-backend listening on :${port}`);
});
