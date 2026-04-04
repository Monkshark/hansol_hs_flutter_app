import { Timestamp } from 'firebase/firestore';

export function formatTime(ts: Timestamp | undefined): string {
  if (!ts) return '';
  const dt = ts.toDate();
  const diff = Date.now() - dt.getTime();
  const min = Math.floor(diff / 60000);
  if (min < 1) return '방금';
  if (min < 60) return `${min}분 전`;
  const hours = Math.floor(min / 60);
  if (hours < 24) return `${hours}시간 전`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}일 전`;
  return `${dt.getMonth() + 1}/${dt.getDate()}`;
}

export function isSuspended(suspendedUntil?: Timestamp): boolean {
  if (!suspendedUntil) return false;
  return new Date() < suspendedUntil.toDate();
}

export function suspendRemaining(suspendedUntil?: Timestamp): string {
  if (!suspendedUntil) return '';
  const diff = suspendedUntil.toDate().getTime() - Date.now();
  if (diff <= 0) return '';
  const d = Math.floor(diff / 86400000);
  const h = Math.floor((diff % 86400000) / 3600000);
  const m = Math.floor((diff % 3600000) / 60000);
  const parts: string[] = [];
  if (d > 0) parts.push(`${d}일`);
  if (h > 0) parts.push(`${h}시간`);
  if (m > 0) parts.push(`${m}분`);
  return parts.join(' ') || '1분 미만';
}

export function displayName(user: { name: string; userType?: string; studentId?: string; graduationYear?: number }): string {
  switch (user.userType) {
    case 'graduate': return `졸업생 ${user.name}`;
    case 'teacher': return `교사 ${user.name}`;
    case 'parent': return `학부모 ${user.name}`;
    default: return user.studentId ? `${user.studentId} ${user.name}` : user.name;
  }
}

export function roleBadge(role: string) {
  switch (role) {
    case 'admin': return { label: 'Admin', color: 'bg-red-100 text-red-600' };
    case 'manager': return { label: '매니저', color: 'bg-blue-100 text-blue-600' };
    default: return null;
  }
}
