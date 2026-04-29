'use client';
import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/lib/auth';
import { useTheme } from '@/lib/theme';
import { canAccess } from '@/lib/utils';

const nav = [
  { href: '/dashboard', label: '대시보드', icon: '📊' },
  { href: '/posts', label: '게시글', icon: '📝' },
  { href: '/comments', label: '댓글', icon: '💬' },
  { href: '/reports', label: '신고', icon: '🚨' },
  { href: '/users', label: '사용자', icon: '👥' },
  { href: '/feedbacks', label: '건의사항', icon: '📮' },
  { href: '/appeals', label: '이의제기', icon: '⚖️' },
  { href: '/data-requests', label: '데이터 요청', icon: '📂' },
  { href: '/community-rules', label: '커뮤니티 규정', icon: '📜' },
  { href: '/admin-logs', label: '관리자 로그', icon: '📋' },
  { href: '/crashes', label: '앱 크래시', icon: '🐛' },
  { href: '/function-logs', label: 'Functions 로그', icon: '⚡' },
  { href: '/settings', label: '설정', icon: '⚙️' },
];

export default function Sidebar() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const { dark, toggle } = useTheme();
  const { profile, logout } = useAuth();
  const filteredNav = nav.filter(item => canAccess(profile?.role ?? 'user', item.href.slice(1)));

  const sidebarContent = (
    <>
      <div className="p-5 border-b border-gray-700 flex items-center justify-between">
        <h2 className="text-white font-bold text-lg">HS Admin</h2>
        <button onClick={() => setOpen(false)} className="md:hidden text-gray-400 hover:text-white text-xl">✕</button>
      </div>
      <nav className="flex-1 py-2">
        {filteredNav.map((item) => (
          <Link key={item.href} href={item.href} onClick={() => setOpen(false)}
            className={`flex items-center gap-3 px-5 py-3 text-sm transition-colors ${
              pathname.startsWith(item.href) ? 'text-white bg-white/5 border-l-2 border-primary' : 'text-gray-400 hover:text-white hover:bg-white/5'
            }`}>
            <span>{item.icon}</span>
            <span>{item.label}</span>
          </Link>
        ))}
      </nav>
      <button onClick={toggle}
        className="flex items-center gap-3 px-5 py-3 text-sm text-gray-400 hover:text-white border-t border-gray-700">
        <span>{dark ? '☀️' : '🌙'}</span><span>{dark ? '라이트 모드' : '다크 모드'}</span>
      </button>
      <button onClick={logout}
        className="flex items-center gap-3 px-5 py-3 text-sm text-gray-400 hover:text-white border-t border-gray-700">
        <span>🚪</span><span>로그아웃</span>
      </button>
    </>
  );

  return (
    <>
      {/* Mobile hamburger button */}
      <button onClick={() => setOpen(true)}
        className="md:hidden fixed top-3 left-3 z-50 bg-dark-card text-white p-2 rounded-lg shadow-lg">
        <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>

      {/* Mobile overlay */}
      {open && (
        <div className="md:hidden fixed inset-0 bg-black/50 z-40" onClick={() => setOpen(false)} />
      )}

      {/* Mobile sidebar */}
      <aside className={`md:hidden fixed top-0 left-0 h-full w-56 bg-dark-card z-50 flex flex-col transform transition-transform duration-200 ${
        open ? 'translate-x-0' : '-translate-x-full'
      }`}>
        {sidebarContent}
      </aside>

      {/* Desktop sidebar */}
      <aside className="hidden md:flex shrink-0 w-56 bg-dark-card min-h-screen flex-col">
        {sidebarContent}
      </aside>
    </>
  );
}
