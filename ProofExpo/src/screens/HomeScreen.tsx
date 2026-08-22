import { Ionicons } from '@expo/vector-icons';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useNavigation } from '@react-navigation/native';
import React from 'react';
import { FlatList, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MissionRow } from '../components/MissionRow';
import { PrimaryButton } from '../components/PrimaryButton';
import { RootStackParamList } from '../navigation/types';
import { useAppState } from '../state/AppState';
import { todayString } from '../data/mockData';

export function HomeScreen() {
  const { resolutions } = useAppState();
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const today = todayString();

  const isCompletedToday = (resolutionId: string) => {
    const r = resolutions.find((x) => x.id === resolutionId);
    return !!r?.proofs.some((p) => p.date === today);
  };

  const firstIncomplete = resolutions.find((r) => !isCompletedToday(r.id));

  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <View style={styles.header}>
        <Text style={styles.title}>Today's Mission</Text>
        <Ionicons
          name="add-circle"
          size={30}
          color="#FF6B35"
          onPress={() => navigation.navigate('CreateResolution')}
        />
      </View>

      {resolutions.length === 0 ? (
        <View style={styles.empty}>
          <Ionicons name="flag-outline" size={44} color="#B8B6B2" />
          <Text style={styles.emptyTitle}>No resolutions yet</Text>
          <Text style={styles.emptyBody}>Add your first goal to start posting daily proof.</Text>
          <PrimaryButton title="Create a resolution" icon="add" onPress={() => navigation.navigate('CreateResolution')} />
        </View>
      ) : (
        <>
          <FlatList
            data={resolutions}
            keyExtractor={(r) => r.id}
            contentContainerStyle={styles.list}
            renderItem={({ item }) => {
              const completed = isCompletedToday(item.id);
              return (
                <MissionRow
                  resolution={item}
                  completedToday={completed}
                  onPress={() =>
                    completed
                      ? navigation.navigate('Progress', { resolutionId: item.id })
                      : navigation.navigate('CaptureProof', { resolutionId: item.id })
                  }
                />
              );
            }}
          />
          <View style={styles.ctaBar}>
            <PrimaryButton
              title="Add Today's Proof"
              icon="camera"
              disabled={!firstIncomplete}
              onPress={() => firstIncomplete && navigation.navigate('CaptureProof', { resolutionId: firstIncomplete.id })}
            />
          </View>
        </>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F6F3EF',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 8,
    paddingBottom: 4,
  },
  title: {
    fontSize: 30,
    fontWeight: '800',
    color: '#1C1C1E',
  },
  list: {
    paddingHorizontal: 16,
    paddingTop: 8,
  },
  ctaBar: {
    padding: 16,
  },
  empty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    gap: 6,
  },
  emptyTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: '#1C1C1E',
    marginTop: 8,
  },
  emptyBody: {
    fontSize: 13.5,
    color: '#6E6E73',
    textAlign: 'center',
    marginBottom: 14,
  },
});
