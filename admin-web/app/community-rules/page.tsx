'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy, limit, addDoc, serverTimestamp, doc, deleteDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import { canAccess } from '@/lib/utils';

interface Rule {
  id: string;
  version: string;
  content: string;
  effectiveDate?: any;
  publishedAt?: any;
  publishedBy?: string;
}

export default function CommunityRulesPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [rules, setRules] = useState<Rule[]>([]);
  const [version, setVersion] = useState('');
  const [content, setContent] = useState('');
  const [effectiveDate, setEffectiveDate] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!loading && !profile) router.push('/');
  }, [loading, profile, router]);

  useEffect(() => {
    if (!profile) return;
    loadRules();
  }, [profile]);

  async function loadRules() {
    const snap = await getDocs(
      query(collection(db, 'community_rules'), orderBy('publishedAt', 'desc'), limit(50))
    );
    setRules(snap.docs.map(d => ({ id: d.id, ...d.data() } as Rule)));
  }

  async function publish() {
    if (!profile) return;
    if (!version.trim() || !content.trim()) {
      alert('버전과 내용을 모두 입력해주세요');
      return;
    }
    setBusy(true);
    try {
      await addDoc(collection(db, 'community_rules'), {
        version: version.trim(),
        content: content.trim(),
        effectiveDate: effectiveDate ? new Date(effectiveDate) : null,
        publishedAt: serverTimestamp(),
        publishedBy: profile.uid,
      });
      setVersion('');
      setContent('');
      setEffectiveDate('');
      await loadRules();
    } finally {
      setBusy(false);
    }
  }

  async function remove(id: string) {
    if (!confirm('이 규정을 삭제하시겠습니까? (이전 규정은 보통 보관합니다)')) return;
    await deleteDoc(doc(db, 'community_rules', id));
    setRules(prev => prev.filter(r => r.id !== id));
  }

  if (loading || !profile) return null;
  if (!canAccess(profile.role, 'community-rules')) {
    return <main className="flex-1 p-8 text-gray-400">접근 권한이 없습니다.</main>;
  }

  return (
    <main className="flex-1 p-4 md:p-8 pt-14 md:pt-8">
      <h1 className="text-2xl font-bold mb-2">커뮤니티 규정</h1>
      <p className="text-gray-500 dark:text-gray-400 text-sm mb-6">최신 규정이 앱에서 사용자에게 표시됩니다</p>

      <div className="bg-white dark:bg-dark-card rounded-xl p-6 mb-8">
        <h2 className="font-semibold mb-4">새 규정 발행</h2>
        <div className="space-y-3">
          <div>
            <label className="text-gray-500 dark:text-gray-400 text-xs mb-1 block">버전 (예: 1.0, 2025-04-28)</label>
            <input
              type="text"
              value={version}
              onChange={(e) => setVersion(e.target.value)}
              className="w-full bg-gray-50 dark:bg-dark-bg text-gray-900 dark:text-gray-200 text-sm p-3 rounded-lg border border-gray-200 dark:border-gray-700 focus:border-primary outline-none"
            />
          </div>
          <div>
            <label className="text-gray-500 dark:text-gray-400 text-xs mb-1 block">시행일</label>
            <input
              type="date"
              value={effectiveDate}
              onChange={(e) => setEffectiveDate(e.target.value)}
              className="w-full bg-gray-50 dark:bg-dark-bg text-gray-900 dark:text-gray-200 text-sm p-3 rounded-lg border border-gray-200 dark:border-gray-700 focus:border-primary outline-none"
            />
          </div>
          <div>
            <label className="text-gray-500 dark:text-gray-400 text-xs mb-1 block">규정 본문 (Markdown 지원)</label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={12}
              className="w-full bg-gray-50 dark:bg-dark-bg text-gray-900 dark:text-gray-200 text-sm p-3 rounded-lg border border-gray-200 dark:border-gray-700 focus:border-primary outline-none resize-y font-mono"
              placeholder="# 한솔고 커뮤니티 규정&#10;&#10;1. ..."
            />
          </div>
          <button onClick={publish} disabled={busy}
            className="px-4 py-2 rounded-lg text-sm font-semibold bg-primary text-white hover:opacity-90 disabled:opacity-50">
            {busy ? '발행 중...' : '발행'}
          </button>
        </div>
      </div>

      <h2 className="font-semibold mb-3">발행 이력</h2>
      <div className="space-y-3">
        {rules.length === 0 ? (
          <div className="bg-white dark:bg-dark-card rounded-xl p-12 text-center">
            <p className="text-gray-400">발행된 규정이 없습니다</p>
          </div>
        ) : rules.map((r, i) => (
          <div key={r.id} className="bg-white dark:bg-dark-card rounded-xl p-4">
            <div className="flex items-center gap-2 mb-2">
              {i === 0 && <span className="bg-green-100 dark:bg-green-500/20 text-green-600 dark:text-green-400 text-xs font-semibold px-2 py-0.5 rounded">현재</span>}
              <span className="font-semibold">v{r.version}</span>
              {r.effectiveDate && (
                <span className="text-gray-500 dark:text-gray-400 text-xs">
                  시행: {r.effectiveDate.toDate?.().toLocaleDateString?.() ?? ''}
                </span>
              )}
              <button onClick={() => remove(r.id)}
                className="ml-auto text-red-500 dark:text-red-400 text-xs hover:underline">
                삭제
              </button>
            </div>
            <pre className="text-gray-700 dark:text-gray-300 text-sm whitespace-pre-wrap font-sans">{r.content}</pre>
          </div>
        ))}
      </div>
    </main>
  );
}
