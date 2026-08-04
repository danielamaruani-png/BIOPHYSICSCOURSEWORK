export type Category = 'fitness' | 'reading' | 'coding' | 'mindfulness' | 'other';

export type PartnerState = 'none' | 'requested' | 'incoming' | 'accepted';

export interface ProofEntry {
  date: string; // yyyy-MM-dd — one entry per resolution per day, same rule as the Firestore doc-id trick in the native app
  photoUri: string;
  caption?: string;
}

export interface Resolution {
  id: string;
  name: string;
  category: Category;
  icon: string; // Ionicons glyph name
  color: string;
  frequencyLabel: string;
  currentStreak: number;
  longestStreak: number;
  totalProofs: number;
  proofs: ProofEntry[];
}

export interface Friend {
  id: string;
  name: string;
  color: string;
  streak: number;
  completedToday: boolean;
  isFollowing: boolean;
  partnerState: PartnerState;
  resolutions?: Resolution[];
}
