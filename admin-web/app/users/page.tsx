'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, deleteDoc, updateDoc, doc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import Badge from '@/components/Badge';
import { isSuspended, suspendRemaining, roleBadge } from '@/lib/utils';
import { UserProfile } from '@/lib/types';
import { useCached, invalidateCache } from '@/lib/cache';
import { writeAdminLog } from '@/lib/adminLog';

type Tab = 'approved' | 'pending' | 'suspended';

export default function UsersPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [tab, setTab] = useState<Tab>('approved');
  const [search, setSearch] = useState('');

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);

  const { data: users = [], setData: setUsers, refresh: refreshUsers } = useCached<UserProfile[]>(
    profile ? 'users:list' : null,
    async () => {
      const snap = await getDocs(collection(db, 'users'));
      return snap.docs.map(d => ({ ...d.data(), uid: d.id } as UserProfile));
    },
    { ttlMs: 60_000 }
  );

  const filtered = (users || []).filter(u => {
    const suspended = isSuspended(u.suspendedUntil);
    if (tab === 'pending') return !u.approved;
    if (tab === 'suspended') return u.approved && suspended;
    if (tab === 'approved') return u.approved && !suspended;
    return false;
  }).filter(u =>
    !search || u.name?.toLowerCase().includes(search.toLowerCase()) || u.studentId?.includes(search)
  );

  if (tab === 'approved') {
    const roleOrder: Record<string, number> = { admin: 0, manager: 1, moderator: 2, auditor: 3, user: 4 };
    filtered.sort((a, b) => (roleOrder[a.role] ?? 4) - (roleOrder[b.role] ?? 4));
  }

  function findUser(uid: string): UserProfile | undefined {
    return (users || []).find(u => u.uid === uid);
  }

  async function approve(uid: string) {
    const target = findUser(uid);
    await updateDoc(doc(db, 'users', uid), { approved: true });
    setUsers(prev => (prev || []).map(u => u.uid === uid ? { ...u, approved: true } : u));
    await writeAdminLog(profile, 'approve_user', { targetUid: uid, targetName: target?.name ?? '' });
  }

  async function reject(uid: string) {
    if (!confirm('가입을 거절하시겠습니까?')) return;
    const target = findUser(uid);
    await deleteDoc(doc(db, 'users', uid));
    setUsers(prev => (prev || []).filter(u => u.uid !== uid));
    await writeAdminLog(profile, 'reject_user', { targetUid: uid, targetName: target?.name ?? '' });
  }

  async function setRole(uid: string, role: string) {
    const labels: Record<string, string> = { admin: 'Admin', manager: '매니저', moderator: '모더레이터', auditor: '감사자', user: '일반' };
    if (!confirm(`${labels[role]}(으)로 변경하시겠습니까?`)) return;
    const target = findUser(uid);
    const previousRole = target?.role ?? 'user';
    await updateDoc(doc(db, 'users', uid), { role });
    setUsers(prev => (prev || []).map(u => u.uid === uid ? { ...u, role: role as UserProfile['role'] } : u));
    await writeAdminLog(profile, 'change_role', {
      targetUid: uid,
      targetName: target?.name ?? '',
      previousRole,
      newRole: role,
    });
  }

  async function suspend(uid: string, hours: number) {
    const target = findUser(uid);
    const until = new Date(Date.now() + hours * 3600000);
    await updateDoc(doc(db, 'users', uid), { suspendedUntil: Timestamp.fromDate(until) });
    invalidateCache('users:');
    refreshUsers();
    await writeAdminLog(profile, 'suspend_user', { targetUid: uid, targetName: target?.name ?? '', hours });
  }

  async function unsuspend(uid: string) {
    const target = findUser(uid);
    await updateDoc(doc(db, 'users', uid), { suspendedUntil: null });
    invalidateCache('users:');
    refreshUsers();
    await writeAdminLog(profile, 'unsuspend_user', { targetUid: uid, targetName: target?.name ?? '' });
  }

  async function deleteUser(uid: string) {
    if (!confirm('계정을 삭제하시겠습니까?')) return;
    if (!confirm('정말 삭제합니까? 되돌릴 수 없습니다.')) return;
    const target = findUser(uid);
    await deleteDoc(doc(db, 'users', uid));
    setUsers(prev => (prev || []).filter(u => u.uid !== uid));
    await writeAdminLog(profile, 'delete_user', { targetUid: uid, targetName: target?.name ?? '' });
  }

  const suspendOptions = [
    { label: '1시간', hours: 1 }, { label: '6시간', hours: 6 }, { label: '12시간', hours: 12 },
    { label: '1일', hours: 24 }, { label: '3일', hours: 72 }, { label: '7일', hours: 168 }, { label: '30일', hours: 720 },
  ];

  if (loading || !profile) return null;

  const tabs: { key: Tab; label: string; color: string }[] = [
    { key: 'pending', label: '승인 대기', color: 'bg-orange-500' },
    { key: 'approved', label: '사용자', color: 'bg-primary' },
    { key: 'suspended', label: '정지', color: 'bg-red-500' },
  ];

  return (
    <main className="flex-1 p-4 md:p-6 pt-14 md:pt-6">
      <h1 className="text-2xl font-bold mb-5">사용자 관리</h1>

      <div className="flex flex-wrap gap-2 mb-4">
        {tabs.map(t => (
          <button key={t.key} onClick={() => setTab(t.key)}
            className={`px-4 py-2 rounded-lg text-sm font-semibold transition ${
              tab === t.key ? `${t.color} text-white` : 'bg-gray-100 dark:bg-dark-input text-gray-500 dark:text-gray-400'
            }`}>{t.label}</button>
        ))}
      </div>

      <input type="text" placeholder="이름 또는 학번 검색..." value={search} onChange={e => setSearch(e.target.value)}
        className="w-full md:max-w-md p-3 bg-white dark:bg-dark-card text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 rounded-xl mb-4 outline-none text-sm shadow-sm" />

      <div className="bg-white dark:bg-dark-card rounded-xl shadow-sm overflow-hidden overflow-x-auto">
        {filtered.length === 0 ? (
          <p className="p-6 text-gray-400 text-sm">사용자가 없습니다</p>
        ) : (
          <table className="w-full text-sm min-w-[600px]">
            <thead><tr className="bg-gray-50 dark:bg-dark-input text-gray-400 dark:text-gray-500 text-xs">
              <th className="text-left p-3">이름</th>
              <th className="text-left p-3">학번</th>
              <th className="text-left p-3">학년/반</th>
              <th className="text-left p-3">로그인</th>
              {tab === 'suspended' && <th className="text-left p-3">남은 기간</th>}
              <th className="text-left p-3">액션</th>
            </tr></thead>
            <tbody>
              {filtered.map(u => {
                const badge = roleBadge(u.role);
                return (
                  <tr key={u.uid} className="border-t border-gray-50 dark:border-gray-800 hover:bg-gray-50 dark:hover:bg-dark-input">
                    <td className="p-3">
                      <span className="cursor-pointer hover:text-primary" onClick={() => router.push(`/users/${u.uid}`)}>
                        {u.name || '-'}
                      </span>
                      {badge && <Badge label={badge.label} className={`ml-2 ${badge.color}`} />}
                    </td>
                    <td className="p-3 text-gray-500 dark:text-gray-400">{u.studentId || '-'}</td>
                    <td className="p-3 text-gray-500 dark:text-gray-400">{u.grade || '-'}학년 {u.classNum || '-'}반</td>
                    <td className="p-3">
                      <span className={`text-xs font-semibold ${
                        (u as any).loginProvider === 'kakao' ? 'text-yellow-600 dark:text-yellow-400' :
                        (u as any).loginProvider === 'apple' ? 'text-gray-600 dark:text-gray-300' : 'text-blue-500 dark:text-blue-400'
                      }`}>
                        {(u as any).loginProvider === 'kakao' ? 'Kakao' :
                         (u as any).loginProvider === 'apple' ? 'Apple' : 'Google'}
                      </span>
                    </td>
                    {tab === 'suspended' && (
                      <td className="p-3 text-red-500 dark:text-red-400 font-semibold text-xs">{suspendRemaining(u.suspendedUntil)}</td>
                    )}
                    <td className="p-3 flex gap-1 flex-wrap">
                      {tab === 'pending' && <>
                        <button onClick={() => approve(u.uid)} className="px-3 py-1 bg-primary text-white rounded-lg text-xs font-semibold">승인</button>
                        <button onClick={() => reject(u.uid)} className="px-3 py-1 bg-red-500 text-white rounded-lg text-xs font-semibold">거절</button>
                      </>}
                      {tab === 'approved' && <>
                        {profile?.role === 'admin' && u.role !== 'admin' && (
                          <select value={u.role} onChange={e => setRole(u.uid, e.target.value)}
                            className="px-2 py-1 border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-input text-gray-900 dark:text-gray-100 rounded-lg text-xs font-semibold">
                            <option value="user">일반</option>
                            <option value="moderator">모더레이터</option>
                            <option value="auditor">감사자</option>
                            <option value="manager">매니저</option>
                            <option value="admin">Admin</option>
                          </select>
                        )}
                        {profile?.role === 'admin' && u.role === 'admin' && u.uid === profile.uid && (
                          <button onClick={() => setRole(u.uid, 'user')} className="px-3 py-1 bg-gray-400 text-white rounded-lg text-xs font-semibold">Admin 해제</button>
                        )}
                        {u.role === 'user' && u.uid !== profile?.uid && <>
                          <select onChange={e => { if (e.target.value) suspend(u.uid, Number(e.target.value)); e.target.value = ''; }}
                            className="px-2 py-1 border border-orange-300 dark:border-orange-700 bg-white dark:bg-dark-input text-orange-600 dark:text-orange-400 rounded-lg text-xs" defaultValue="">
                            <option value="" disabled>정지</option>
                            {suspendOptions.map(o => <option key={o.hours} value={o.hours}>{o.label}</option>)}
                          </select>
                          <button onClick={() => deleteUser(u.uid)} className="px-3 py-1 bg-red-500 text-white rounded-lg text-xs font-semibold">삭제</button>
                        </>}
                      </>}
                      {tab === 'suspended' && (
                        <button onClick={() => unsuspend(u.uid)} className="px-3 py-1 bg-primary text-white rounded-lg text-xs font-semibold">정지 해제</button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </main>
  );
}
