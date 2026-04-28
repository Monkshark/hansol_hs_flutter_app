'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, query, orderBy, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import { formatTime } from '@/lib/utils';

interface FunctionLog {
  id: string;
  function: string;
  error: string;
  code: string;
  stack: string;
  createdAt: any;
  [key: string]: any;
}

export default function FunctionLogsPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [logs, setLogs] = useState<FunctionLog[]>([]);
  const [expanded, setExpanded] = useState<string | null>(null);

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);
  useEffect(() => { if (profile) loadLogs(); }, [profile]);

  async function loadLogs() {
    const snap = await getDocs(
      query(collection(db, 'function_logs'), orderBy('createdAt', 'desc'), limit(100))
    );
    setLogs(snap.docs.map(d => ({ id: d.id, ...d.data() } as FunctionLog)));
  }

  if (loading || !profile) return null;

  return (
    <main className="flex-1 min-w-0 p-4 md:p-8 pt-14 md:pt-8">
      <h1 className="text-2xl font-bold mb-6">Cloud Functions 로그</h1>

      {logs.length === 0 ? (
        <div className="bg-white dark:bg-dark-card rounded-xl p-12 text-center">
          <p className="text-gray-500 dark:text-gray-400 text-lg">에러 로그가 없습니다</p>
          <p className="text-gray-400 dark:text-gray-500 text-sm mt-2">Cloud Functions에서 에러가 발생하면 여기에 표시됩니다</p>
        </div>
      ) : (
        <div className="space-y-3">
          {logs.map((log) => (
            <div key={log.id}
              className="bg-white dark:bg-dark-card rounded-xl p-4 cursor-pointer hover:bg-gray-50 dark:hover:bg-dark-input transition-colors"
              onClick={() => setExpanded(expanded === log.id ? null : log.id)}>
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1 flex-wrap">
                    <span className="text-orange-600 dark:text-orange-400 text-xs font-medium px-2 py-0.5 bg-orange-100 dark:bg-orange-400/10 rounded">
                      {log.function}
                    </span>
                    {log.code && (
                      <span className="text-red-600 dark:text-red-400 text-xs font-medium px-2 py-0.5 bg-red-100 dark:bg-red-400/10 rounded">
                        {log.code}
                      </span>
                    )}
                  </div>
                  <p className="text-sm font-mono truncate">{log.error}</p>
                </div>
                <span className="text-gray-500 dark:text-gray-400 text-xs whitespace-nowrap">
                  {log.createdAt ? formatTime(log.createdAt) : ''}
                </span>
              </div>

              {expanded === log.id && (
                <div className="mt-3 space-y-2">
                  {log.stack && (
                    <pre className="p-3 bg-gray-100 dark:bg-dark-input rounded-lg text-xs text-gray-700 dark:text-gray-400 font-mono overflow-x-auto max-h-48 overflow-y-auto whitespace-pre-wrap break-all">
                      {log.stack}
                    </pre>
                  )}
                  <div className="flex flex-wrap gap-2 text-xs text-gray-500 dark:text-gray-400">
                    {Object.entries(log)
                      .filter(([k]) => !['id', 'function', 'error', 'code', 'stack', 'createdAt'].includes(k))
                      .map(([k, v]) => (
                        <span key={k} className="bg-gray-100 dark:bg-dark-input px-2 py-1 rounded break-all">
                          {k}: {String(v)}
                        </span>
                      ))}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
