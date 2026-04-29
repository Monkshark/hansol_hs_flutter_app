'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy, limit, doc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import { formatTime, canAccess } from '@/lib/utils';

interface DataRequest {
  id: string;
  uid: string;
  type: string;
  status: string;
  createdAt: any;
  completedAt?: any;
  downloadUrl?: string;
  note?: string;
}

export default function DataRequestsPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [requests, setRequests] = useState<DataRequest[]>([]);
  const [selected, setSelected] = useState<DataRequest | null>(null);

  useEffect(() => {
    if (!loading && !profile) router.push('/');
  }, [loading, profile, router]);

  useEffect(() => {
    if (!profile) return;
    loadRequests();
  }, [profile]);

  async function loadRequests() {
    const snap = await getDocs(
      query(collection(db, 'data_requests'), orderBy('createdAt', 'desc'), limit(200))
    );
    setRequests(snap.docs.map(d => ({ id: d.id, ...d.data() } as DataRequest)));
  }

  async function updateStatus(id: string, status: string, note?: string) {
    if (!profile) return;
    const update: any = {
      status,
      processedBy: profile.uid,
      processedAt: serverTimestamp(),
    };
    if (status === 'completed') update.completedAt = serverTimestamp();
    if (note !== undefined) update.note = note;
    await updateDoc(doc(db, 'data_requests', id), update);
    setRequests(prev => prev.map(r => r.id === id ? { ...r, status, note: note ?? r.note } : r));
    if (selected?.id === id) setSelected({ ...selected, status, note: note ?? selected.note });
  }

  function typeBadge(type: string) {
    const config: Record<string, { bg: string; text: string; label: string }> = {
      export: { bg: 'bg-blue-100 dark:bg-blue-500/20', text: 'text-blue-600 dark:text-blue-400', label: '데이터 내보내기' },
      delete: { bg: 'bg-red-100 dark:bg-red-500/20', text: 'text-red-600 dark:text-red-400', label: '삭제 요청' },
    };
    const c = config[type] || { bg: 'bg-gray-200 dark:bg-gray-500/20', text: 'text-gray-500 dark:text-gray-400', label: type };
    return <span className={`${c.bg} ${c.text} text-xs font-semibold px-2 py-0.5 rounded`}>{c.label}</span>;
  }

  function statusBadge(status: string) {
    const config: Record<string, { bg: string; text: string; label: string }> = {
      pending: { bg: 'bg-gray-200 dark:bg-gray-500/20', text: 'text-gray-500 dark:text-gray-400', label: '대기중' },
      processing: { bg: 'bg-orange-100 dark:bg-orange-500/20', text: 'text-orange-600 dark:text-orange-400', label: '처리중' },
      completed: { bg: 'bg-green-100 dark:bg-green-500/20', text: 'text-green-600 dark:text-green-400', label: '완료' },
      rejected: { bg: 'bg-red-100 dark:bg-red-500/20', text: 'text-red-600 dark:text-red-400', label: '거부' },
    };
    const c = config[status] || config.pending;
    return <span className={`${c.bg} ${c.text} text-xs font-semibold px-2 py-0.5 rounded`}>{c.label}</span>;
  }

  if (loading || !profile) return null;
  if (!canAccess(profile.role, 'data-requests')) {
    return <main className="flex-1 p-8 text-gray-400">접근 권한이 없습니다.</main>;
  }

  return (
    <main className="flex-1 p-4 md:p-8 pt-14 md:pt-8">
      <h1 className="text-2xl font-bold mb-2">데이터 요청</h1>
      <p className="text-gray-500 dark:text-gray-400 text-sm mb-6">개인정보보호법 제35조(열람권) / 제36조(정정·삭제권)</p>

      <div className="flex gap-6 flex-col md:flex-row">
        <div className="flex-1 space-y-3 min-w-0">
          {requests.length === 0 ? (
            <div className="bg-white dark:bg-dark-card rounded-xl p-12 text-center">
              <p className="text-gray-400">요청이 없습니다</p>
            </div>
          ) : requests.map(r => (
            <div key={r.id}
              onClick={() => setSelected(r)}
              className={`bg-white dark:bg-dark-card rounded-xl p-4 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-white/5 ${
                selected?.id === r.id ? 'ring-1 ring-primary' : ''
              }`}>
              <div className="flex items-center gap-2 mb-2 flex-wrap">
                {typeBadge(r.type)}
                {statusBadge(r.status)}
                <span className="text-sm font-mono">{r.uid.slice(0, 8)}</span>
                <span className="text-gray-500 dark:text-gray-400 text-xs ml-auto">
                  {r.createdAt ? formatTime(r.createdAt) : ''}
                </span>
              </div>
              {r.note && <p className="text-gray-500 dark:text-gray-400 text-xs line-clamp-1">{r.note}</p>}
            </div>
          ))}
        </div>

        {selected && (
          <div className="w-full md:w-96 bg-white dark:bg-dark-card rounded-xl p-6 h-fit md:sticky md:top-8 shrink-0">
            <div className="flex items-center gap-2 mb-4 flex-wrap">
              {typeBadge(selected.type)}
              {statusBadge(selected.status)}
            </div>
            <div className="text-sm mb-3">
              <p className="font-semibold mb-1">UID</p>
              <p className="font-mono text-xs text-gray-500 dark:text-gray-400">{selected.uid}</p>
            </div>
            {selected.downloadUrl && (
              <div className="mb-3">
                <a href={selected.downloadUrl} target="_blank" rel="noreferrer"
                  className="text-primary text-sm underline break-all">
                  내보내기 파일 다운로드
                </a>
              </div>
            )}
            {selected.note && (
              <p className="text-gray-700 dark:text-gray-300 text-sm whitespace-pre-wrap mb-4">{selected.note}</p>
            )}
            <div className="flex gap-2 flex-wrap">
              {selected.status !== 'processing' && (
                <button onClick={() => updateStatus(selected.id, 'processing')}
                  className="flex-1 py-2 rounded-lg text-sm font-semibold border border-orange-500 text-orange-600 dark:text-orange-400 hover:bg-orange-50 dark:hover:bg-orange-500/10">
                  처리중
                </button>
              )}
              <button onClick={() => updateStatus(selected.id, 'completed')}
                className="flex-1 py-2 rounded-lg text-sm font-semibold bg-green-600 text-white hover:bg-green-700">
                완료
              </button>
              <button onClick={() => updateStatus(selected.id, 'rejected')}
                className="flex-1 py-2 rounded-lg text-sm font-semibold bg-red-600 text-white hover:bg-red-700">
                거부
              </button>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
