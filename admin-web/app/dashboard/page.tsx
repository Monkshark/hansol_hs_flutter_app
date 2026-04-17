'use client';
import { useEffect, useState } from 'react';
import { collection, doc, getDoc, getDocs, query, orderBy, limit, where, Timestamp } from 'firebase/firestore';
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
const CATEGORIES = ['자유', '질문', '정보공유', '분실물', '학생회', '동아리'];

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
    const totalsDoc = await getDoc(doc(db, 'app_stats', 'totals'));
    const totals = totalsDoc.exists() ? totalsDoc.data() : {};

    const todayKey = fmtDateKey(new Date());
    const todayDoc = await getDoc(doc(db, 'app_stats', `daily_${todayKey}`));
    const todayData = todayDoc.exists() ? todayDoc.data() : {};

    setStats({
      users: totals.users || 0,
      posts: totals.posts || 0,
      reports: totals.reports || 0,
      todayPosts: todayData.posts || 0,
    });

    const [postsData, reportsData] = await Promise.all([
      getDocs(query(collection(db, 'posts'), orderBy('createdAt', 'desc'), limit(10))),
      getDocs(query(collection(db, 'reports'), orderBy('createdAt', 'desc'), limit(5))),
    ]);

    setRecentPosts(postsData.docs.map(d => ({ id: d.id, ...d.data() } as Post)));
    setRecentReports(reportsData.docs.map(d => ({ id: d.id, ...d.data() } as Report)));
  }

  async function loadChartData() {
    const days: string[] = [];
    for (let i = 29; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      days.push(fmtDateKey(d));
    }

    const dailyDocs = await Promise.all(
      days.map(key => getDoc(doc(db, 'app_stats', `daily_${key}`)))
    );

    const postTrendData: DailyCount[] = [];
    const signupTrendData: DailyCount[] = [];
    const reportTrendData: DailyCount[] = [];
    const catAccum: Record<string, number> = {};
    const hourAccum: Record<number, number> = {};

    days.forEach((key, i) => {
      const data = dailyDocs[i].exists() ? dailyDocs[i].data()! : {};
      const label = fmtDateLabel(key);

      postTrendData.push({ date: label, count: data.posts || 0 });
      signupTrendData.push({ date: label, count: data.users || 0 });
      reportTrendData.push({ date: label, count: data.reports || 0 });

      for (const cat of CATEGORIES) {
        const val = data[`cat_${cat}`] || 0;
        if (val > 0) catAccum[cat] = (catAccum[cat] || 0) + val;
      }

      for (let h = 0; h < 24; h++) {
        const val = data[`hour_${h}`] || 0;
        if (val > 0) hourAccum[h] = (hourAccum[h] || 0) + val;
      }
    });

    setPostTrend(postTrendData);
    setSignupTrend(signupTrendData);
    setReportTrend(reportTrendData);
    setCatDist(
      Object.entries(catAccum)
        .map(([name, value]) => ({ name, value }))
        .sort((a, b) => b.value - a.value)
    );
    setHourDist(Array.from({ length: 24 }, (_, i) => ({ hour: `${i}시`, count: hourAccum[i] || 0 })));

    const topPosts = await getDocs(
      query(collection(db, 'posts'), orderBy('commentCount', 'desc'), limit(5))
    );
    setTopCommented(
      topPosts.docs.map(d => ({
        title: d.data().title as string,
        comments: (d.data().commentCount as number) || 0,
      }))
    );
  }

  function fmtDateKey(d: Date) {
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    return `${yyyy}-${mm}-${dd}`;
  }

  function fmtDateLabel(key: string) {
    const parts = key.split('-');
    return `${parseInt(parts[1])}/${parseInt(parts[2])}`;
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
