import { Friend, Resolution } from '../types';

export function todayString(): string {
  return new Date().toISOString().slice(0, 10);
}

function placeholderPhoto(seed: string): string {
  return `https://picsum.photos/seed/${encodeURIComponent(seed)}/500/500`;
}

// Local, in-memory seed data — this Expo build has no backend wired up
// yet, so the whole app runs off this state (see src/state/AppState.tsx).
// The native SwiftUI build already has the real Firebase model; this
// mirrors its shape closely enough that swapping in Firestore later is
// mostly a matter of replacing the functions in AppState.tsx.
export function seedResolutions(): Resolution[] {
  const today = todayString();
  return [
    {
      id: 'run',
      name: 'Run 5km',
      category: 'fitness',
      icon: 'walk-outline',
      color: '#E7414C',
      frequencyLabel: 'Every day',
      currentStreak: 12,
      longestStreak: 15,
      totalProofs: 47,
      proofs: [],
    },
    {
      id: 'read',
      name: 'Read every day',
      category: 'reading',
      icon: 'book-outline',
      color: '#2EC4B6',
      frequencyLabel: 'Every day',
      currentStreak: 18,
      longestStreak: 24,
      totalProofs: 61,
      proofs: [{ date: today, photoUri: placeholderPhoto('read-today'), caption: 'Finished chapter 4' }],
    },
    {
      id: 'code',
      name: 'Code daily',
      category: 'coding',
      icon: 'code-slash-outline',
      color: '#1982C4',
      frequencyLabel: '3x / week',
      currentStreak: 0,
      longestStreak: 9,
      totalProofs: 22,
      proofs: [],
    },
  ];
}

export function seedFriends(): Friend[] {
  const today = todayString();
  return [
    {
      id: 'marco',
      name: 'Marco',
      color: '#1982C4',
      streak: 9,
      completedToday: true,
      isFollowing: true,
      partnerState: 'accepted',
      resolutions: [
        {
          id: 'pushups',
          name: 'Push-ups',
          category: 'fitness',
          icon: 'barbell-outline',
          color: '#1982C4',
          frequencyLabel: 'Every day',
          currentStreak: 9,
          longestStreak: 12,
          totalProofs: 40,
          proofs: [{ date: today, photoUri: placeholderPhoto('marco-pushups'), caption: '50 today 💪' }],
        },
      ],
    },
    {
      id: 'lea',
      name: 'Léa',
      color: '#6A4C93',
      streak: 31,
      completedToday: true,
      isFollowing: true,
      partnerState: 'none',
    },
    {
      id: 'sam',
      name: 'Sam',
      color: '#E7414C',
      streak: 4,
      completedToday: true,
      isFollowing: false,
      partnerState: 'incoming',
      resolutions: [
        {
          id: 'meditate',
          name: 'Meditate 10 min',
          category: 'mindfulness',
          icon: 'leaf-outline',
          color: '#E7414C',
          frequencyLabel: 'Every day',
          currentStreak: 4,
          longestStreak: 11,
          totalProofs: 19,
          proofs: [{ date: today, photoUri: placeholderPhoto('sam-meditate'), caption: '' }],
        },
      ],
    },
  ];
}

export const categoryIcons: Record<string, string> = {
  fitness: 'walk-outline',
  reading: 'book-outline',
  coding: 'code-slash-outline',
  mindfulness: 'leaf-outline',
  other: 'star-outline',
};
