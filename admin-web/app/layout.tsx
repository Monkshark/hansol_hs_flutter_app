import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: '한솔고 Admin',
  description: '한솔고등학교 관리자 대시보드',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body className="bg-gray-50 text-gray-900">{children}</body>
    </html>
  );
}
