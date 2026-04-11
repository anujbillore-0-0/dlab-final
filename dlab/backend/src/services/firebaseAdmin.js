import fs from 'fs';
import path from 'path';
import process from 'process';

import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

function readServiceAccountFromEnv() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  }

  if (process.env.FIREBASE_SERVICE_ACCOUNT_PATH) {
    const resolvedPath = path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
    const content = fs.readFileSync(resolvedPath, 'utf8');
    return JSON.parse(content);
  }

  return null;
}

function initFirebaseApp() {
  if (getApps().length > 0) return getApps()[0];

  const serviceAccount = readServiceAccountFromEnv();
  if (serviceAccount) {
    return initializeApp({
      credential: cert(serviceAccount),
    });
  }

  return initializeApp();
}

const firebaseApp = initFirebaseApp();

export const messaging = getMessaging(firebaseApp);
