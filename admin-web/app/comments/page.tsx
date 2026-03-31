'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, deleteDoc, doc, getDoc, updateDoc, query, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import { formatTime } from '@/lib/utils';
import { Comment } from '@/lib/types';

export default function CommentsPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [comments, setComments] = useState<(Comment & { postTitle: string })[]>([]);
  const [search, setSearch] = useState('');

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);
  useEffect(() => { if (profile) loadComments(); }, [profile]);

  async function loadComments() {
    const postsQ = query(collection(db, 'posts'), orderBy('createdAt', 'desc'), limit(50));
    const postsSnap = await getDocs(postsQ);
    const all: (Comment & { postTitle: string })[] = [];

    for (const postDoc of postsSnap.docs) {
      const postData = postDoc.data();
      const cSnap = await getDocs(collection(db, 'posts', postDoc.id, 'comments'));
      cSnap.forEach(c => {
        all.push({ id: c.id, postId: postDoc.id, postTitle: postData.title || '', ...c.data() } as Comment & { postTitle: string });
      });
    }
    all.sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));
    setComments(all);
  }

  async function handleDelete(postId: string, commentId: string) {
    if (!confirm('이 댓글을 삭제하시겠습니까?')) return;
    await deleteDoc(doc(db, 'posts', postId, 'comments', commentId));
    const postSnap = await getDoc(doc(db, 'posts', postId));
    if (postSnap.exists()) {
      const count = postSnap.data().commentCount || 0;
      await updateDoc(doc(db, 'posts', postId), { commentCount: Math.max(0, count - 1) });
    }
    setComments(prev => prev.filter(c => c.id !== commentId));
  }

  const filtered = comments.filter(c =>
    c.content.toLowerCase().includes(search.toLowerCase()) ||
    c.authorName.toLowerCase().includes(search.toLowerCase())
  );

  if (loading || !profile) return null;

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-6">
        <h1 className="text-2xl font-bold mb-5">댓글 관리</h1>

        <input type="text" placeholder="댓글 내용 또는 작성자 검색..." value={search} onChange={e => setSearch(e.target.value)}
          className="w-full max-w-md p-3 bg-white rounded-xl mb-4 outline-none text-sm shadow-sm" />

        <div className="bg-white rounded-xl shadow-sm overflow-hidden">
          <table className="w-full text-sm">
            <thead><tr className="bg-gray-50 text-gray-400 text-xs">
              <th className="text-left p-3">글 제목</th>
              <th className="text-left p-3">댓글</th>
              <th className="text-left p-3">작성자</th>
              <th className="text-left p-3">시간</th>
              <th className="text-left p-3">액션</th>
            </tr></thead>
            <tbody>
              {filtered.map(c => (
                <tr key={c.id} className="border-t border-gray-50 hover:bg-gray-50">
                  <td className="p-3 text-primary cursor-pointer hover:underline max-w-[150px] truncate"
                    onClick={() => router.push(`/posts/${c.postId}`)}>{c.postTitle}</td>
                  <td className="p-3 max-w-[300px] truncate">{c.content}</td>
                  <td className="p-3 text-gray-500">{c.authorName}</td>
                  <td className="p-3 text-gray-400 text-xs">{formatTime(c.createdAt)}</td>
                  <td className="p-3">
                    <button onClick={() => handleDelete(c.postId, c.id)}
                      className="px-3 py-1 bg-red-500 text-white rounded-lg text-xs font-semibold">삭제</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>
    </div>
  );
}
