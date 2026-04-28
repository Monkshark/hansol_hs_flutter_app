'use client';
import { useEffect, useState } from 'react';
import { doc, getDoc, collection, getDocs, query, where, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter, useParams } from 'next/navigation';
import Badge from '@/components/Badge';
import { formatTime, roleBadge, isSuspended, suspendRemaining } from '@/lib/utils';
import { UserProfile, Post } from '@/lib/types';

export default function UserDetailPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const params = useParams();
  const userId = params.id as string;
  const [user, setUser] = useState<UserProfile | null>(null);
  const [posts, setPosts] = useState<Post[]>([]);

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);
  useEffect(() => { if (profile && userId) loadUser(); }, [profile, userId]);

  async function loadUser() {
    const snap = await getDoc(doc(db, 'users', userId));
    if (snap.exists()) setUser({ ...snap.data(), uid: snap.id } as UserProfile);

    const postsQ = query(collection(db, 'posts'), where('authorUid', '==', userId), orderBy('createdAt', 'desc'), limit(20));
    try {
      const postsSnap = await getDocs(postsQ);
      setPosts(postsSnap.docs.map(d => ({ id: d.id, ...d.data() } as Post)));
    } catch { setPosts([]); }
  }

  if (loading || !profile || !user) return <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6">로딩중...</main>;

  const badge = roleBadge(user.role);
  const suspended = isSuspended(user.suspendedUntil);
  const typeLabels: Record<string, string> = { student: '재학생', graduate: '졸업생', teacher: '교사', parent: '학부모' };

  return (
    <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6 max-w-4xl">
        <button onClick={() => router.back()} className="text-sm text-gray-400 mb-4 hover:text-gray-600">← 뒤로</button>

        <div className="bg-white dark:bg-dark-card rounded-xl p-6 shadow-sm mb-4">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-14 h-14 rounded-full bg-primary flex items-center justify-center text-white text-xl font-bold">
              {user.name?.[0] || '?'}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl font-bold">{user.name}</h1>
                {badge && <Badge label={badge.label} className={badge.color} />}
                {suspended && <Badge label="정지" className="bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-400" />}
              </div>
              <p className="text-sm text-gray-400">{user.email}</p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div><span className="text-gray-400">신분:</span> {typeLabels[user.userType] || user.userType}</div>
            <div><span className="text-gray-400">학번:</span> {user.studentId || '-'}</div>
            <div><span className="text-gray-400">학년/반:</span> {user.grade}학년 {user.classNum}반</div>
            <div><span className="text-gray-400">승인:</span> {user.approved ? '승인됨' : '대기중'}</div>
            <div><span className="text-gray-400">로그인:</span> {
              (user as any).loginProvider === 'kakao' ? 'Kakao' :
              (user as any).loginProvider === 'apple' ? 'Apple' : 'Google'
            }</div>
            {user.graduationYear && <div><span className="text-gray-400">졸업연도:</span> {user.graduationYear}</div>}
            {user.teacherSubject && <div><span className="text-gray-400">담당과목:</span> {user.teacherSubject}</div>}
            {suspended && <div><span className="text-gray-400">정지 남은 기간:</span> <span className="text-red-500 font-semibold">{suspendRemaining(user.suspendedUntil)}</span></div>}
          </div>
        </div>

        <div className="bg-white dark:bg-dark-card rounded-xl p-6 shadow-sm">
          <h3 className="font-bold mb-3">작성한 글 ({posts.length})</h3>
          {posts.length === 0 ? (
            <p className="text-gray-400 text-sm">작성한 글이 없습니다</p>
          ) : (
            <div className="space-y-2">
              {posts.map(p => (
                <div key={p.id} className="p-3 bg-gray-50 dark:bg-dark-input rounded-lg cursor-pointer hover:bg-gray-100 flex items-center gap-3"
                  onClick={() => router.push(`/posts/${p.id}`)}>
                  <Badge label={p.category} className="bg-blue-100 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400" />
                  <span className="text-sm flex-1">{p.title}</span>
                  <span className="text-xs text-gray-400">{formatTime(p.createdAt)}</span>
                </div>
              ))}
            </div>
          )}
        </div>
    </main>
  );
}
