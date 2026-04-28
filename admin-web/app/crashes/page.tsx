'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import { formatTime } from '@/lib/utils';

interface CrashLog {
  id: string;
  error: string;
  stack: string;
  library: string;
  uid: string;
  createdAt: any;
}

export default function CrashesPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [crashes, setCrashes] = useState<CrashLog[]>([]);
  const [expanded, setExpanded] = useState<string | null>(null);

  useEffect(() => {
    if (!loading && !profile) router.push('/');
  }, [loading, profile, router]);

  useEffect(() => {
    if (!profile) return;
    loadCrashes();
  }, [profile]);

  async function loadCrashes() {
    const snap = await getDocs(
      query(collection(db, 'crash_logs'), orderBy('createdAt', 'desc'), limit(100))
    );
    setCrashes(snap.docs.map(doc => ({ id: doc.id, ...doc.data() } as CrashLog)));
  }

  if (loading || !profile) return null;

  return (
    <main className="flex-1 min-w-0 p-4 md:p-8 pt-14 md:pt-8">
      <h1 className="text-2xl font-bold mb-6">크래시 로그</h1>

      {crashes.length === 0 ? (
        <div className="bg-white dark:bg-dark-card rounded-xl p-12 text-center">
          <p className="text-gray-500 dark:text-gray-400 text-lg">크래시 로그가 없습니다</p>
          <p className="text-gray-400 dark:text-gray-500 text-sm mt-2">앱에서 크래시가 발생하면 여기에 표시됩니다</p>
        </div>
      ) : (
        <div className="space-y-3">
          {crashes.map((crash) => (
            <div key={crash.id}
              className="bg-white dark:bg-dark-card rounded-xl p-4 cursor-pointer hover:bg-gray-50 dark:hover:bg-white/5 transition-colors"
              onClick={() => setExpanded(expanded === crash.id ? null : crash.id)}>
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-red-600 dark:text-red-400 text-xs font-medium px-2 py-0.5 bg-red-100 dark:bg-red-400/10 rounded">
                      {crash.library || 'flutter'}
                    </span>
                    {crash.uid && (
                      <span className="text-gray-500 dark:text-gray-400 text-xs">
                        {crash.uid.substring(0, 12)}...
                      </span>
                    )}
                  </div>
                  <p className="text-sm font-mono truncate">
                    {crash.error}
                  </p>
                </div>
                <span className="text-gray-500 dark:text-gray-400 text-xs whitespace-nowrap">
                  {crash.createdAt ? formatTime(crash.createdAt) : ''}
                </span>
              </div>

              {expanded === crash.id && crash.stack && (
                <pre className="mt-3 p-3 bg-gray-100 dark:bg-black/30 rounded-lg text-xs text-gray-700 dark:text-gray-400 font-mono overflow-x-auto max-h-64 overflow-y-auto whitespace-pre-wrap break-all">
                  {crash.stack}
                </pre>
              )}
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
