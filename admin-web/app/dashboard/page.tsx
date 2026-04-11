'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy, limit, where, Timestamp, collectionGroup } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import StatsCard from '@/components/StatsCard';
import Badge from '@/components/Badge';
import { formatTime } from '@/lib/utils';
import { Post, Report } from '@/lib/types';
import {
  ResponsiveContainer, LineChart, Line, BarChart, Bar,
  PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
} from 'recharts';

const COLORS = ['#3b82f6', '#22c55e', '#f97316', '#ef4444', '#a855f7', '#eab308', '#ec4899'];
const CAT_COLORS: Record<string, string> = {
  '자유': '#3b82f6', '질문': '#22c55e', '정보공유': '#f97316',
  '분실물': '#ef4444', '학생회': '#a855f7', '동아리': '#eab308',
};

interface DailyCount { date: string; count: number; }
interface CatCount { name: string; value: number; }
interface HourCount { hour: string; count: number; }
interface TopPost { title: string; comments: number; }

export default function DashboardPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [stats, setStats] = useState({ users: 0, posts: 0, reports: 0, todayPosts: 0 });
  const [recentPosts, setRecentPosts] = useState<Post[]>([]);
  const [recentReports, setRecentReports] = useState<Report[]>([]);

  const [postTrend, setPostTrend] = useState<DailyCount[]>([]);
  const [signupTrend, setSignupTrend] = useState<DailyCount[]>([]);
  const [catDist, setCatDist] = useState<CatCount[]>([]);
  const [hourDist, setHourDist] = useState<HourCount[]>([]);
  const [reportTrend, setReportTrend] = useState<DailyCount[]>([]);
  const [topCommented, setTopCommented] = useState<TopPost[]>([]);

  useEffect(() => {
    if (!loading && !profile) router.push('/');
  }, [loading, profile, router]);

  useEffect(() => {
    if (!profile) return;
    loadData();
    loadChartData();
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

  async function loadChartData() {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 29);
    thirtyDaysAgo.setHours(0, 0, 0, 0);
    const tsThirty = Timestamp.fromDate(thirtyDaysAgo);

    const [postsSnap, usersSnap, reportsSnap] = await Promise.all([
      getDocs(query(collection(db, 'posts'), where('createdAt', '>=', tsThirty), orderBy('createdAt', 'desc'))),
      getDocs(collection(db, 'users')),
      getDocs(query(collection(db, 'reports'), where('createdAt', '>=', tsThirty))),
    ]);

    const dayMap: Record<string, number> = {};
    const catMap: Record<string, number> = {};
    const hourMap: Record<number, number> = {};
    for (let i = 0; i < 30; i++) {
      const d = new Date(thirtyDaysAgo);
      d.setDate(d.getDate() + i);
      dayMap[fmtDate(d)] = 0;
    }

    postsSnap.docs.forEach(doc => {
      const data = doc.data();
      const ts = data.createdAt as Timestamp | undefined;
      if (!ts) return;
      const dt = ts.toDate();
      const key = fmtDate(dt);
      if (key in dayMap) dayMap[key] = (dayMap[key] || 0) + 1;
      catMap[data.category] = (catMap[data.category] || 0) + 1;
      hourMap[dt.getHours()] = (hourMap[dt.getHours()] || 0) + 1;
    });

    setPostTrend(Object.entries(dayMap).map(([date, count]) => ({ date, count })));
    setCatDist(Object.entries(catMap).map(([name, value]) => ({ name, value })).sort((a, b) => b.value - a.value));
    setHourDist(Array.from({ length: 24 }, (_, i) => ({ hour: `${i}시`, count: hourMap[i] || 0 })));

    const signupMap: Record<string, number> = {};
    for (const key of Object.keys(dayMap)) signupMap[key] = 0;
    usersSnap.docs.forEach(doc => {
      const data = doc.data();
      const ts = data.createdAt as Timestamp | undefined;
      if (!ts) return;
      const key = fmtDate(ts.toDate());
      if (key in signupMap) signupMap[key] = (signupMap[key] || 0) + 1;
    });
    setSignupTrend(Object.entries(signupMap).map(([date, count]) => ({ date, count })));

    const reportDayMap: Record<string, number> = {};
    for (const key of Object.keys(dayMap)) reportDayMap[key] = 0;
    reportsSnap.docs.forEach(doc => {
      const data = doc.data();
      const ts = data.createdAt as Timestamp | undefined;
      if (!ts) return;
      const key = fmtDate(ts.toDate());
      if (key in reportDayMap) reportDayMap[key] = (reportDayMap[key] || 0) + 1;
    });
    setReportTrend(Object.entries(reportDayMap).map(([date, count]) => ({ date, count })));

    const topPosts = postsSnap.docs
      .map(doc => ({ title: doc.data().title as string, comments: (doc.data().commentCount as number) || 0 }))
      .sort((a, b) => b.comments - a.comments)
      .slice(0, 5);
    setTopCommented(topPosts);
  }

  function fmtDate(d: Date) {
    return `${d.getMonth() + 1}/${d.getDate()}`;
  }

  if (loading || !profile) return <div className="min-h-screen flex items-center justify-center">로딩중...</div>;

  const catColor: Record<string, string> = {
    '자유': 'bg-blue-100 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400',
    '질문': 'bg-green-100 dark:bg-green-900/40 text-green-600 dark:text-green-400',
    '정보공유': 'bg-orange-100 dark:bg-orange-900/40 text-orange-600 dark:text-orange-400',
  };

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6 overflow-y-auto">
        <h1 className="text-2xl font-bold mb-5">대시보드</h1>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <StatsCard label="전체 사용자" value={stats.users} />
          <StatsCard label="전체 게시글" value={stats.posts} />
          <StatsCard label="미처리 신고" value={stats.reports} color="text-red-500" />
          <StatsCard label="오늘 게시글" value={stats.todayPosts} color="text-green-500" />
        </div>

        {/* 일별 게시글 추이 + 가입자 추이 */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <ChartCard title="일별 게시글 (30일)">
            <ResponsiveContainer width="100%" height={220}>
              <LineChart data={postTrend}>
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} interval={4} stroke="#9ca3af" />
                <YAxis allowDecimals={false} tick={{ fontSize: 11 }} stroke="#9ca3af" />
                <Tooltip contentStyle={{ backgroundColor: '#1f2937', border: 'none', borderRadius: 8, fontSize: 12 }} />
                <Line type="monotone" dataKey="count" stroke="#3b82f6" strokeWidth={2} dot={false} name="게시글" />
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="일별 가입자 (30일)">
            <ResponsiveContainer width="100%" height={220}>
              <LineChart data={signupTrend}>
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} interval={4} stroke="#9ca3af" />
                <YAxis allowDecimals={false} tick={{ fontSize: 11 }} stroke="#9ca3af" />
                <Tooltip contentStyle={{ backgroundColor: '#1f2937', border: 'none', borderRadius: 8, fontSize: 12 }} />
                <Line type="monotone" dataKey="count" stroke="#22c55e" strokeWidth={2} dot={false} name="가입자" />
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>

        {/* 카테고리 분포 + 시간대별 활동 */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <ChartCard title="카테고리별 게시글 분포">
            <ResponsiveContainer width="100%" height={220}>
              <PieChart>
                <Pie data={catDist} cx="50%" cy="50%" outerRadius={80} dataKey="value" label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`} labelLine={false} fontSize={11}>
                  {catDist.map((entry, i) => (
                    <Cell key={entry.name} fill={CAT_COLORS[entry.name] || COLORS[i % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ backgroundColor: '#1f2937', border: 'none', borderRadius: 8, fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="시간대별 글 작성">
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={hourDist}>
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                <XAxis dataKey="hour" tick={{ fontSize: 10 }} interval={2} stroke="#9ca3af" />
                <YAxis allowDecimals={false} tick={{ fontSize: 11 }} stroke="#9ca3af" />
                <Tooltip contentStyle={{ backgroundColor: '#1f2937', border: 'none', borderRadius: 8, fontSize: 12 }} />
                <Bar dataKey="count" fill="#a855f7" radius={[4, 4, 0, 0]} name="글 수" />
              </BarChart>
            </ResponsiveContainer>
          </ChartCard>
        </div>

        {/* 신고 추이 + 댓글 많은 글 TOP 5 */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <ChartCard title="일별 신고 (30일)">
            <ResponsiveContainer width="100%" height={220}>
              <LineChart data={reportTrend}>
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} interval={4} stroke="#9ca3af" />
                <YAxis allowDecimals={false} tick={{ fontSize: 11 }} stroke="#9ca3af" />
                <Tooltip contentStyle={{ backgroundColor: '#1f2937', border: 'none', borderRadius: 8, fontSize: 12 }} />
                <Line type="monotone" dataKey="count" stroke="#ef4444" strokeWidth={2} dot={false} name="신고" />
              </LineChart>
            </ResponsiveContainer>
          </ChartCard>

          <ChartCard title="댓글 많은 글 TOP 5">
            <div className="space-y-2 mt-1">
              {topCommented.length === 0 ? (
                <p className="text-gray-400 text-sm">데이터 없음</p>
              ) : topCommented.map((p, i) => (
                <div key={i} className="flex items-center gap-3">
                  <span className="text-xs font-bold text-gray-400 w-5">{i + 1}</span>
                  <div className="flex-1 bg-gray-100 dark:bg-gray-800 rounded-full h-6 overflow-hidden">
                    <div className="bg-blue-500/20 h-full rounded-full flex items-center px-3"
                      style={{ width: `${Math.max((p.comments / (topCommented[0]?.comments || 1)) * 100, 20)}%` }}>
                      <span className="text-xs truncate">{p.title}</span>
                    </div>
                  </div>
                  <span className="text-xs font-semibold text-blue-500 w-8 text-right">{p.comments}</span>
                </div>
              ))}
            </div>
          </ChartCard>
        </div>

        {/* 기존 테이블 */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-white dark:bg-dark-card rounded-xl p-5 shadow-sm">
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
                    <tr key={r.id} className="border-t border-gray-50 dark:border-gray-800">
                      <td className="py-2"><Badge label={r.reason} className="bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-400" /></td>
                      <td className="py-2 text-gray-400">{formatTime(r.createdAt)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <div className="bg-white dark:bg-dark-card rounded-xl p-5 shadow-sm">
            <h3 className="font-bold mb-3">최근 게시글</h3>
            <table className="w-full text-sm">
              <thead><tr className="text-gray-400 text-xs">
                <th className="text-left pb-2">카테고리</th><th className="text-left pb-2">제목</th><th className="text-left pb-2">작성자</th>
              </tr></thead>
              <tbody>
                {recentPosts.map(p => (
                  <tr key={p.id} className="border-t border-gray-50 dark:border-gray-800 cursor-pointer hover:bg-gray-50 dark:hover:bg-dark-input"
                    onClick={() => router.push(`/posts/${p.id}`)}>
                    <td className="py-2"><Badge label={p.category} className={catColor[p.category] || 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300'} /></td>
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

function ChartCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-white dark:bg-dark-card rounded-xl p-5 shadow-sm">
      <h3 className="font-bold mb-3 text-sm">{title}</h3>
      {children}
    </div>
  );
}
