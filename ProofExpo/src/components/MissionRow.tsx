import { Ionicons } from '@expo/vector-icons';
import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { Resolution } from '../types';
import { StreakBadge } from './StreakBadge';

interface Props {
  resolution: Resolution;
  completedToday: boolean;
  onPress: () => void;
}

export function MissionRow({ resolution, completedToday, onPress }: Props) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.row, pressed && styles.pressed]}>
      <View style={[styles.iconWrap, { backgroundColor: `${resolution.color}29` }]}>
        <Ionicons name={resolution.icon as any} size={19} color={resolution.color} />
      </View>
      <View style={styles.meta}>
        <Text style={styles.name}>{resolution.name}</Text>
        <Text style={styles.freq}>{resolution.frequencyLabel}</Text>
      </View>
      <StreakBadge streak={resolution.currentStreak} />
      <Ionicons
        name={completedToday ? 'checkmark-circle' : 'ellipse-outline'}
        size={24}
        color={completedToday ? '#2FA84F' : '#B8B6B2'}
        style={{ marginLeft: 10 }}
      />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 13,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: '#E5E2DC',
  },
  pressed: {
    opacity: 0.7,
  },
  iconWrap: {
    width: 38,
    height: 38,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  meta: {
    flex: 1,
  },
  name: {
    fontSize: 15.5,
    fontWeight: '700',
    color: '#1C1C1E',
  },
  freq: {
    fontSize: 12.5,
    color: '#6E6E73',
    marginTop: 1,
  },
});
