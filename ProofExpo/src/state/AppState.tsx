import React, { createContext, useCallback, useContext, useMemo, useState } from 'react';
import { Friend, PartnerState, Resolution } from '../types';
import { seedFriends, seedResolutions, todayString } from '../data/mockData';

interface NewResolutionInput {
  name: string;
  category: Resolution['category'];
  icon: string;
  color: string;
  frequencyLabel: string;
}

interface AppStateValue {
  signedIn: boolean;
  userName: string;
  resolutions: Resolution[];
  friends: Friend[];
  signIn: (provider: 'apple' | 'google') => void;
  signOut: () => void;
  updateUserName: (name: string) => void;
  addResolution: (input: NewResolutionInput) => void;
  postProof: (resolutionId: string, photoUri: string, caption: string) => void;
  requestPartnership: (friendId: string) => void;
  respondPartnership: (friendId: string, accept: boolean) => void;
  toggleFollow: (friendId: string) => void;
}

const AppStateContext = createContext<AppStateValue | null>(null);

/// Everything here lives in memory for this Expo Go build — there is no
/// Firebase wired up yet. The native SwiftUI app (../Proof) already has
/// the real Firestore/Storage model this mirrors; the point of this
/// build is to be instantly testable in Expo Go with zero setup.
export function AppStateProvider({ children }: { children: React.ReactNode }) {
  const [signedIn, setSignedIn] = useState(false);
  const [userName, setUserName] = useState('Daniela');
  const [resolutions, setResolutions] = useState<Resolution[]>(seedResolutions);
  const [friends, setFriends] = useState<Friend[]>(seedFriends);

  const signIn = useCallback((_provider: 'apple' | 'google') => {
    setSignedIn(true);
  }, []);

  const signOut = useCallback(() => setSignedIn(false), []);

  const updateUserName = useCallback((name: string) => {
    if (name.trim().length > 0) setUserName(name.trim());
  }, []);

  const addResolution = useCallback((input: NewResolutionInput) => {
    setResolutions((prev) => [
      ...prev,
      {
        id: `r${Date.now()}`,
        name: input.name,
        category: input.category,
        icon: input.icon,
        color: input.color,
        frequencyLabel: input.frequencyLabel,
        currentStreak: 0,
        longestStreak: 0,
        totalProofs: 0,
        proofs: [],
      },
    ]);
  }, []);

  const postProof = useCallback((resolutionId: string, photoUri: string, caption: string) => {
    const today = todayString();
    setResolutions((prev) =>
      prev.map((r) => {
        if (r.id !== resolutionId) return r;
        const alreadyToday = r.proofs.some((p) => p.date === today);
        const newStreak = alreadyToday ? r.currentStreak : r.currentStreak + 1;
        return {
          ...r,
          currentStreak: newStreak,
          longestStreak: Math.max(r.longestStreak, newStreak),
          totalProofs: alreadyToday ? r.totalProofs : r.totalProofs + 1,
          proofs: alreadyToday
            ? r.proofs.map((p) => (p.date === today ? { ...p, photoUri, caption } : p))
            : [...r.proofs, { date: today, photoUri, caption }],
        };
      })
    );
  }, []);

  const requestPartnership = useCallback((friendId: string) => {
    setFriends((prev) =>
      prev.map((f) => (f.id === friendId ? { ...f, partnerState: 'requested' as PartnerState } : f))
    );
  }, []);

  const respondPartnership = useCallback((friendId: string, accept: boolean) => {
    setFriends((prev) =>
      prev.map((f) =>
        f.id === friendId ? { ...f, partnerState: (accept ? 'accepted' : 'none') as PartnerState } : f
      )
    );
  }, []);

  const toggleFollow = useCallback((friendId: string) => {
    setFriends((prev) => prev.map((f) => (f.id === friendId ? { ...f, isFollowing: !f.isFollowing } : f)));
  }, []);

  const value = useMemo<AppStateValue>(
    () => ({
      signedIn,
      userName,
      resolutions,
      friends,
      signIn,
      signOut,
      updateUserName,
      addResolution,
      postProof,
      requestPartnership,
      respondPartnership,
      toggleFollow,
    }),
    [signedIn, userName, resolutions, friends, signIn, signOut, updateUserName, addResolution, postProof, requestPartnership, respondPartnership, toggleFollow]
  );

  return <AppStateContext.Provider value={value}>{children}</AppStateContext.Provider>;
}

export function useAppState(): AppStateValue {
  const ctx = useContext(AppStateContext);
  if (!ctx) throw new Error('useAppState must be used within AppStateProvider');
  return ctx;
}
