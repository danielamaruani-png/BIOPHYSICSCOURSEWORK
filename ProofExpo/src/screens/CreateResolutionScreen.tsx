import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import React, { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { PrimaryButton } from '../components/PrimaryButton';
import { RootStackParamList } from '../navigation/types';
import { useAppState } from '../state/AppState';
import { Category } from '../types';

const CATEGORIES: { key: Category; label: string; icon: string }[] = [
  { key: 'fitness', label: 'Fitness', icon: 'walk-outline' },
  { key: 'reading', label: 'Reading', icon: 'book-outline' },
  { key: 'coding', label: 'Coding', icon: 'code-slash-outline' },
  { key: 'mindfulness', label: 'Mindfulness', icon: 'leaf-outline' },
  { key: 'other', label: 'Other', icon: 'star-outline' },
];

const SWATCHES = ['#E7414C', '#2EC4B6', '#6A4C93', '#1982C4', '#FFB703'];
const FREQUENCIES = ['Every day', 'Weekdays', '3x / week'];

export function CreateResolutionScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const { addResolution } = useAppState();

  const [name, setName] = useState('');
  const [category, setCategory] = useState<Category>('fitness');
  const [color, setColor] = useState(SWATCHES[0]);
  const [frequency, setFrequency] = useState(FREQUENCIES[0]);

  const isValid = name.trim().length > 0;
  const icon = CATEGORIES.find((c) => c.key === category)?.icon ?? 'star-outline';

  function save() {
    if (!isValid) return;
    addResolution({ name: name.trim(), category, icon, color, frequencyLabel: frequency });
    navigation.goBack();
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()}>
          <Text style={styles.cancel}>Cancel</Text>
        </Pressable>
        <Text style={styles.title}>New resolution</Text>
        <Pressable onPress={save} disabled={!isValid}>
          <Text style={[styles.save, !isValid && styles.saveDisabled]}>Save</Text>
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.fieldLabel}>Goal</Text>
        <TextInput style={styles.input} placeholder="e.g. Meditate 10 min" value={name} onChangeText={setName} />

        <Text style={styles.fieldLabel}>Category</Text>
        <View style={styles.chipRow}>
          {CATEGORIES.map((c) => (
            <Pressable
              key={c.key}
              style={[styles.chip, category === c.key && styles.chipSelected]}
              onPress={() => setCategory(c.key)}
            >
              <Ionicons name={c.icon as any} size={13} color={category === c.key ? '#fff' : '#1C1C1E'} />
              <Text style={[styles.chipText, category === c.key && styles.chipTextSelected]}>{c.label}</Text>
            </Pressable>
          ))}
        </View>

        <Text style={styles.fieldLabel}>Frequency</Text>
        <View style={styles.segRow}>
          {FREQUENCIES.map((f) => (
            <Pressable
              key={f}
              style={[styles.segOpt, frequency === f && styles.segOptSelected]}
              onPress={() => setFrequency(f)}
            >
              <Text style={[styles.segText, frequency === f && styles.segTextSelected]}>{f}</Text>
            </Pressable>
          ))}
        </View>

        <Text style={styles.fieldLabel}>Colour</Text>
        <View style={styles.swatchRow}>
          {SWATCHES.map((c) => (
            <Pressable
              key={c}
              style={[styles.swatch, { backgroundColor: c }, color === c && styles.swatchSelected]}
              onPress={() => setColor(c)}
            />
          ))}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F6F3EF' },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 16,
    paddingBottom: 8,
  },
  cancel: { color: '#FF6B35', fontSize: 16, fontWeight: '600' },
  save: { color: '#FF6B35', fontSize: 16, fontWeight: '800' },
  saveDisabled: { opacity: 0.4 },
  title: { fontSize: 17, fontWeight: '700', color: '#1C1C1E' },
  content: { padding: 16 },
  fieldLabel: {
    fontSize: 12,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    color: '#6E6E73',
    marginTop: 16,
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#E5E2DC',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 12,
    fontSize: 15,
  },
  chipRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderWidth: 1,
    borderColor: '#E5E2DC',
    backgroundColor: '#fff',
    borderRadius: 20,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  chipSelected: { backgroundColor: '#FF6B35', borderColor: '#FF6B35' },
  chipText: { fontSize: 12.5, fontWeight: '700', color: '#1C1C1E' },
  chipTextSelected: { color: '#fff' },
  segRow: { flexDirection: 'row', backgroundColor: '#FBFAF8', borderRadius: 10, padding: 3 },
  segOpt: { flex: 1, alignItems: 'center', paddingVertical: 7, borderRadius: 8 },
  segOptSelected: { backgroundColor: '#fff' },
  segText: { fontSize: 12, fontWeight: '700', color: '#6E6E73' },
  segTextSelected: { color: '#1C1C1E' },
  swatchRow: { flexDirection: 'row', gap: 10 },
  swatch: { width: 30, height: 30, borderRadius: 15 },
  swatchSelected: { borderWidth: 2, borderColor: '#1C1C1E' },
});
