import { Ionicons } from '@expo/vector-icons';
import React from 'react';
import { Image, StyleSheet, Text, View } from 'react-native';

interface Props {
  photoUri?: string;
  streak: number;
  completed: boolean;
  label: string;
}

/// BeReal-style tile: photo fills the frame, streak badge sits over the
/// top-left corner, name/status sits over a bottom scrim. Mirrors the
/// real WidgetKit PhotoTile in ProofWidget/ProofWidget.swift.
export function PhotoTile({ photoUri, streak, completed, label }: Props) {
  return (
    <View style={styles.tile}>
      {photoUri ? (
        <Image source={{ uri: photoUri }} style={StyleSheet.absoluteFill} />
      ) : (
        <View style={[StyleSheet.absoluteFill, styles.placeholder]} />
      )}
      <View style={styles.streakBadge}>
        <Text style={styles.streakText}>🔥 {streak}</Text>
      </View>
      <View style={styles.footer}>
        <Text style={styles.name} numberOfLines={1}>
          {label}
        </Text>
        {!completed && <Ionicons name="ellipse-outline" size={12} color="rgba(255,255,255,0.85)" />}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  tile: {
    flex: 1,
    borderRadius: 18,
    overflow: 'hidden',
    justifyContent: 'space-between',
    backgroundColor: '#ddd',
  },
  placeholder: {
    backgroundColor: '#D9D6CF',
  },
  streakBadge: {
    alignSelf: 'flex-start',
    margin: 8,
    backgroundColor: 'rgba(0,0,0,0.38)',
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderRadius: 20,
  },
  streakText: {
    color: '#fff',
    fontWeight: '800',
    fontSize: 12,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 9,
    paddingVertical: 7,
    backgroundColor: 'rgba(0,0,0,0.32)',
  },
  name: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 11,
    flexShrink: 1,
  },
});
