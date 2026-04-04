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
  const [updateUrlAndroid, setUpdateUrlAndroid] = useState('');
  const [updateUrlIOS, setUpdateUrlIOS] = useState('');
  // 팝업
  const [popupActive, setPopupActive] = useState(false);
  const [popupType, setPopupType] = useState('notice');
  const [popupTitle, setPopupTitle] = useState('');
  const [popupContent, setPopupContent] = useState('');
  const [popupStart, setPopupStart] = useState('');
  const [popupEnd, setPopupEnd] = useState('');
  const [popupDismissible, setPopupDismissible] = useState(true);
  const [popupSaved, setPopupSaved] = useState(false);
  const [message, setMessage] = useState('');
  const [saved, setSaved] = useState(false);
  const [pinnedPosts, setPinnedPosts] = useState<{ id: string; title: string }[]>([]);

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);
  useEffect(() => { if (profile) { loadConfig(); loadPinned(); loadPopup(); } }, [profile]);

  async function loadConfig() {
    const snap = await getDoc(doc(db, 'app_config', 'version'));
    if (snap.exists()) {
      const d = snap.data();
      setLatest(d.latest || '');
      setMin(d.min || '');
      setUpdateUrlAndroid(d.updateUrlAndroid || d.updateUrl || '');
      setUpdateUrlIOS(d.updateUrlIOS || '');
      setMessage(d.message || '');
    }
  }

  async function loadPopup() {
    const snap = await getDoc(doc(db, 'app_config', 'popup'));
    if (snap.exists()) {
      const d = snap.data();
      setPopupActive(d.active || false);
      setPopupType(d.type || 'notice');
      setPopupTitle(d.title || '');
      setPopupContent(d.content || '');
      setPopupStart(d.startDate || '');
      setPopupEnd(d.endDate || '');
      setPopupDismissible(d.dismissible ?? true);
    }
  }

  async function savePopup() {
    await setDoc(doc(db, 'app_config', 'popup'), {
      active: popupActive, type: popupType, title: popupTitle,
      content: popupContent, startDate: popupStart, endDate: popupEnd, dismissible: popupDismissible,
    });
    setPopupSaved(true);
    setTimeout(() => setPopupSaved(false), 3000);
  }

  async function loadPinned() {
    const snap = await getDocs(collection(db, 'posts'));
    const pinned = snap.docs
      .filter(d => d.data().isPinned === true)
      .map(d => ({ id: d.id, title: d.data().title }));
    setPinnedPosts(pinned);
  }

  async function saveConfig() {
    await setDoc(doc(db, 'app_config', 'version'), { latest, min, updateUrlAndroid, updateUrlIOS, message });
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

        <div className="bg-white dark:bg-dark-card rounded-xl p-6 shadow-sm mb-4">
          <h3 className="font-bold mb-4">앱 버전 관리</h3>
          <p className="text-sm text-gray-400 mb-4">버전을 설정하면 앱에서 업데이트 알림을 표시합니다.</p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="text-xs text-gray-500 font-semibold">최신 버전 (latest)</label>
              <input value={latest} onChange={e => setLatest(e.target.value)} placeholder="1.1.0"
                className="w-full p-3 bg-gray-50 dark:bg-dark-input dark:text-gray-100 rounded-xl mt-1 outline-none text-sm" />
            </div>
            <div>
              <label className="text-xs text-gray-500 font-semibold">최소 버전 (min)</label>
              <input value={min} onChange={e => setMin(e.target.value)} placeholder="1.0.0"
                className="w-full p-3 bg-gray-50 dark:bg-dark-input dark:text-gray-100 rounded-xl mt-1 outline-none text-sm" />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label className="text-xs text-gray-500 font-semibold">Android 업데이트 URL</label>
              <input value={updateUrlAndroid} onChange={e => setUpdateUrlAndroid(e.target.value)} placeholder="https://play.google.com/..."
                className="w-full p-3 bg-gray-50 dark:bg-dark-input dark:text-gray-100 rounded-xl mt-1 outline-none text-sm" />
            </div>
            <div>
              <label className="text-xs text-gray-500 font-semibold">iOS 업데이트 URL</label>
              <input value={updateUrlIOS} onChange={e => setUpdateUrlIOS(e.target.value)} placeholder="https://apps.apple.com/..."
                className="w-full p-3 bg-gray-50 dark:bg-dark-input dark:text-gray-100 rounded-xl mt-1 outline-none text-sm" />
            </div>
          </div>

          <div className="mb-4">
            <label className="text-xs text-gray-500 font-semibold">메시지</label>
            <textarea value={message} onChange={e => setMessage(e.target.value)} rows={3}
              placeholder="새로운 기능이 추가되었습니다."
              className="w-full p-3 bg-gray-50 dark:bg-dark-input dark:text-gray-100 rounded-xl mt-1 outline-none text-sm resize-none" />
          </div>

          <div className="flex items-center gap-3">
            <button onClick={saveConfig}
              className="px-6 py-2 bg-primary text-white rounded-xl font-semibold hover:bg-primary-dark transition text-sm">
              저장
            </button>
            {saved && <span className="text-green-500 text-sm">저장 완료!</span>}
          </div>
        </div>

        <div className="bg-white dark:bg-dark-card rounded-xl p-6 shadow-sm">
          <h3 className="font-bold mb-3">공지 관리 ({pinnedPosts.length}/3)</h3>
          {pinnedPosts.length === 0 ? (
            <p className="text-gray-400 text-sm">등록된 공지가 없습니다</p>
          ) : (
            <div className="space-y-2">
              {pinnedPosts.map(p => (
                <div key={p.id} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-dark-input rounded-lg">
                  <span className="text-sm">📌 {p.title}</span>
                  <button onClick={() => unpinPost(p.id)}
                    className="px-3 py-1 bg-gray-400 text-white rounded-lg text-xs font-semibold">해제</button>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="bg-white dark:bg-dark-card rounded-xl p-6 shadow-sm mt-4">
          <h3 className="font-bold mb-4">긴급 팝업 공지</h3>
          <p className="text-sm text-gray-400 mb-4">앱 실행 시 사용자에게 팝업을 표시합니다.</p>

          <div className="flex items-center gap-3 mb-4">
            <label className="text-sm font-semibold">활성화</label>
            <button onClick={() => setPopupActive(!popupActive)}
              className={`px-4 py-1.5 rounded-full text-xs font-semibold ${popupActive ? 'bg-red-500 text-white' : 'bg-gray-200 dark:bg-dark-input text-gray-500'}`}>
              {popupActive ? 'ON' : 'OFF'}
            </button>
          </div>

          <div className="flex gap-2 mb-4">
            {['emergency', 'notice', 'event'].map(t => (
              <button key={t} onClick={() => setPopupType(t)}
                className={`px-4 py-1.5 rounded-full text-xs font-semibold transition ${
                  popupType === t
                    ? t === 'emergency' ? 'bg-red-500 text-white' : t === 'event' ? 'bg-green-500 text-white' : 'bg-primary text-white'
                    : 'bg-gray-100 dark:bg-dark-input text-gray-500'
                }`}>
                {t === 'emergency' ? '긴급' : t === 'event' ? '이벤트' : '공지'}
              </button>
            ))}
          </div>

          <input value={popupTitle} onChange={e => setPopupTitle(e.target.value)} placeholder="제목"
            className="w-full p-3 bg-gray-50 dark:bg-dark-input dark:text-gray-100 rounded-xl mb-3 outline-none text-sm" />
          <textarea value={popupContent} onChange={e => setPopupContent(e.target.value)} rows={3} placeholder="내용"
            className="w-full p-3 bg-gray-50 dark:bg-dark-input dark:text-gray-100 rounded-xl mb-3 outline-none text-sm resize-none" />

          <div className="grid grid-cols-2 gap-3 mb-3">
            <input type="date" value={popupStart} onChange={e => setPopupStart(e.target.value)}
              className="p-3 bg-gray-50 dark:bg-dark-input dark:text-gray-100 rounded-xl outline-none text-sm" />
            <input type="date" value={popupEnd} onChange={e => setPopupEnd(e.target.value)}
              className="p-3 bg-gray-50 dark:bg-dark-input dark:text-gray-100 rounded-xl outline-none text-sm" />
          </div>

          <div className="flex items-center gap-3 mb-4">
            <label className="text-sm text-gray-500">"오늘 안 보기" 허용</label>
            <button onClick={() => setPopupDismissible(!popupDismissible)}
              className={`px-4 py-1.5 rounded-full text-xs font-semibold ${popupDismissible ? 'bg-primary text-white' : 'bg-gray-200 dark:bg-dark-input text-gray-500'}`}>
              {popupDismissible ? 'ON' : 'OFF'}
            </button>
          </div>

          <div className="flex items-center gap-3">
            <button onClick={savePopup}
              className="px-6 py-2 bg-red-500 text-white rounded-xl font-semibold hover:bg-red-600 transition text-sm">
              저장
            </button>
            {popupSaved && <span className="text-green-500 text-sm">저장 완료!</span>}
          </div>
        </div>
      </main>
    </div>
  );
}
