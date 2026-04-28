'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, deleteDoc, doc, query, orderBy } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import Badge from '@/components/Badge';
import { formatTime } from '@/lib/utils';
import { Report } from '@/lib/types';

export default function ReportsPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [reports, setReports] = useState<Report[]>([]);

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);
  useEffect(() => { if (profile) loadReports(); }, [profile]);

  async function loadReports() {
    const q = query(collection(db, 'reports'), orderBy('createdAt', 'desc'));
    const snap = await getDocs(q);
    setReports(snap.docs.map(d => ({ id: d.id, ...d.data() } as Report)));
  }

  async function handleDeletePost(postId: string, reportId: string) {
    if (!confirm('신고된 게시글을 삭제하시겠습니까?')) return;
    try {
      const comments = await getDocs(collection(db, 'posts', postId, 'comments'));
      for (const c of comments.docs) await deleteDoc(c.ref);
      await deleteDoc(doc(db, 'posts', postId));
    } catch {}
    await deleteDoc(doc(db, 'reports', reportId));
    setReports(prev => prev.filter(r => r.id !== reportId));
  }

  async function handleDismiss(reportId: string) {
    if (!confirm('이 신고를 무시하시겠습니까?')) return;
    await deleteDoc(doc(db, 'reports', reportId));
    setReports(prev => prev.filter(r => r.id !== reportId));
  }

  if (loading || !profile) return null;

  return (
    <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6">
      <h1 className="text-2xl font-bold mb-5">신고 관리</h1>

      <div className="bg-white dark:bg-dark-card rounded-xl shadow-sm overflow-hidden overflow-x-auto">
        {reports.length === 0 ? (
          <p className="p-6 text-gray-400 text-sm">신고가 없습니다</p>
        ) : (
          <table className="w-full text-sm min-w-[500px]">
            <thead><tr className="bg-gray-50 dark:bg-dark-input text-gray-400 dark:text-gray-500 text-xs">
              <th className="text-left p-3">사유</th>
              <th className="text-left p-3">신고자</th>
              <th className="text-left p-3">시간</th>
              <th className="text-left p-3">액션</th>
            </tr></thead>
            <tbody>
              {reports.map(r => (
                <tr key={r.id} className="border-t border-gray-50 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-input">
                  <td className="p-3"><Badge label={r.reason} className="bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-400" /></td>
                  <td className="p-3 text-gray-400 text-xs">{r.reporterUid.substring(0, 8)}...</td>
                  <td className="p-3 text-gray-400 text-xs">{formatTime(r.createdAt)}</td>
                  <td className="p-3 flex gap-2 flex-wrap">
                    <button onClick={() => router.push(`/posts/${r.postId}`)}
                      className="px-3 py-1 bg-primary text-white rounded-lg text-xs font-semibold">글 보기</button>
                    <button onClick={() => handleDeletePost(r.postId, r.id)}
                      className="px-3 py-1 bg-red-500 text-white rounded-lg text-xs font-semibold">글 삭제</button>
                    <button onClick={() => handleDismiss(r.id)}
                      className="px-3 py-1 bg-gray-400 text-white rounded-lg text-xs font-semibold">무시</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </main>
  );
}
