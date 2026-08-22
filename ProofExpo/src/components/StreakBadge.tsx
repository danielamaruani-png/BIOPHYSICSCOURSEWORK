import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

export function StreakBadge({ streak }: { streak: number }) {
  if (streak <= 0) return null;
  return (
    <View style={styles.badge}>
      <Text style={styles.text}>🔥 {streak}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    backgroundColor: 'rgba(255,107,53,0.15)',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 20,
  },
  text: {
    color: '#FF6B35',
    fontWeight: '800',
    fontSize: 12.5,
  },
});
