import React, { useState } from 'react';
import { ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { PhotoTile } from '../components/PhotoTile';
import { PrimaryButton } from '../components/PrimaryButton';
import { StreakBadge } from '../components/StreakBadge';
import { useAppState } from '../state/AppState';
import { todayString } from '../data/mockData';

export function ProfileScreen() {
  const { userName, updateUserName, resolutions, friends, signOut } = useAppState();
  const [editingName, setEditingName] = useState(userName);
  const today = todayString();

  const bestStreak = Math.max(0, ...resolutions.map((r) => r.currentStreak));
  const myCompletedToday = resolutions.some((r) => r.proofs.some((p) => p.date === today));
  const featuredPartner = friends.find((f) => f.partnerState === 'accepted' && f.completedToday);
  const myPhoto = resolutions.flatMap((r) => r.proofs).find((p) => p.date === today)?.photoUri;
  const partnerPhoto = featuredPartner?.resolutions?.flatMap((r) => r.proofs).find((p) => p.date === today)?.photoUri;

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.title}>Profile</Text>

        <View style={styles.card}>
          <View style={[styles.avatar]}>
            <Text style={styles.avatarText}>{userName[0] ?? '?'}</Text>
          </View>
          <TextInput
            style={styles.nameInput}
            value={editingName}
            onChangeText={setEditingName}
            onEndEditing={() => updateUserName(editingName)}
            placeholder="Your name"
          />
        </View>

        <Text style={styles.sectionLabel}>Resolutions</Text>
        {resolutions.map((r) => (
          <View key={r.id} style={styles.resRow}>
            <Text style={styles.resName}>{r.name}</Text>
            <StreakBadge streak={r.currentStreak} />
          </View>
        ))}

        <Text style={styles.sectionLabel}>Home Screen widget (aperçu)</Text>
        <Text style={styles.widgetNote}>
          Les vrais widgets iOS ne tournent pas dans Expo Go — voici à quoi ressemblerait celui de la build native (voir
          Proof/ProofWidget).
        </Text>
        <View style={styles.widgetPreview}>
          <PhotoTile photoUri={myCompletedToday ? myPhoto : undefined} streak={bestStreak} completed={myCompletedToday} label="You" />
          {featuredPartner ? (
            <PhotoTile photoUri={partnerPhoto} streak={featuredPartner.streak} completed={true} label={featuredPartner.name} />
          ) : (
            <View style={styles.noPartnerTile}>
              <Text style={styles.noPartnerText}>No partner{'\n'}proof yet</Text>
            </View>
          )}
        </View>

        <View style={{ height: 24 }} />
        <PrimaryButton title="Sign out" variant="danger" onPress={signOut} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F6F3EF' },
  content: { padding: 16 },
  title: { fontSize: 30, fontWeight: '800', color: '#1C1C1E', marginBottom: 12 },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: '#E5E2DC',
    marginBottom: 20,
  },
  avatar: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: '#FF6B35',
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: { color: '#fff', fontWeight: '800', fontSize: 18 },
  nameInput: { fontSize: 16.5, fontWeight: '700', color: '#1C1C1E', flex: 1 },
  sectionLabel: {
    fontSize: 12,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    color: '#6E6E73',
    marginBottom: 8,
    marginTop: 6,
  },
  resRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#fff',
    borderRadius: 14,
    padding: 12,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#E5E2DC',
  },
  resName: { fontSize: 14.5, fontWeight: '600', color: '#1C1C1E' },
  widgetNote: { fontSize: 12, color: '#6E6E73', marginBottom: 10, lineHeight: 17 },
  widgetPreview: {
    flexDirection: 'row',
    gap: 6,
    height: 150,
    marginBottom: 12,
  },
  noPartnerTile: {
    flex: 1,
    borderRadius: 18,
    backgroundColor: '#EDEBE6',
    alignItems: 'center',
    justifyContent: 'center',
  },
  noPartnerText: { fontSize: 10.5, color: '#6E6E73', textAlign: 'center' },
});
