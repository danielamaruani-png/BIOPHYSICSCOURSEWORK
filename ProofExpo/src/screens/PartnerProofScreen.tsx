import { Ionicons } from '@expo/vector-icons';
import { useNavigation, useRoute } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import React from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { StreakBadge } from '../components/StreakBadge';
import { RootStackParamList } from '../navigation/types';
import { useAppState } from '../state/AppState';

/// Only ever reachable for an *accepted* accountability partner — lists
/// their resolutions and drills into the same read-only ProgressScreen
/// used for your own progress.
export function PartnerProofScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const route = useRoute<any>();
  const { friendId } = route.params as { friendId: string };
  const { friends } = useAppState();
  const friend = friends.find((f) => f.id === friendId);

  React.useEffect(() => {
    navigation.setOptions({ title: friend?.name ?? '' });
  }, [friend?.name]);

  if (!friend) return null;
  const resolutions = friend.resolutions ?? [];

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <FlatList
        data={resolutions}
        keyExtractor={(r) => r.id}
        contentContainerStyle={styles.list}
        ListEmptyComponent={<Text style={styles.empty}>{friend.name} hasn't added a resolution yet.</Text>}
        renderItem={({ item }) => (
          <Pressable
            style={styles.row}
            onPress={() => navigation.navigate('Progress', { resolutionId: item.id, friendId: friend.id })}
          >
            <View style={[styles.iconWrap, { backgroundColor: `${item.color}29` }]}>
              <Ionicons name={item.icon as any} size={18} color={item.color} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.name}>{item.name}</Text>
              <Text style={styles.freq}>{item.frequencyLabel}</Text>
            </View>
            <StreakBadge streak={item.currentStreak} />
          </Pressable>
        )}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F6F3EF' },
  list: { padding: 16 },
  empty: { color: '#6E6E73', fontSize: 13.5, textAlign: 'center', marginTop: 40 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 13,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#E5E2DC',
    gap: 12,
  },
  iconWrap: {
    width: 38,
    height: 38,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  name: { fontSize: 15.5, fontWeight: '700', color: '#1C1C1E' },
  freq: { fontSize: 12.5, color: '#6E6E73', marginTop: 1 },
});
