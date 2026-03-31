'use client';
import { useEffect, useState } from 'react';
import { collection, getDocs, deleteDoc, updateDoc, doc, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useAuth } from '@/lib/auth';
import { useRouter } from 'next/navigation';
import Sidebar from '@/components/Sidebar';
import Badge from '@/components/Badge';
import { isSuspended, suspendRemaining, roleBadge } from '@/lib/utils';
import { UserProfile } from '@/lib/types';

type Tab = 'approved' | 'pending' | 'suspended';

export default function UsersPage() {
  const { profile, loading } = useAuth();
  const router = useRouter();
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [tab, setTab] = useState<Tab>('approved');
  const [search, setSearch] = useState('');

  useEffect(() => { if (!loading && !profile) router.push('/'); }, [loading, profile, router]);
  useEffect(() => { if (profile) loadUsers(); }, [profile]);

  async function loadUsers() {
    const snap = await getDocs(collection(db, 'users'));
    setUsers(snap.docs.map(d => ({ ...d.data(), uid: d.id } as UserProfile)));
  }

  const filtered = users.filter(u => {
    const suspended = isSuspended(u.suspendedUntil);
    if (tab === 'pending') return !u.approved;
    if (tab === 'suspended') return u.approved && suspended;
    if (tab === 'approved') return u.approved && !suspended;
    return false;
  }).filter(u =>
    !search || u.name?.toLowerCase().includes(search.toLowerCase()) || u.studentId?.includes(search)
  );

  if (tab === 'approved') {
    const roleOrder: Record<string, number> = { admin: 0, manager: 1, user: 2 };
    filtered.sort((a, b) => (roleOrder[a.role] || 2) - (roleOrder[b.role] || 2));
  }

  async function approve(uid: string) {
    await updateDoc(doc(db, 'users', uid), { approved: true });
    setUsers(prev => prev.map(u => u.uid === uid ? { ...u, approved: true } : u));
  }

  async function reject(uid: string) {
    if (!confirm('가입을 거절하시겠습니까?')) return;
    await deleteDoc(doc(db, 'users', uid));
    setUsers(prev => prev.filter(u => u.uid !== uid));
  }

  async function setRole(uid: string, role: string) {
    const labels: Record<string, string> = { admin: 'Admin', manager: '매니저', user: '일반' };
    if (!confirm(`${labels[role]}(으)로 변경하시겠습니까?`)) return;
    await updateDoc(doc(db, 'users', uid), { role });
    setUsers(prev => prev.map(u => u.uid === uid ? { ...u, role: role as UserProfile['role'] } : u));
  }

  async function suspend(uid: string, hours: number) {
    const until = new Date(Date.now() + hours * 3600000);
    await updateDoc(doc(db, 'users', uid), { suspendedUntil: Timestamp.fromDate(until) });
    loadUsers();
  }

  async function unsuspend(uid: string) {
    await updateDoc(doc(db, 'users', uid), { suspendedUntil: null });
    loadUsers();
  }

  async function deleteUser(uid: string) {
    if (!confirm('계정을 삭제하시겠습니까?')) return;
    if (!confirm('정말 삭제합니까? 되돌릴 수 없습니다.')) return;
    await deleteDoc(doc(db, 'users', uid));
    setUsers(prev => prev.filter(u => u.uid !== uid));
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
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-6">
        <h1 className="text-2xl font-bold mb-5">사용자 관리</h1>

        <div className="flex gap-2 mb-4">
          {tabs.map(t => (
            <button key={t.key} onClick={() => setTab(t.key)}
              className={`px-4 py-2 rounded-lg text-sm font-semibold transition ${
                tab === t.key ? `${t.color} text-white` : 'bg-gray-100 text-gray-500'
              }`}>{t.label}</button>
          ))}
        </div>

        <input type="text" placeholder="이름 또는 학번 검색..." value={search} onChange={e => setSearch(e.target.value)}
          className="w-full max-w-md p-3 bg-white rounded-xl mb-4 outline-none text-sm shadow-sm" />

        <div className="bg-white rounded-xl shadow-sm overflow-hidden">
          {filtered.length === 0 ? (
            <p className="p-6 text-gray-400 text-sm">사용자가 없습니다</p>
          ) : (
            <table className="w-full text-sm">
              <thead><tr className="bg-gray-50 text-gray-400 text-xs">
                <th className="text-left p-3">이름</th>
                <th className="text-left p-3">학번</th>
                <th className="text-left p-3">학년/반</th>
                {tab === 'suspended' && <th className="text-left p-3">남은 기간</th>}
                <th className="text-left p-3">액션</th>
              </tr></thead>
              <tbody>
                {filtered.map(u => {
                  const badge = roleBadge(u.role);
                  return (
                    <tr key={u.uid} className="border-t border-gray-50 hover:bg-gray-50">
                      <td className="p-3">
                        <span className="cursor-pointer hover:text-primary" onClick={() => router.push(`/users/${u.uid}`)}>
                          {u.name || '-'}
                        </span>
                        {badge && <Badge label={badge.label} className={`ml-2 ${badge.color}`} />}
                      </td>
                      <td className="p-3 text-gray-500">{u.studentId || '-'}</td>
                      <td className="p-3 text-gray-500">{u.grade || '-'}학년 {u.classNum || '-'}반</td>
                      {tab === 'suspended' && (
                        <td className="p-3 text-red-500 font-semibold text-xs">{suspendRemaining(u.suspendedUntil)}</td>
                      )}
                      <td className="p-3 flex gap-1 flex-wrap">
                        {tab === 'pending' && <>
                          <button onClick={() => approve(u.uid)} className="px-3 py-1 bg-primary text-white rounded-lg text-xs font-semibold">승인</button>
                          <button onClick={() => reject(u.uid)} className="px-3 py-1 bg-red-500 text-white rounded-lg text-xs font-semibold">거절</button>
                        </>}
                        {tab === 'approved' && <>
                          {profile?.role === 'admin' && u.role !== 'admin' && <>
                            <button onClick={() => setRole(u.uid, u.role === 'manager' ? 'user' : 'manager')}
                              className={`px-3 py-1 rounded-lg text-xs font-semibold ${u.role === 'manager' ? 'bg-gray-400 text-white' : 'bg-blue-500 text-white'}`}>
                              {u.role === 'manager' ? '매니저 해제' : '매니저'}
                            </button>
                            <button onClick={() => setRole(u.uid, 'admin')} className="px-3 py-1 bg-red-500 text-white rounded-lg text-xs font-semibold">Admin</button>
                          </>}
                          {profile?.role === 'admin' && u.role === 'admin' && u.uid === profile.uid && (
                            <button onClick={() => setRole(u.uid, 'user')} className="px-3 py-1 bg-gray-400 text-white rounded-lg text-xs font-semibold">Admin 해제</button>
                          )}
                          {u.role === 'user' && u.uid !== profile?.uid && <>
                            <select onChange={e => { if (e.target.value) suspend(u.uid, Number(e.target.value)); e.target.value = ''; }}
                              className="px-2 py-1 border border-orange-300 rounded-lg text-xs text-orange-600" defaultValue="">
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
    </div>
  );
}
