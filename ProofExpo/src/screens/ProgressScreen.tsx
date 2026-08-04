import { useNavigation, useRoute } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import React from 'react';
import { Image, ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { RootStackParamList } from '../navigation/types';
import { useAppState } from '../state/AppState';
import { Resolution } from '../types';

/// Read-only by construction — no capture affordance here — so this
/// same screen works both for your own progress (friendId omitted)
/// and, once a friend has accepted a partner request, for browsing
/// their actual proof photos (friendId set). Mirrors
/// Proof/Views/Progress/ProgressScreenView.swift in the native app.
export function ProgressScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const route = useRoute<any>();
  const { resolutionId, friendId } = route.params as { resolutionId: string; friendId?: string };
  const { resolutions, friends } = useAppState();

  let resolution: Resolution | undefined;
  if (friendId) {
    resolution = friends.find((f) => f.id === friendId)?.resolutions?.find((r) => r.id === resolutionId);
  } else {
    resolution = resolutions.find((r) => r.id === resolutionId);
  }

  React.useEffect(() => {
    navigation.setOptions({ title: resolution?.name ?? '' });
  }, [resolution?.name]);

  if (!resolution) return null;

  const daysSinceStart = Math.max(resolution.totalProofs, 30);
  const completion = Math.min(100, Math.round((resolution.totalProofs / daysSinceStart) * 100));
  const recentProofs = [...resolution.proofs].sort((a, b) => (a.date < b.date ? 1 : -1));

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.statsRow}>
          <StatTile label="CURRENT" value={resolution.currentStreak} />
          <StatTile label="LONGEST" value={resolution.longestStreak} />
          <StatTile label="TOTAL" value={resolution.totalProofs} />
          <StatTile label="COMPLETION" value={`${completion}%`} />
        </View>

        <Text style={styles.sectionLabel}>Recent proofs</Text>
        {recentProofs.length === 0 ? (
          <Text style={styles.emptyText}>No proof posted yet.</Text>
        ) : (
          recentProofs.map((proof) => (
            <View key={proof.date} style={styles.proofRow}>
              <Image source={{ uri: proof.photoUri }} style={styles.thumb} />
              <View style={{ flex: 1 }}>
                <Text style={styles.proofDate}>{proof.date}</Text>
                {!!proof.caption && <Text style={styles.proofCaption}>{proof.caption}</Text>}
              </View>
            </View>
          ))
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

function StatTile({ label, value }: { label: string; value: number | string }) {
  return (
    <View style={styles.statTile}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F6F3EF',
  },
  content: {
    padding: 16,
  },
  statsRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: 20,
  },
  statTile: {
    flex: 1,
    backgroundColor: '#fff',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E5E2DC',
    paddingVertical: 12,
    alignItems: 'center',
  },
  statValue: {
    fontSize: 18,
    fontWeight: '800',
    color: '#1C1C1E',
  },
  statLabel: {
    fontSize: 10,
    color: '#6E6E73',
    marginTop: 2,
  },
  sectionLabel: {
    fontSize: 12,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    color: '#6E6E73',
    marginBottom: 8,
  },
  emptyText: {
    color: '#6E6E73',
    fontSize: 13.5,
  },
  proofRow: {
    flexDirection: 'row',
    gap: 12,
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E2DC',
    alignItems: 'center',
  },
  thumb: {
    width: 44,
    height: 44,
    borderRadius: 8,
    backgroundColor: '#eee',
  },
  proofDate: {
    fontSize: 12,
    color: '#6E6E73',
  },
  proofCaption: {
    fontSize: 14,
    color: '#1C1C1E',
    marginTop: 2,
  },
});
