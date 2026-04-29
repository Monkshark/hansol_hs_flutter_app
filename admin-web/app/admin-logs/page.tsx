'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import Badge from '@/components/Badge';
import { formatTime } from '@/lib/utils';
import { AdminLog } from '@/lib/types';
import { useCached } from '@/lib/cache';

type ActionFilter = 'all' | 'role' | 'delete' | 'user' | 'other';

const roleLabel: Record<string, string> = {
  admin: 'Admin',
  manager: '매니저',
  moderator: '모더레이터',
  auditor: '감사자',
  user: '일반',
};

function actionMeta(action: string): { label: string; color: string; group: ActionFilter } {
  if (action === 'change_role' || action.startsWith('역할 변경')) {
    return { label: '역할 변경', color: 'bg-indigo-100 dark:bg-indigo-900/40 text-indigo-600 dark:text-indigo-400', group: 'role' };
  }
  if (action === 'delete_post') {
    return { label: '게시글 삭제', color: 'bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-400', group: 'delete' };
  }
  if (action === 'delete_comment') {
    return { label: '댓글 삭제', color: 'bg-rose-100 dark:bg-rose-900/40 text-rose-600 dark:text-rose-400', group: 'delete' };
  }
  if (action === 'delete_feedback') {
    return { label: '건의 삭제', color: 'bg-orange-100 dark:bg-orange-900/40 text-orange-600 dark:text-orange-400', group: 'delete' };
  }
  if (action === 'approve_user' || action === '승인') {
    return { label: '가입 승인', color: 'bg-emerald-100 dark:bg-emerald-900/40 text-emerald-600 dark:text-emerald-400', group: 'user' };
  }
  if (action === 'reject_user' || action === '거절') {
    return { label: '가입 거절', color: 'bg-amber-100 dark:bg-amber-900/40 text-amber-600 dark:text-amber-400', group: 'user' };
  }
  if (action === 'suspend_user' || action === 'suspend' || action === '정지') {
    return { label: '계정 정지', color: 'bg-orange-100 dark:bg-orange-900/40 text-orange-600 dark:text-orange-400', group: 'user' };
  }
  if (action === 'unsuspend_user' || action === '정지 해제') {
    return { label: '정지 해제', color: 'bg-teal-100 dark:bg-teal-900/40 text-teal-600 dark:text-teal-400', group: 'user' };
  }
  if (action === 'delete_user' || action === '삭제') {
    return { label: '계정 삭제', color: 'bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-400', group: 'user' };
  }
  return { label: action || '-', color: 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300', group: 'other' };
}

function formatHours(hours?: number): string {
  if (!hours) return '';
  if (hours < 24) return `${hours}시간`;
  const days = Math.round(hours / 24);
  return `${days}일`;
}

function describe(log: AdminLog): React.ReactNode {
  const action = log.action;

  if (action === 'change_role') {
    const prev = roleLabel[log.previousRole ?? ''] ?? log.previousRole ?? '-';
    const next = roleLabel[log.newRole ?? ''] ?? log.newRole ?? '-';
    return (
      <>
        <span className="font-semibold">{log.targetName || '-'}</span>{' '}
        <span className="text-gray-400">{prev}</span>
        <span className="mx-1 text-gray-400">→</span>
        <span className="text-primary font-semibold">{next}</span>
      </>
    );
  }

  if (action?.startsWith('역할 변경')) {
    const next = action.replace('역할 변경:', '').trim();
    return (
      <>
        <span className="font-semibold">{log.targetName || '-'}</span>{' '}
        <span className="mx-1 text-gray-400">→</span>
        <span className="text-primary font-semibold">{roleLabel[next] ?? next}</span>
      </>
    );
  }

  if (action === 'delete_post') {
    return (
      <>
        <span className="font-semibold">{log.postTitle || log.postId || '-'}</span>
        {log.postAuthorName && <span className="text-gray-400 ml-2">— 작성자: {log.postAuthorName}</span>}
      </>
    );
  }

  if (action === 'delete_comment') {
    return (
      <>
        <span className="font-semibold truncate">{log.commentContent || '-'}</span>
        {log.commentAuthorName && <span className="text-gray-400 ml-2">— 작성자: {log.commentAuthorName}</span>}
      </>
    );
  }

  if (action === 'delete_feedback') {
    return (
      <>
        <span className="font-semibold">{log.feedbackContent || '-'}</span>
        {log.feedbackAuthorName && <span className="text-gray-400 ml-2">— 작성자: {log.feedbackAuthorName}</span>}
      </>
    );
  }

  if (action === 'suspend_user' || action === 'suspend' || action === '정지') {
    return (
      <>
        <span className="font-semibold">{log.targetName || '-'}</span>
        {log.hours != null && <span className="text-gray-400 ml-2">{formatHours(log.hours)} 정지</span>}
        {log.days != null && <span className="text-gray-400 ml-2">{log.days}일 정지</span>}
        {log.reason && <span className="text-gray-400 ml-2">사유: {log.reason}</span>}
      </>
    );
  }

  return <span className="font-semibold">{log.targetName || log.postTitle || log.feedbackContent || '-'}</span>;
}

export default function AdminLogsPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [filter, setFilter] = useState<ActionFilter>('all');
  const [search, setSearch] = useState('');

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);

  const { data: logs = [], loading: listLoading } = useCached<AdminLog[]>(
    profile ? 'admin-logs:list' : null,
    async () => {
      const q = query(collection(db, 'admin_logs'), orderBy('createdAt', 'desc'), limit(200));
      const snap = await getDocs(q);
      return snap.docs.map(d => ({ id: d.id, ...d.data() } as AdminLog));
    },
    { ttlMs: 60_000 }
  );

  const filtered = (logs || []).filter(l => {
    const meta = actionMeta(l.action);
    if (filter !== 'all' && meta.group !== filter) return false;
    if (!search) return true;
    const s = search.toLowerCase();
    return (
      (l.adminName?.toLowerCase().includes(s)) ||
      (l.targetName?.toLowerCase().includes(s)) ||
      (l.postTitle?.toLowerCase().includes(s)) ||
      (l.commentContent?.toLowerCase().includes(s)) ||
      (l.feedbackContent?.toLowerCase().includes(s))
    );
  });

  if (loading || !profile) return null;

  const filters: { key: ActionFilter; label: string }[] = [
    { key: 'all', label: '전체' },
    { key: 'role', label: '역할 변경' },
    { key: 'delete', label: '삭제' },
    { key: 'user', label: '계정' },
    { key: 'other', label: '기타' },
  ];

  return (
    <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6">
      <h1 className="text-2xl font-bold mb-2">관리자 로그</h1>
      <p className="text-xs text-gray-400 dark:text-gray-500 mb-5">최근 200건 · 30일간 보관</p>

      <div className="flex flex-wrap gap-2 mb-4">
        {filters.map(f => (
          <button key={f.key} onClick={() => setFilter(f.key)}
            className={`px-4 py-2 rounded-lg text-sm font-semibold transition ${
              filter === f.key ? 'bg-primary text-white' : 'bg-gray-100 dark:bg-dark-input text-gray-500 dark:text-gray-400'
            }`}>{f.label}</button>
        ))}
      </div>

      <input type="text" placeholder="관리자/대상자/내용 검색..." value={search} onChange={e => setSearch(e.target.value)}
        className="w-full md:max-w-md p-3 bg-white dark:bg-dark-card text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 rounded-xl mb-4 outline-none text-sm shadow-sm" />

      <div className="bg-white dark:bg-dark-card rounded-xl shadow-sm overflow-hidden overflow-x-auto">
        {listLoading && (logs || []).length === 0 ? (
          <p className="p-6 text-gray-400 text-sm">불러오는 중...</p>
        ) : filtered.length === 0 ? (
          <p className="p-6 text-gray-400 text-sm">로그가 없습니다</p>
        ) : (
          <table className="w-full text-sm min-w-[700px]">
            <thead><tr className="bg-gray-50 dark:bg-dark-input text-gray-400 dark:text-gray-500 text-xs">
              <th className="text-left p-3">유형</th>
              <th className="text-left p-3">대상</th>
              <th className="text-left p-3">관리자</th>
              <th className="text-left p-3">시간</th>
            </tr></thead>
            <tbody>
              {filtered.map(l => {
                const meta = actionMeta(l.action);
                return (
                  <tr key={l.id} className="border-t border-gray-50 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-input">
                    <td className="p-3 whitespace-nowrap"><Badge label={meta.label} className={meta.color} /></td>
                    <td className="p-3 max-w-[420px] truncate">{describe(l)}</td>
                    <td className="p-3 text-gray-600 dark:text-gray-300 whitespace-nowrap">{l.adminName || '-'}</td>
                    <td className="p-3 text-gray-400 text-xs whitespace-nowrap">{formatTime(l.createdAt)}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </main>
  );
}
