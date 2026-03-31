'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy, limit, where, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import StatsCard from '@/components/StatsCard';
import Badge from '@/components/Badge';
import { formatTime } from '@/lib/utils';
import { Post, Report } from '@/lib/types';

export default function DashboardPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [stats, setStats] = useState({ users: 0, posts: 0, reports: 0, todayPosts: 0 });
  const [recentPosts, setRecentPosts] = useState<Post[]>([]);
  const [recentReports, setRecentReports] = useState<Report[]>([]);

  useEffect(() => {
    if (!loading && !profile) router.push('/');
  }, [loading, profile, router]);

  useEffect(() => {
    if (!profile) return;
    loadData();
  }, [profile]);

  async function loadData() {
    const [usersSnap, postsSnap, reportsSnap] = await Promise.all([
      getDocs(collection(db, 'users')),
      getDocs(collection(db, 'posts')),
      getDocs(collection(db, 'reports')),
    ]);

    const today = new Date(); today.setHours(0, 0, 0, 0);
    const todayPosts = await getDocs(query(collection(db, 'posts'), where('createdAt', '>=', Timestamp.fromDate(today))));

    setStats({
      users: usersSnap.size,
      posts: postsSnap.size,
      reports: reportsSnap.size,
      todayPosts: todayPosts.size,
    });

    const postsQ = query(collection(db, 'posts'), orderBy('createdAt', 'desc'), limit(10));
    const postsData = await getDocs(postsQ);
    setRecentPosts(postsData.docs.map(d => ({ id: d.id, ...d.data() } as Post)));

    const reportsQ = query(collection(db, 'reports'), orderBy('createdAt', 'desc'), limit(5));
    const reportsData = await getDocs(reportsQ);
    setRecentReports(reportsData.docs.map(d => ({ id: d.id, ...d.data() } as Report)));
  }

  if (loading || !profile) return <div className="min-h-screen flex items-center justify-center">로딩중...</div>;

  const catColor: Record<string, string> = {
    '자유': 'bg-blue-100 text-blue-600',
    '질문': 'bg-green-100 text-green-600',
    '정보공유': 'bg-orange-100 text-orange-600',
  };

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-6">
        <h1 className="text-2xl font-bold mb-5">대시보드</h1>

        <div className="grid grid-cols-4 gap-4 mb-6">
          <StatsCard label="전체 사용자" value={stats.users} />
          <StatsCard label="전체 게시글" value={stats.posts} />
          <StatsCard label="미처리 신고" value={stats.reports} color="text-red-500" />
          <StatsCard label="오늘 게시글" value={stats.todayPosts} color="text-green-500" />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white rounded-xl p-5 shadow-sm">
            <h3 className="font-bold mb-3">최근 신고</h3>
            {recentReports.length === 0 ? (
              <p className="text-gray-400 text-sm">신고가 없습니다</p>
            ) : (
              <table className="w-full text-sm">
                <thead><tr className="text-gray-400 text-xs">
                  <th className="text-left pb-2">사유</th><th className="text-left pb-2">시간</th>
                </tr></thead>
                <tbody>
                  {recentReports.map(r => (
                    <tr key={r.id} className="border-t border-gray-50">
                      <td className="py-2"><Badge label={r.reason} className="bg-red-100 text-red-600" /></td>
                      <td className="py-2 text-gray-400">{formatTime(r.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <div className="bg-white rounded-xl p-5 shadow-sm">
            <h3 className="font-bold mb-3">최근 게시글</h3>
            <table className="w-full text-sm">
              <thead><tr className="text-gray-400 text-xs">
                <th className="text-left pb-2">카테고리</th><th className="text-left pb-2">제목</th><th className="text-left pb-2">작성자</th>
              </tr></thead>
              <tbody>
                {recentPosts.map(p => (
                  <tr key={p.id} className="border-t border-gray-50 cursor-pointer hover:bg-gray-50"
                    onClick={() => router.push(`/posts/${p.id}`)}>
                    <td className="py-2"><Badge label={p.category} className={catColor[p.category] || 'bg-gray-100 text-gray-600'} /></td>
                    <td className="py-2">{p.isPinned && <span className="text-red-500 mr-1">📌</span>}{p.title}</td>
                    <td className="py-2 text-gray-400">{p.authorName}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}
