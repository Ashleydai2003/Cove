// /Backend/src/services/notify.ts
import * as admin from 'firebase-admin';
import { initializeFirebase } from '../middleware/firebase';
import { PrismaClient } from '@prisma/client';

export type NotificationData = {
  type: string;
  actor_user_id?: string;
  cove_id?: string;
  event_id?: string;
  deeplink?: string;
  [key: string]: string | undefined;
};

function truncate(input: string, max: number): string {
  if (input.length <= max) return input;
  return input.slice(0, max - 1) + '…';
}

export async function sendToTokens(tokens: string[], title: string, body: string, data: NotificationData): Promise<admin.messaging.BatchResponse | null> {
  if (!tokens.length) return null;
  await initializeFirebase();
  const sanitizedTitle = truncate(title, 120);
  const sanitizedBody = truncate(body, 240);

  try {
    const res = await admin.messaging().sendMulticast({
      tokens,
      notification: { title: sanitizedTitle, body: sanitizedBody },
      data: Object.fromEntries(Object.entries(data).filter(([, v]) => typeof v === 'string' && v !== undefined)) as { [key: string]: string },
    });
    console.log(`[notify] FCM multicast: success=${res.successCount} failure=${res.failureCount}`);
    if (res.failureCount > 0) {
      res.responses.forEach((r, idx) => {
        if (!r.success) {
          console.warn(`[notify] token[${idx}] error:`, r.error?.code, r.error?.message);
        }
      });
    }
    return res;
  } catch (err) {
    console.error('FCM sendMulticast error:', err);
    return null;
  }
}

export async function sendToUserIds(prisma: PrismaClient, userIds: string[], title: string, body: string, data: NotificationData): Promise<void> {
  if (!userIds.length) return;
  const users = await prisma.user.findMany({ where: { id: { in: userIds } }, select: { id: true, fcmToken: true } });
  const tokens = users.map(u => u.fcmToken).filter((t): t is string => !!t);
  if (!tokens.length) return;
  const res = await sendToTokens(tokens, title, body, data);
  // Cleanup UNREGISTERED tokens (stale)
  if (res && res.failureCount > 0) {
    const invalid: string[] = [];
    res.responses.forEach((r, idx) => {
      if (!r.success && r.error?.code === 'messaging/registration-token-not-registered') {
        invalid.push(tokens[idx]);
      }
    });
    if (invalid.length) {
      await prisma.user.updateMany({ where: { fcmToken: { in: invalid } }, data: { fcmToken: null } });
      console.log(`[notify] Cleared ${invalid.length} unregistered tokens`);
    }
  }
} 