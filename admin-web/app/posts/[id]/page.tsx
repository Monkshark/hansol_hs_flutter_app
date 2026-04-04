'use client';
import { useEffect, useState } from 'react';
import { doc, getDoc, deleteDoc, collection, getDocs, updateDoc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter, useParams } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Badge from '@/components/Badge';
import { Post, Comment } from '@/lib/types';
import { displayName } from '@/lib/utils';

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
    if (!snap.exists()) return;
    const postData = { id: snap.id, ...snap.data() } as Post;

    // 익명 실명 조회
    if (postData.isAnonymous) {
      try {
        const userDoc = await getDoc(doc(db, 'users', postData.authorUid));
        if (userDoc.exists()) (postData as any).authorRealName = displayName(userDoc.data() as any);
      } catch {}
    }

    const cSnap = await getDocs(collection(db, 'posts', postId, 'comments'));
    const commentList = cSnap.docs.map(d => ({ id: d.id, postId, ...d.data() } as Comment));
    postData.commentCount = commentList.length;

    // 유저 실명 맵
    const usersSnap = await getDocs(collection(db, 'users'));
    const nameMap: Record<string, string> = {};
    usersSnap.forEach(d => { nameMap[d.id] = displayName(d.data() as any); });

    // anonymousMap에서 익명 번호 추출
    const anonMap: Record<string, number> = (postData as any).anonymousMap || {};

    for (const c of commentList) {
      // 실명 매핑
      if (nameMap[c.authorUid]) (c as any).authorRealName = nameMap[c.authorUid];

      // 익명 번호 + 글쓴이 구분
      if (c.isAnonymous) {
        const isPostAuthor = c.authorUid === postData.authorUid;
        const anonNum = anonMap[c.authorUid];
        if (isPostAuthor) {
          (c as any).anonLabel = '익명(글쓴이)';
        } else if (anonNum != null) {
          (c as any).anonLabel = `익명${anonNum}`;
        } else {
          (c as any).anonLabel = '익명';
        }
      }

      // 글쓴이 여부
      (c as any).isPostAuthor = c.authorUid === postData.authorUid;
    }

    // 게시글 작성자 익명 라벨
    if (postData.isAnonymous) {
      (postData as any).anonLabel = '익명(글쓴이)';
    }

    setPost(postData);
    setComments(commentList);
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

  const likes = typeof post.likes === 'number' ? post.likes : (post.likes ? Object.keys(post.likes).length : 0);
  const dislikes = typeof post.dislikes === 'number' ? post.dislikes : (post.dislikes ? Object.keys(post.dislikes).length : 0);

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6 max-w-4xl">
        <button onClick={() => router.back()} className="text-sm text-gray-400 mb-4 hover:text-gray-600">← 뒤로</button>

        <div className="bg-white dark:bg-dark-card rounded-xl p-6 shadow-sm mb-4">
          <div className="flex items-center gap-2 mb-3">
            {post.isPinned && <span className="text-red-500">📌</span>}
            <Badge label={post.category} />
            {post.isAnonymous && <Badge label="익명" className="bg-purple-100 dark:bg-purple-900/40 text-purple-600 dark:text-purple-400" />}
          </div>
          <h1 className="text-xl font-bold mb-2">{post.title}</h1>
          <p className="text-sm text-gray-400 mb-4">
            {post.isAnonymous
              ? <>{(post as any).anonLabel} <span className="text-gray-400">({post.authorRealName})</span></>
              : post.authorName} · {post.createdAt?.toDate().toLocaleString('ko-KR')}
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

          <div className="flex gap-2 mt-4 pt-4 border-t border-gray-100 dark:border-gray-800">
            <button onClick={togglePin}
              className={`px-4 py-2 rounded-lg text-xs font-semibold ${post.isPinned ? 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300' : 'bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-400'}`}>
              {post.isPinned ? '📌 공지 해제' : '📌 공지 등록'}
            </button>
            <button onClick={handleDeletePost}
              className="px-4 py-2 bg-red-500 text-white rounded-lg text-xs font-semibold hover:bg-red-600">
              게시글 삭제
            </button>
          </div>
        </div>

        <div className="bg-white dark:bg-dark-card rounded-xl p-6 shadow-sm">
          <h3 className="font-bold mb-3">댓글 ({comments.length})</h3>
          {comments.length === 0 ? (
            <p className="text-gray-400 text-sm">댓글이 없습니다</p>
          ) : (
            <div className="space-y-3">
              {(() => {
                const parents = comments.filter(c => !(c as any).parentId);
                const childMap: Record<string, typeof comments> = {};
                comments.filter(c => (c as any).parentId).forEach(c => {
                  const pid = (c as any).parentId;
                  if (!childMap[pid]) childMap[pid] = [];
                  childMap[pid].push(c);
                });
                parents.sort((a, b) => (a.createdAt?.seconds || 0) - (b.createdAt?.seconds || 0));

                const renderName = (c: any) => {
                  if (c.isAnonymous) {
                    return <>{c.anonLabel || '익명'} <span className="text-gray-400">({c.authorRealName})</span></>;
                  }
                  return c.authorName;
                };

                return parents.map(p => (
                  <div key={p.id}>
                    <div className={`p-3 rounded-lg ${(p as any).isPostAuthor ? 'bg-blue-50 dark:bg-blue-950/50 border border-blue-200 dark:border-blue-800' : 'bg-gray-50 dark:bg-dark-input'}`}>
                      <div className="flex items-center justify-between">
                        <div className="text-xs">
                          {(p as any).isPostAuthor && <span className="text-blue-500 bg-blue-100 dark:bg-blue-900/40 px-1.5 py-0.5 rounded text-[10px] font-bold mr-1.5">글쓴이</span>}
                          <span className="font-semibold">{renderName(p)}</span>
                          <span className="text-gray-400 ml-2">{p.createdAt?.toDate().toLocaleString('ko-KR')}</span>
                        </div>
                        <button onClick={() => handleDeleteComment(p.id)}
                          className="text-xs text-red-400 hover:text-red-600">삭제</button>
                      </div>
                      <p className="text-sm mt-1">{p.content}</p>
                    </div>
                    {(childMap[p.id] || [])
                      .sort((a, b) => (a.createdAt?.seconds || 0) - (b.createdAt?.seconds || 0))
                      .map(child => (
                      <div key={child.id} className={`ml-8 mt-2 p-3 rounded-lg border-l-2 ${(child as any).isPostAuthor ? 'bg-blue-50 dark:bg-blue-950/50 border-blue-400' : 'bg-gray-50 dark:bg-dark-input border-gray-300 dark:border-gray-600'}`}>
                        <div className="flex items-center justify-between">
                          <div className="text-xs">
                            <span className="text-gray-400 font-semibold mr-1">↳</span>
                            {(child as any).isPostAuthor && <span className="text-blue-500 bg-blue-100 dark:bg-blue-900/40 px-1.5 py-0.5 rounded text-[10px] font-bold mr-1.5">글쓴이</span>}
                            <span className="font-semibold">{renderName(child)}</span>
                            <span className="text-gray-400 ml-2">{child.createdAt?.toDate().toLocaleString('ko-KR')}</span>
                          </div>
                          <button onClick={() => handleDeleteComment(child.id)}
                            className="text-xs text-red-400 hover:text-red-600">삭제</button>
                        </div>
                        <p className="text-sm mt-1">{child.content}</p>
                      </div>
                    ))}
                  </div>
                ));
              })()}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
