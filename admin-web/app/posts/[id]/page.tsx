'use client';
import { useEffect, useState } from 'react';
import { doc, getDoc, deleteDoc, collection, getDocs, updateDoc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter, useParams } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Badge from '@/components/Badge';
import { Post, Comment } from '@/lib/types';

export default function PostDetailPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const params = useParams();
  const postId = params.id as string;
  const [post, setPost] = useState<Post | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);
  useEffect(() => { if (profile && postId) loadPost(); }, [profile, postId]);

  async function loadPost() {
    const snap = await getDoc(doc(db, 'posts', postId));
    if (snap.exists()) setPost({ id: snap.id, ...snap.data() } as Post);

    const cSnap = await getDocs(collection(db, 'posts', postId, 'comments'));
    setComments(cSnap.docs.map(d => ({ id: d.id, postId, ...d.data() } as Comment)));
  }

  async function handleDeletePost() {
    if (!confirm('게시글을 삭제하시겠습니까?')) return;
    for (const c of comments) await deleteDoc(doc(db, 'posts', postId, 'comments', c.id));
    await deleteDoc(doc(db, 'posts', postId));
    router.push('/posts');
  }

  async function handleDeleteComment(commentId: string) {
    if (!confirm('댓글을 삭제하시겠습니까?')) return;
    await deleteDoc(doc(db, 'posts', postId, 'comments', commentId));
    await updateDoc(doc(db, 'posts', postId), { commentCount: Math.max(0, (post?.commentCount || 1) - 1) });
    setComments(prev => prev.filter(c => c.id !== commentId));
  }

  async function togglePin() {
    if (!post) return;
    if (!post.isPinned) {
      const allPosts = await getDocs(collection(db, 'posts'));
      const pinned = allPosts.docs.filter(d => d.data().isPinned === true);
      if (pinned.length >= 3) { alert('공지는 최대 3개까지 가능합니다'); return; }
      await updateDoc(doc(db, 'posts', postId), { isPinned: true, pinnedAt: Timestamp.now() });
    } else {
      await updateDoc(doc(db, 'posts', postId), { isPinned: false });
    }
    loadPost();
  }

  if (loading || !profile || !post) return <div className="flex min-h-screen"><Sidebar /><main className="flex-1 p-4 md:p-6 pt-14 md:pt-6">로딩중...</main></div>;

  const likes = post.likes ? Object.keys(post.likes).length : 0;
  const dislikes = post.dislikes ? Object.keys(post.dislikes).length : 0;

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6 max-w-4xl">
        <button onClick={() => router.back()} className="text-sm text-gray-400 mb-4 hover:text-gray-600">← 뒤로</button>

        <div className="bg-white rounded-xl p-6 shadow-sm mb-4">
          <div className="flex items-center gap-2 mb-3">
            {post.isPinned && <span className="text-red-500">📌</span>}
            <Badge label={post.category} />
            {post.isAnonymous && <Badge label="익명" className="bg-purple-100 text-purple-600" />}
          </div>
          <h1 className="text-xl font-bold mb-2">{post.title}</h1>
          <p className="text-sm text-gray-400 mb-4">
            {post.isAnonymous && post.authorRealName ? `익명 (${post.authorRealName})` : post.authorName} · {post.createdAt?.toDate().toLocaleString('ko-KR')}
          </p>
          <p className="text-sm leading-7 whitespace-pre-wrap mb-4">{post.content}</p>

          {post.imageUrls && post.imageUrls.length > 0 && (
            <div className="flex gap-2 mb-4 overflow-x-auto">
              {post.imageUrls.map((url, i) => (
                <img key={i} src={url} alt="" className="h-40 rounded-lg object-cover" />
              ))}
            </div>
          )}

          <div className="flex items-center gap-4 text-sm">
            <span className="text-primary font-semibold">👍 {likes}</span>
            <span className="text-red-500 font-semibold">👎 {dislikes}</span>
            <span className="text-gray-400">💬 {post.commentCount || 0}</span>
          </div>

          <div className="flex gap-2 mt-4 pt-4 border-t border-gray-100">
            <button onClick={togglePin}
              className={`px-4 py-2 rounded-lg text-xs font-semibold ${post.isPinned ? 'bg-gray-200 text-gray-600' : 'bg-red-100 text-red-600'}`}>
              {post.isPinned ? '📌 공지 해제' : '📌 공지 등록'}
            </button>
            <button onClick={handleDeletePost}
              className="px-4 py-2 bg-red-500 text-white rounded-lg text-xs font-semibold hover:bg-red-600">
              게시글 삭제
            </button>
          </div>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h3 className="font-bold mb-3">댓글 ({comments.length})</h3>
          {comments.length === 0 ? (
            <p className="text-gray-400 text-sm">댓글이 없습니다</p>
          ) : (
            <div className="space-y-3">
              {comments.map(c => (
                <div key={c.id} className={`p-3 bg-gray-50 rounded-lg ${c.replyTo ? 'ml-8 border-l-2 border-primary/30' : ''}`}>
                  <div className="flex items-center justify-between">
                    <div className="text-xs">
                      <span className="font-semibold">
                        {c.isAnonymous && c.authorRealName ? `익명 (${c.authorRealName})` : c.authorName}
                      </span>
                      <span className="text-gray-400 ml-2">{c.createdAt?.toDate().toLocaleString('ko-KR')}</span>
                    </div>
                    <button onClick={() => handleDeleteComment(c.id)}
                      className="text-xs text-red-400 hover:text-red-600">삭제</button>
                  </div>
                  {c.replyToName && <p className="text-xs text-primary font-semibold mt-1">@{c.replyToName}</p>}
                  <p className="text-sm mt-1">{c.content}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
