'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, deleteDoc, doc, query, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Badge from '@/components/Badge';
import { formatTime, displayName } from '@/lib/utils';
import { Post } from '@/lib/types';

export default function PostsPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [posts, setPosts] = useState<Post[]>([]);
  const [search, setSearch] = useState('');

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);
  useEffect(() => { if (profile) loadPosts(); }, [profile]);

  async function loadPosts() {
    const q = query(collection(db, 'posts'), orderBy('createdAt', 'desc'), limit(100));
    const snap = await getDocs(q);
    const postList = snap.docs.map(d => ({ id: d.id, ...d.data() } as Post));

    // 유저 정보 맵
    const userMap: Record<string, any> = {};
    try {
      const usersSnap = await getDocs(collection(db, 'users'));
      usersSnap.forEach(d => { userMap[d.id] = d.data(); });
    } catch {}

    for (const p of postList) {
      const user = userMap[p.authorUid];
      if (p.isAnonymous && user) {
        (p as any).authorRealName = displayName(user);
      }
    }

    setPosts(postList);
  }

  async function handleDelete(id: string) {
    if (!confirm('이 게시글을 삭제하시겠습니까?')) return;
    const comments = await getDocs(collection(db, 'posts', id, 'comments'));
    for (const c of comments.docs) await deleteDoc(c.ref);
    await deleteDoc(doc(db, 'posts', id));
    setPosts(prev => prev.filter(p => p.id !== id));
  }

  const filtered = posts.filter(p =>
    p.title.toLowerCase().includes(search.toLowerCase()) ||
    p.authorName.toLowerCase().includes(search.toLowerCase())
  );

  const catColor: Record<string, string> = {
    '자유': 'bg-blue-100 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400',
    '질문': 'bg-green-100 dark:bg-green-900/40 text-green-600 dark:text-green-400',
    '정보공유': 'bg-orange-100 dark:bg-orange-900/40 text-orange-600 dark:text-orange-400',
    '분실물': 'bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-400',
    '학생회': 'bg-emerald-100 dark:bg-emerald-900/40 text-emerald-600 dark:text-emerald-400',
    '동아리': 'bg-purple-100 dark:bg-purple-900/40 text-purple-600 dark:text-purple-400',
  };

  if (loading || !profile) return null;

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6">
        <h1 className="text-2xl font-bold mb-5">게시글 관리</h1>

        <input type="text" placeholder="제목 또는 작성자 검색..." value={search} onChange={e => setSearch(e.target.value)}
          className="w-full md:max-w-md p-3 bg-white dark:bg-dark-card rounded-xl mb-4 outline-none text-sm shadow-sm" />

        <div className="bg-white dark:bg-dark-card rounded-xl shadow-sm overflow-hidden overflow-x-auto">
          <table className="w-full text-sm min-w-[700px]">
            <thead><tr className="bg-gray-50 dark:bg-dark-input text-gray-400 dark:text-gray-500 text-xs">
              <th className="text-left p-3">카테고리</th>
              <th className="text-left p-3">제목</th>
              <th className="text-left p-3">작성자</th>
              <th className="text-left p-3">추천</th>
              <th className="text-left p-3">댓글</th>
              <th className="text-left p-3">작성일</th>
              <th className="text-left p-3">액션</th>
            </tr></thead>
            <tbody>
              {filtered.map(p => {
                const likes = typeof p.likes === 'number' ? p.likes : (p.likes ? Object.keys(p.likes).length : 0);
                const dislikes = typeof p.dislikes === 'number' ? p.dislikes : (p.dislikes ? Object.keys(p.dislikes).length : 0);
                return (
                  <tr key={p.id} className="border-t border-gray-50 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-input">
                    <td className="p-3">
                      {p.isPinned && <span className="text-red-500 mr-1">📌</span>}
                      <Badge label={p.category} className={catColor[p.category] || 'bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300'} />
                    </td>
                    <td className="p-3 cursor-pointer hover:text-primary" onClick={() => router.push(`/posts/${p.id}`)}>
                      {p.title}
                      {p.isAnonymous && <Badge label="익명" className="bg-purple-100 dark:bg-purple-900/40 text-purple-600 dark:text-purple-400 ml-2" />}
                    </td>
                    <td className="p-3 text-gray-500">
                      {p.isAnonymous && (p as any).authorRealName
                        ? <>익명 <span className="text-gray-400">({(p as any).authorRealName})</span></>
                        : p.authorName}
                    </td>
                    <td className="p-3">
                      <span className="text-primary">+{likes}</span>{' '}
                      <span className="text-red-500">-{dislikes}</span>
                    </td>
                    <td className="p-3">{p.commentCount || 0}</td>
                    <td className="p-3 text-gray-400 text-xs">{formatTime(p.createdAt)}</td>
                    <td className="p-3">
                      <button onClick={() => handleDelete(p.id)}
                        className="px-3 py-1 bg-red-500 text-white rounded-lg text-xs font-semibold hover:bg-red-600">
                        삭제
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}
