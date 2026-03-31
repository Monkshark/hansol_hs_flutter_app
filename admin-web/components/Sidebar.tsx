'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { signOut } from 'firebase/auth';
import { auth } from '@/lib/firebase';

const nav = [
  { href: '/dashboard', label: '대시보드', icon: '📊' },
  { href: '/posts', label: '게시글', icon: '📝' },
  { href: '/comments', label: '댓글', icon: '💬' },
  { href: '/reports', label: '신고', icon: '🚨' },
  { href: '/users', label: '사용자', icon: '👥' },
  { href: '/settings', label: '설정', icon: '⚙️' },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-56 bg-dark-card min-h-screen flex flex-col">
      <div className="p-5 border-b border-gray-700">
        <h2 className="text-white font-bold text-lg">HS Admin</h2>
      </div>
      <nav className="flex-1 py-2">
        {nav.map((item) => (
          <Link key={item.href} href={item.href}
            className={`flex items-center gap-3 px-5 py-3 text-sm transition-colors ${
              pathname.startsWith(item.href) ? 'text-white bg-white/5 border-l-2 border-primary' : 'text-gray-400 hover:text-white hover:bg-white/5'
            }`}>
            <span>{item.icon}</span>
            <span>{item.label}</span>
          </Link>
        ))}
      </nav>
      <button onClick={() => signOut(auth)}
        className="flex items-center gap-3 px-5 py-3 text-sm text-gray-400 hover:text-white border-t border-gray-700">
        <span>🚪</span><span>로그아웃</span>
      </button>
    </aside>
  );
}
