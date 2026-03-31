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
          if (data.role === 'admin' || data.role === 'manager') {
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

  return { user, profile, loading };
}
