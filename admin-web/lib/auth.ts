'use client';
import { useEffect, useState } from 'react';
import { onAuthStateChanged, User } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from './firebase';
import { UserProfile } from './types';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthStateChanged(auth, async (u) => {
      setUser(u);
      if (u) {
        const snap = await getDoc(doc(db, 'users', u.uid));
        if (snap.exists()) {
          const data = snap.data() as UserProfile;
          if (['admin', 'manager', 'moderator', 'auditor'].includes(data.role)) {
            setProfile({ ...data, uid: snap.id });
          } else {
            setProfile(null);
            await auth.signOut();
          }
        }
      } else {
        setProfile(null);
      }
      setLoading(false);
    });
  }, []);

  async function logout() {
    await auth.signOut();
    document.cookie = 'admin_session=; path=/; max-age=0';
  }

  return { user, profile, loading, logout };
}
