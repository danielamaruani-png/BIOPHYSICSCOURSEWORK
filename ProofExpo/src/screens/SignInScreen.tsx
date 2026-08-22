import { Ionicons } from '@expo/vector-icons';
import React from 'react';
import { Platform, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { PrimaryButton } from '../components/PrimaryButton';
import { useAppState } from '../state/AppState';

export function SignInScreen() {
  const { signIn } = useAppState();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.spacer} />
      <Text style={styles.title}>Proof</Text>
      <Text style={styles.subtitle}>Post today's proof. Build the streak.</Text>
      <View style={styles.spacer} />

      <View style={styles.buttons}>
        {Platform.OS === 'ios' && (
          <PrimaryButton title="Continue with Apple" icon="logo-apple" onPress={() => signIn('apple')} />
        )}
        <PrimaryButton
          title="Continue with Google"
          icon="logo-google"
          variant="secondary"
          onPress={() => signIn('google')}
        />
      </View>

      <Text style={styles.note}>
        Aperçu Expo Go — pas de vrai compte requis, ceci simule la connexion.
      </Text>
      <View style={styles.spacer} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F6F3EF',
    paddingHorizontal: 24,
    alignItems: 'center',
  },
  spacer: {
    flex: 1,
  },
  title: {
    fontSize: 44,
    fontWeight: '800',
    color: '#1C1C1E',
  },
  subtitle: {
    fontSize: 15,
    color: '#6E6E73',
    marginTop: 6,
  },
  buttons: {
    width: '100%',
    gap: 12,
  },
  note: {
    marginTop: 16,
    fontSize: 12,
    color: '#B8B6B2',
    textAlign: 'center',
  },
});
