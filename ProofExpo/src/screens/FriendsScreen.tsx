import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import React from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StreakBadge } from '../components/StreakBadge';
import { RootStackParamList } from '../navigation/types';
import { useAppState } from '../state/AppState';
import { Friend } from '../types';

export function FriendsScreen() {
  const { friends, requestPartnership, respondPartnership, toggleFollow } = useAppState();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();

  const incoming = friends.filter((f) => f.partnerState === 'incoming');

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <Text style={styles.title}>Friends</Text>
      <FlatList
        data={friends}
        keyExtractor={(f) => f.id}
        contentContainerStyle={styles.list}
        ListHeaderComponent={
          incoming.length > 0 ? (
            <View style={styles.requestsSection}>
              <Text style={styles.sectionLabel}>Proof-sharing requests</Text>
              {incoming.map((f) => (
                <View key={f.id} style={styles.requestRow}>
                  <Avatar name={f.name} color={f.color} />
                  <Text style={styles.name}>{f.name}</Text>
                  <View style={{ flex: 1 }} />
                  <Pressable style={styles.declineBtn} onPress={() => respondPartnership(f.id, false)}>
                    <Text style={styles.declineText}>Decline</Text>
                  </Pressable>
                  <Pressable style={styles.acceptBtn} onPress={() => respondPartnership(f.id, true)}>
                    <Text style={styles.acceptText}>Accept</Text>
                  </Pressable>
                </View>
              ))}
              <Text style={[styles.sectionLabel, { marginTop: 18 }]}>Friends</Text>
            </View>
          ) : (
            <Text style={styles.sectionLabel}>Friends</Text>
          )
        }
        renderItem={({ item }) => (
          <FriendRow
            friend={item}
            onToggleFollow={() => toggleFollow(item.id)}
            onRequestPartner={() => requestPartnership(item.id)}
            onOpenPartner={() => navigation.navigate('PartnerProof', { friendId: item.id })}
          />
        )}
      />
    </SafeAreaView>
  );
}

function FriendRow({
  friend,
  onToggleFollow,
  onRequestPartner,
  onOpenPartner,
}: {
  friend: Friend;
  onToggleFollow: () => void;
  onRequestPartner: () => void;
  onOpenPartner: () => void;
}) {
  return (
    <View style={styles.row}>
      <Avatar name={friend.name} color={friend.color} />
      <View style={{ flex: 1, minWidth: 0 }}>
        <Text style={styles.name}>{friend.name}</Text>
        <Text style={styles.sub}>{friend.completedToday ? 'Completed today ✅' : 'Not completed yet'}</Text>
      </View>
      <StreakBadge streak={friend.streak} />
      {friend.partnerState !== 'accepted' && (
        <Pressable style={styles.followBtn} onPress={onToggleFollow}>
          <Text style={styles.followText}>{friend.isFollowing ? 'Following' : 'Follow'}</Text>
        </Pressable>
      )}
      <PartnerControl friend={friend} onRequest={onRequestPartner} onOpen={onOpenPartner} />
    </View>
  );
}

function PartnerControl({ friend, onRequest, onOpen }: { friend: Friend; onRequest: () => void; onOpen: () => void }) {
  switch (friend.partnerState) {
    case 'accepted':
      return (
        <Pressable style={styles.partnersBtn} onPress={onOpen}>
          <Ionicons name="checkmark-circle" size={12} color="#2FA84F" />
          <Text style={styles.partnersText}>Partners</Text>
        </Pressable>
      );
    case 'requested':
      return <Text style={styles.requestedText}>Requested</Text>;
    case 'incoming':
      return <Text style={styles.requestedText}>See ↑</Text>;
    default:
      return (
        <Pressable style={styles.followBtn} onPress={onRequest}>
          <Text style={styles.followText}>Share</Text>
        </Pressable>
      );
  }
}

function Avatar({ name, color }: { name: string; color: string }) {
  return (
    <View style={[styles.avatar, { backgroundColor: color }]}>
      <Text style={styles.avatarText}>{name[0]}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F6F3EF' },
  title: { fontSize: 30, fontWeight: '800', color: '#1C1C1E', paddingHorizontal: 20, paddingTop: 8 },
  list: { padding: 16, paddingTop: 8 },
  sectionLabel: {
    fontSize: 12,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    color: '#6E6E73',
    marginBottom: 8,
    marginTop: 6,
  },
  requestsSection: { marginBottom: 4 },
  requestRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 14,
    padding: 11,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#E5E2DC',
    gap: 10,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 14,
    padding: 11,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#E5E2DC',
    gap: 8,
  },
  avatar: {
    width: 38,
    height: 38,
    borderRadius: 19,
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: { color: '#fff', fontWeight: '800', fontSize: 14 },
  name: { fontSize: 14.5, fontWeight: '700', color: '#1C1C1E' },
  sub: { fontSize: 12, color: '#6E6E73', marginTop: 1 },
  followBtn: {
    borderWidth: 1,
    borderColor: '#E5E2DC',
    backgroundColor: '#FBFAF8',
    borderRadius: 20,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  followText: { fontSize: 12.5, fontWeight: '700', color: '#1C1C1E' },
  declineBtn: {
    borderWidth: 1,
    borderColor: '#E7414C',
    borderRadius: 20,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginRight: 6,
  },
  declineText: { color: '#E7414C', fontWeight: '700', fontSize: 12 },
  acceptBtn: {
    backgroundColor: '#FF6B35',
    borderRadius: 20,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  acceptText: { color: '#fff', fontWeight: '700', fontSize: 12 },
  partnersBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    borderWidth: 1,
    borderColor: '#2FA84F',
    borderRadius: 20,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  partnersText: { color: '#2FA84F', fontWeight: '700', fontSize: 11.5 },
  requestedText: { fontSize: 11, color: '#6E6E73', fontWeight: '700' },
});
