import { Timestamp } from 'firebase/firestore';

export interface UserProfile {
  uid: string;
  name: string;
  studentId: string;
  grade: number;
  classNum: number;
  email: string;
  approved: boolean;
  role: 'user' | 'manager' | 'admin';
  userType: 'student' | 'graduate' | 'teacher' | 'parent';
  fcmToken?: string;
  suspendedUntil?: Timestamp;
  loginProvider?: string;
  lastProfileUpdate?: string;
  graduationYear?: number;
  teacherSubject?: string;
}

export interface Post {
  id: string;
  title: string;
  content: string;
  category: string;
  authorUid: string;
  authorName: string;
  authorRealName?: string;
  isAnonymous: boolean;
  isPinned: boolean;
  pinnedAt?: Timestamp;
  createdAt: Timestamp;
  expireAt?: Timestamp;
  commentCount: number;
  likes?: number | Record<string, boolean>;
  dislikes?: number | Record<string, boolean>;
  imageUrls?: string[];
  pollOptions?: string[];
  pollVoters?: Record<string, number>;
  eventDate?: string;
  eventContent?: string;
}

export interface Comment {
  id: string;
  postId: string;
  content: string;
  authorUid: string;
  authorName: string;
  authorRealName?: string;
  isAnonymous: boolean;
  createdAt: Timestamp;
  replyTo?: string;
  replyToName?: string;
  parentId?: string;
}

export interface Report {
  id: string;
  postId: string;
  reporterUid: string;
  reason: string;
  createdAt: Timestamp;
}
