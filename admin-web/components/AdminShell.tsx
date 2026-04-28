'use client';
import { usePathname } from 'next/navigation';
import Sidebar from './Sidebar';

export default function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const isAuthPage = pathname === '/' || pathname.startsWith('/login');

  if (isAuthPage) return <>{children}</>;

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex-1 min-w-0 flex flex-col">{children}</div>
    </div>
  );
}
