'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy, limit, doc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import { formatTime, canAccess } from '@/lib/utils';

interface Appeal {
  id: string;
  uid: string;
  content: string;
  status: string;
  createdAt: any;
  reviewedAt?: any;
  reviewerNote?: string;
}

export default function AppealsPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [appeals, setAppeals] = useState<Appeal[]>([]);
  const [selected, setSelected] = useState<Appeal | null>(null);
  const [note, setNote] = useState('');
  const [filter, setFilter] = useState<'all' | 'pending' | 'reviewing' | 'accepted' | 'rejected'>('pending');

  useEffect(() => {
    if (!loading && !profile) router.push('/');
  }, [loading, profile, router]);

  useEffect(() => {
    if (!profile) return;
    loadAppeals();
  }, [profile]);

  async function loadAppeals() {
    const snap = await getDocs(
      query(collection(db, 'appeals'), orderBy('createdAt', 'desc'), limit(200))
    );
    setAppeals(snap.docs.map(d => ({ id: d.id, ...d.data() } as Appeal)));
  }

  async function updateStatus(id: string, status: string) {
    if (!profile) return;
    const canWrite = ['admin', 'manager'].includes(profile.role);
    if (!canWrite) return;
    await updateDoc(doc(db, 'appeals', id), {
      status,
      reviewerNote: note,
      reviewedAt: serverTimestamp(),
      reviewedBy: profile.uid,
    });
    setAppeals(prev => prev.map(a => a.id === id ? { ...a, status, reviewerNote: note } : a));
    if (selected?.id === id) setSelected({ ...selected, status, reviewerNote: note });
    setNote('');
  }

  function statusBadge(status: string) {
    const config: Record<string, { bg: string; text: string; label: string }> = {
      pending: { bg: 'bg-gray-200 dark:bg-gray-500/20', text: 'text-gray-500 dark:text-gray-400', label: '대기중' },
      reviewing: { bg: 'bg-orange-100 dark:bg-orange-500/20', text: 'text-orange-600 dark:text-orange-400', label: '검토중' },
      accepted: { bg: 'bg-green-100 dark:bg-green-500/20', text: 'text-green-600 dark:text-green-400', label: '수용' },
      rejected: { bg: 'bg-red-100 dark:bg-red-500/20', text: 'text-red-600 dark:text-red-400', label: '기각' },
    };
    const c = config[status] || config.pending;
    return <span className={`${c.bg} ${c.text} text-xs font-semibold px-2 py-0.5 rounded`}>{c.label}</span>;
  }

  if (loading || !profile) return null;
  if (!canAccess(profile.role, 'appeals')) {
    return <main className="flex-1 p-8 text-gray-400">접근 권한이 없습니다.</main>;
  }

  const canWrite = ['admin', 'manager'].includes(profile.role);
  const filtered = filter === 'all' ? appeals : appeals.filter(a => a.status === filter);

  return (
    <main className="flex-1 p-4 md:p-8 pt-14 md:pt-8">
      <h1 className="text-2xl font-bold mb-6">이의제기</h1>

      <div className="flex gap-2 mb-6 flex-wrap">
        {(['all', 'pending', 'reviewing', 'accepted', 'rejected'] as const).map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
              filter === f ? 'bg-primary text-white' : 'bg-white dark:bg-dark-card text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
            }`}>
            {f === 'all' ? '전체' : f === 'pending' ? '대기중' : f === 'reviewing' ? '검토중' : f === 'accepted' ? '수용' : '기각'}
          </button>
        ))}
      </div>

      <div className="flex gap-6 flex-col md:flex-row">
        <div className="flex-1 space-y-3 min-w-0">
          {filtered.length === 0 ? (
            <div className="bg-white dark:bg-dark-card rounded-xl p-12 text-center">
              <p className="text-gray-400">이의제기가 없습니다</p>
            </div>
          ) : filtered.map(a => (
            <div key={a.id}
              onClick={() => { setSelected(a); setNote(a.reviewerNote || ''); }}
              className={`bg-white dark:bg-dark-card rounded-xl p-4 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-white/5 ${
                selected?.id === a.id ? 'ring-1 ring-primary' : ''
              }`}>
              <div className="flex items-center gap-2 mb-2">
                {statusBadge(a.status)}
                <span className="text-sm font-mono">{a.uid.slice(0, 8)}</span>
                <span className="text-gray-500 dark:text-gray-400 text-xs ml-auto">
                  {a.createdAt ? formatTime(a.createdAt) : ''}
                </span>
              </div>
              <p className="text-gray-700 dark:text-gray-300 text-sm line-clamp-2">{a.content}</p>
            </div>
          ))}
        </div>

        {selected && (
          <div className="w-full md:w-96 bg-white dark:bg-dark-card rounded-xl p-6 h-fit md:sticky md:top-8 shrink-0">
            <div className="flex items-center gap-2 mb-4">
              {statusBadge(selected.status)}
              <span className="font-mono text-sm">{selected.uid.slice(0, 12)}</span>
            </div>
            <p className="text-gray-700 dark:text-gray-300 text-sm whitespace-pre-wrap mb-4" style={{ lineHeight: 1.7 }}>
              {selected.content}
            </p>
            {canWrite && (
              <>
                <textarea
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  placeholder="검토 메모 (사용자에게는 비공개)"
                  rows={3}
                  className="w-full bg-gray-50 dark:bg-dark-bg text-gray-900 dark:text-gray-200 text-sm p-3 rounded-lg mb-3 resize-none border border-gray-200 dark:border-gray-700 focus:border-primary outline-none"
                />
                <div className="flex gap-2 flex-wrap">
                  {selected.status !== 'reviewing' && (
                    <button onClick={() => updateStatus(selected.id, 'reviewing')}
                      className="flex-1 py-2 rounded-lg text-sm font-semibold border border-orange-500 text-orange-600 dark:text-orange-400 hover:bg-orange-50 dark:hover:bg-orange-500/10">
                      검토중
                    </button>
                  )}
                  <button onClick={() => updateStatus(selected.id, 'accepted')}
                    className="flex-1 py-2 rounded-lg text-sm font-semibold bg-green-600 text-white hover:bg-green-700">
                    수용
                  </button>
                  <button onClick={() => updateStatus(selected.id, 'rejected')}
                    className="flex-1 py-2 rounded-lg text-sm font-semibold bg-red-600 text-white hover:bg-red-700">
                    기각
                  </button>
                </div>
              </>
            )}
            {!canWrite && (
              <p className="text-gray-500 dark:text-gray-400 text-xs">읽기 전용 (감사자)</p>
            )}
          </div>
        )}
      </div>
    </main>
  );
}
