'use client';
import { useState } from 'react';
import { signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '@/lib/firebase';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const router = useRouter();

  async function checkRole(uid: string): Promise<boolean> {
    const snap = await getDoc(doc(db, 'users', uid));
    if (!snap.exists()) return false;
    const role = snap.data().role;
    return role === 'admin' || role === 'manager';
  }

  async function handleEmail() {
    try {
      const result = await signInWithEmailAndPassword(auth, email, password);
      if (await checkRole(result.user.uid)) {
        router.push('/dashboard');
      } else {
        setError('관리자 또는 매니저 권한이 필요합니다');
        await auth.signOut();
      }
    } catch { setError('로그인 실패: 이메일 또는 비밀번호를 확인하세요'); }
  }

  async function handleGoogle() {
    try {
      const result = await signInWithPopup(auth, new GoogleAuthProvider());
      if (await checkRole(result.user.uid)) {
        router.push('/dashboard');
      } else {
        setError('관리자 또는 매니저 권한이 필요합니다');
        await auth.signOut();
      }
    } catch { setError('Google 로그인 실패'); }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary to-primary-dark">
      <div className="bg-white dark:bg-dark-card rounded-2xl p-10 w-96 shadow-2xl">
        <h1 className="text-2xl font-bold mb-1">한솔고 Admin</h1>
        <p className="text-sm text-gray-400 mb-6">관리자 계정으로 로그인하세요</p>

        <input type="email" placeholder="이메일" value={email} onChange={e => setEmail(e.target.value)}
          className="w-full p-3 bg-gray-100 dark:bg-dark-input rounded-xl mb-3 outline-none focus:bg-gray-200 dark:focus:bg-dark-card dark:text-gray-100 text-sm" />
        <input type="password" placeholder="비밀번호" value={password} onChange={e => setPassword(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleEmail()}
          className="w-full p-3 bg-gray-100 dark:bg-dark-input rounded-xl mb-3 outline-none focus:bg-gray-200 dark:focus:bg-dark-card dark:text-gray-100 text-sm" />
        <button onClick={handleEmail}
          className="w-full p-3 bg-primary text-white rounded-xl font-semibold hover:bg-primary-dark transition">
          이메일 로그인
        </button>

        <div className="text-center text-gray-400 text-sm my-3">또는</div>

        <button onClick={handleGoogle}
          className="w-full p-3 bg-white dark:bg-dark-card border border-gray-200 dark:border-gray-700 rounded-xl font-semibold hover:bg-gray-50 dark:hover:bg-dark-input transition text-sm">
          Google 로그인 (매니저)
        </button>

        {error && <p className="text-red-500 text-xs mt-3">{error}</p>}
      </div>
    </div>
  );
}
