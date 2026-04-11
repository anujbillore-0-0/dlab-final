import crypto from 'crypto';

import { Router } from 'express';
import { z } from 'zod';

import { verifySupabaseToken } from '../middleware/verifySupabaseToken.js';
import { messaging } from '../services/firebaseAdmin.js';

export const notificationsRouter = Router();

const BROADCAST_TOPIC = process.env.FCM_BROADCAST_TOPIC ?? 'all_users';

function getTopicSecret() {
  return process.env.FCM_TOPIC_SECRET || process.env.SUPABASE_SERVICE_ROLE_KEY || 'dlab-fcm-topic-secret';
}

function sanitizeTopicPart(value) {
  return value.replace(/[^a-zA-Z0-9_-]/g, '');
}

export function buildUserTopic(userId) {
  const uid = sanitizeTopicPart(userId);
  const hash = crypto
    .createHmac('sha256', getTopicSecret())
    .update(userId)
    .digest('hex')
    .slice(0, 24);

  return `u_${uid}_${hash}`;
}

function requireAdminSendKey(req, res, next) {
  const configured = process.env.NOTIFICATION_ADMIN_KEY;
  if (!configured) {
    return res.status(500).json({ message: 'Notification admin key is not configured' });
  }

  const provided = req.headers['x-notification-admin-key']?.toString() ?? '';
  if (provided !== configured) {
    return res.status(401).json({ message: 'Unauthorized notification sender' });
  }

  return next();
}

const sendSchema = z.object({
  targetType: z.enum(['all', 'topic', 'user']),
  topic: z.string().trim().min(1).optional(),
  userId: z.string().trim().min(1).optional(),
  title: z.string().trim().min(1),
  body: z.string().trim().min(1),
  imageUrl: z.string().trim().url().optional(),
  deepLink: z.string().trim().optional(),
  data: z.record(z.string()).optional(),
});

function resolveTargetTopic({ targetType, topic, userId }) {
  if (targetType === 'all') return BROADCAST_TOPIC;
  if (targetType === 'topic') return sanitizeTopicPart(topic);
  return buildUserTopic(userId);
}

notificationsRouter.get('/health', (_req, res) => {
  res.json({ ok: true, broadcastTopic: BROADCAST_TOPIC });
});

notificationsRouter.post('/topic', verifySupabaseToken, async (req, res, next) => {
  try {
    const userId = req.supabaseUser?.id;
    if (!userId) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    return res.json({
      userId,
      broadcastTopic: BROADCAST_TOPIC,
      userTopic: buildUserTopic(userId),
    });
  } catch (err) {
    return next(err);
  }
});

notificationsRouter.post('/send', requireAdminSendKey, async (req, res, next) => {
  try {
    const parsed = sendSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
      return res.status(400).json({
        message: 'Invalid payload',
        issues: parsed.error.flatten(),
      });
    }

    const payload = parsed.data;

    if (payload.targetType === 'topic' && !payload.topic) {
      return res.status(400).json({ message: 'topic is required when targetType=topic' });
    }
    if (payload.targetType === 'user' && !payload.userId) {
      return res.status(400).json({ message: 'userId is required when targetType=user' });
    }

    const topic = resolveTargetTopic(payload);
    const dataPayload = {
      ...(payload.deepLink ? { deep_link: payload.deepLink } : {}),
      ...(payload.data ?? {}),
    };

    const message = {
      topic,
      notification: {
        title: payload.title,
        body: payload.body,
        ...(payload.imageUrl ? { imageUrl: payload.imageUrl } : {}),
      },
      data: dataPayload,
      android: {
        priority: 'high',
        notification: {
          ...(payload.imageUrl ? { imageUrl: payload.imageUrl } : {}),
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            'mutable-content': payload.imageUrl ? 1 : 0,
          },
        },
        ...(payload.imageUrl ? { fcmOptions: { imageUrl: payload.imageUrl } } : {}),
      },
    };

    const messageId = await messaging.send(message);

    return res.json({
      ok: true,
      messageId,
      targetType: payload.targetType,
      topic,
    });
  } catch (err) {
    return next(err);
  }
});
