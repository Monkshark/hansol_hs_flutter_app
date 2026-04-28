'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy, limit, doc, updateDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import { formatTime } from '@/lib/utils';

interface Feedback {
  id: string;
  content: string;
  imageUrls: string[];
  authorName: string;
  authorUid: string;
  status: string;
  createdAt: any;
}

export default function FeedbacksPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [tab, setTab] = useState<'app' | 'council'>('app');
  const [feedbacks, setFeedbacks] = useState<Feedback[]>([]);
  const [selected, setSelected] = useState<Feedback | null>(null);

  useEffect(() => {
    if (!loading && !profile) router.push('/');
  }, [loading, profile, router]);

  useEffect(() => {
    if (!profile) return;
    loadFeedbacks();
  }, [profile, tab]);

  async function loadFeedbacks() {
    const col = tab === 'app' ? 'app_feedbacks' : 'council_feedbacks';
    const snap = await getDocs(
      query(collection(db, col), orderBy('createdAt', 'desc'), limit(100))
    );
    setFeedbacks(snap.docs.map(d => ({ id: d.id, ...d.data() } as Feedback)));
  }

  async function updateStatus(id: string, status: string) {
    const col = tab === 'app' ? 'app_feedbacks' : 'council_feedbacks';
    await updateDoc(doc(db, col, id), { status });
    setFeedbacks(prev => prev.map(f => f.id === id ? { ...f, status } : f));
    if (selected?.id === id) setSelected({ ...selected!, status });
  }

  function statusBadge(status: string) {
    const config: Record<string, { bg: string; text: string; label: string }> = {
      pending: { bg: 'bg-gray-200 dark:bg-gray-500/20', text: 'text-gray-500 dark:text-gray-400', label: '대기중' },
      reviewed: { bg: 'bg-orange-100 dark:bg-orange-500/20', text: 'text-orange-600 dark:text-orange-400', label: '확인됨' },
      resolved: { bg: 'bg-green-100 dark:bg-green-500/20', text: 'text-green-600 dark:text-green-400', label: '해결됨' },
    };
    const c = config[status] || config.pending;
    return <span className={`${c.bg} ${c.text} text-xs font-semibold px-2 py-0.5 rounded`}>{c.label}</span>;
  }

  if (loading || !profile) return null;

  return (
    <main className="flex-1 p-4 md:p-8 pt-14 md:pt-8">
      <h1 className="text-2xl font-bold mb-6">건의사항</h1>

      <div className="flex gap-2 mb-6">
        <button onClick={() => { setTab('app'); setSelected(null); }}
          className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
            tab === 'app' ? 'bg-primary text-white' : 'bg-white dark:bg-dark-card text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
          }`}>
          앱 건의/버그
        </button>
        <button onClick={() => { setTab('council'); setSelected(null); }}
          className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${
            tab === 'council' ? 'bg-primary text-white' : 'bg-white dark:bg-dark-card text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
          }`}>
          학생회 건의
        </button>
      </div>

      <div className="flex gap-6 flex-col md:flex-row">
        {/* 목록 */}
        <div className="flex-1 space-y-3 min-w-0">
          {feedbacks.length === 0 ? (
            <div className="bg-white dark:bg-dark-card rounded-xl p-12 text-center">
              <p className="text-gray-400">건의사항이 없습니다</p>
            </div>
          ) : feedbacks.map(f => (
            <div key={f.id}
              onClick={() => setSelected(f)}
              className={`bg-white dark:bg-dark-card rounded-xl p-4 cursor-pointer transition-colors hover:bg-gray-50 dark:hover:bg-white/5 ${
                selected?.id === f.id ? 'ring-1 ring-primary' : ''
              }`}>
              <div className="flex items-center gap-2 mb-2">
                {statusBadge(f.status)}
                <span className="text-sm font-semibold">{f.authorName}</span>
                <span className="text-gray-500 dark:text-gray-400 text-xs ml-auto">
                  {f.createdAt ? formatTime(f.createdAt) : ''}
                </span>
              </div>
              <p className="text-gray-700 dark:text-gray-300 text-sm line-clamp-2">{f.content}</p>
              {f.imageUrls?.length > 0 && (
                <p className="text-gray-500 dark:text-gray-400 text-xs mt-1">사진 {f.imageUrls.length}장</p>
              )}
            </div>
          ))}
        </div>

        {/* 상세 */}
        {selected && (
          <div className="w-full md:w-96 bg-white dark:bg-dark-card rounded-xl p-6 h-fit md:sticky md:top-8 shrink-0">
            <div className="flex items-center gap-2 mb-4">
              {statusBadge(selected.status)}
              <span className="font-semibold">{selected.authorName}</span>
            </div>
            <p className="text-gray-700 dark:text-gray-300 text-sm whitespace-pre-wrap mb-4" style={{ lineHeight: 1.7 }}>
              {selected.content}
            </p>
            {selected.imageUrls?.length > 0 && (
              <div className="space-y-2 mb-4">
                {selected.imageUrls.map((url, i) => (
                  <img key={i} src={url} alt="" className="rounded-lg w-full" />
                ))}
              </div>
            )}
            <div className="flex gap-2">
              {selected.status !== 'reviewed' && (
                <button onClick={() => updateStatus(selected.id, 'reviewed')}
                  className="flex-1 py-2 rounded-lg text-sm font-semibold border border-orange-500 text-orange-600 dark:text-orange-400 hover:bg-orange-50 dark:hover:bg-orange-500/10">
                  확인됨
                </button>
              )}
              {selected.status !== 'resolved' && (
                <button onClick={() => updateStatus(selected.id, 'resolved')}
                  className="flex-1 py-2 rounded-lg text-sm font-semibold bg-green-600 text-white hover:bg-green-700">
                  해결됨
                </button>
              )}
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
