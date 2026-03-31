'use client';
import { useEffect, useState } from 'react';
import { doc, getDoc, setDoc, collection, getDocs, updateDoc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';

export default function SettingsPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [latest, setLatest] = useState('');
  const [min, setMin] = useState('');
  const [updateUrl, setUpdateUrl] = useState('');
  const [message, setMessage] = useState('');
  const [saved, setSaved] = useState(false);
  const [pinnedPosts, setPinnedPosts] = useState<{ id: string; title: string }[]>([]);

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);
  useEffect(() => { if (profile) { loadConfig(); loadPinned(); } }, [profile]);

  async function loadConfig() {
    const snap = await getDoc(doc(db, 'app_config', 'version'));
    if (snap.exists()) {
      const d = snap.data();
      setLatest(d.latest || '');
      setMin(d.min || '');
      setUpdateUrl(d.updateUrl || '');
      setMessage(d.message || '');
    }
  }

  async function loadPinned() {
    const snap = await getDocs(collection(db, 'posts'));
    const pinned = snap.docs
      .filter(d => d.data().isPinned === true)
      .map(d => ({ id: d.id, title: d.data().title }));
    setPinnedPosts(pinned);
  }

  async function saveConfig() {
    await setDoc(doc(db, 'app_config', 'version'), { latest, min, updateUrl, message });
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  }

  async function unpinPost(postId: string) {
    await updateDoc(doc(db, 'posts', postId), { isPinned: false });
    setPinnedPosts(prev => prev.filter(p => p.id !== postId));
  }

  if (loading || !profile) return null;

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6 max-w-3xl">
        <h1 className="text-2xl font-bold mb-5">설정</h1>

        <div className="bg-white rounded-xl p-6 shadow-sm mb-4">
          <h3 className="font-bold mb-4">앱 버전 관리</h3>
          <p className="text-sm text-gray-400 mb-4">버전을 설정하면 앱에서 업데이트 알림을 표시합니다.</p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="text-xs text-gray-500 font-semibold">최신 버전 (latest)</label>
              <input value={latest} onChange={e => setLatest(e.target.value)} placeholder="1.1.0"
                className="w-full p-3 bg-gray-50 rounded-xl mt-1 outline-none text-sm" />
            </div>
            <div>
              <label className="text-xs text-gray-500 font-semibold">최소 버전 (min)</label>
              <input value={min} onChange={e => setMin(e.target.value)} placeholder="1.0.0"
                className="w-full p-3 bg-gray-50 rounded-xl mt-1 outline-none text-sm" />
            </div>
          </div>

          <div className="mb-4">
            <label className="text-xs text-gray-500 font-semibold">업데이트 URL</label>
            <input value={updateUrl} onChange={e => setUpdateUrl(e.target.value)} placeholder="https://play.google.com/..."
              className="w-full p-3 bg-gray-50 rounded-xl mt-1 outline-none text-sm" />
          </div>

          <div className="mb-4">
            <label className="text-xs text-gray-500 font-semibold">메시지</label>
            <textarea value={message} onChange={e => setMessage(e.target.value)} rows={3}
              placeholder="새로운 기능이 추가되었습니다."
              className="w-full p-3 bg-gray-50 rounded-xl mt-1 outline-none text-sm resize-none" />
          </div>

          <div className="flex items-center gap-3">
            <button onClick={saveConfig}
              className="px-6 py-2 bg-primary text-white rounded-xl font-semibold hover:bg-primary-dark transition text-sm">
              저장
            </button>
            {saved && <span className="text-green-500 text-sm">저장 완료!</span>}
          </div>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-sm">
          <h3 className="font-bold mb-3">공지 관리 ({pinnedPosts.length}/3)</h3>
          {pinnedPosts.length === 0 ? (
            <p className="text-gray-400 text-sm">등록된 공지가 없습니다</p>
          ) : (
            <div className="space-y-2">
              {pinnedPosts.map(p => (
                <div key={p.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <span className="text-sm">📌 {p.title}</span>
                  <button onClick={() => unpinPost(p.id)}
                    className="px-3 py-1 bg-gray-400 text-white rounded-lg text-xs font-semibold">해제</button>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
