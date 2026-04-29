import { addDoc, collection, serverTimestamp, Timestamp } from 'firebase/firestore';
import { db } from './firebase';
import { UserProfile } from './types';

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;

export async function writeAdminLog(
  actor: UserProfile | null,
  action: string,
  fields: Record<string, unknown> = {},
): Promise<void> {
  try {
    await addDoc(collection(db, 'admin_logs'), {
      action,
      adminUid: actor?.uid ?? '',
      adminName: actor?.name ?? '',
      ...fields,
      createdAt: serverTimestamp(),
      expiresAt: Timestamp.fromDate(new Date(Date.now() + THIRTY_DAYS_MS)),
    });
  } catch (e) {
    console.error('writeAdminLog failed:', e);
  }
}
