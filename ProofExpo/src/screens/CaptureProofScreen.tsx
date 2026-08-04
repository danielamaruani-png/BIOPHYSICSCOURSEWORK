import { Ionicons } from '@expo/vector-icons';
import { useNavigation, useRoute } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import * as ImagePicker from 'expo-image-picker';
import React, { useState } from 'react';
import { Alert, Image, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { PrimaryButton } from '../components/PrimaryButton';
import { RootStackParamList } from '../navigation/types';
import { useAppState } from '../state/AppState';

const CAPTION_LIMIT = 100;

export function CaptureProofScreen() {
  const navigation = useNavigation<NativeStackNavigationProp<RootStackParamList>>();
  const route = useRoute<any>();
  const { resolutionId } = route.params as { resolutionId: string };
  const { resolutions, postProof } = useAppState();
  const resolution = resolutions.find((r) => r.id === resolutionId);

  const [photoUri, setPhotoUri] = useState<string | null>(null);
  const [caption, setCaption] = useState('');
  const [submitting, setSubmitting] = useState(false);

  if (!resolution) return null;

  async function pickFrom(source: 'camera' | 'library') {
    const permission =
      source === 'camera'
        ? await ImagePicker.requestCameraPermissionsAsync()
        : await ImagePicker.requestMediaLibraryPermissionsAsync();

    if (!permission.granted) {
      Alert.alert('Permission needed', `Proof needs access to your ${source === 'camera' ? 'camera' : 'photos'} to continue.`);
      return;
    }

    const result =
      source === 'camera'
        ? await ImagePicker.launchCameraAsync({ quality: 0.6, allowsEditing: true, aspect: [1, 1] })
        : await ImagePicker.launchImageLibraryAsync({ quality: 0.6, allowsEditing: true, aspect: [1, 1] });

    if (!result.canceled && result.assets[0]) {
      setPhotoUri(result.assets[0].uri);
    }
  }

  function submit() {
    if (!photoUri) return;
    setSubmitting(true);
    postProof(resolutionId, photoUri, caption.trim());
    setSubmitting(false);
    navigation.goBack();
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Pressable onPress={() => navigation.goBack()}>
          <Text style={styles.cancel}>Cancel</Text>
        </Pressable>
        <Text style={styles.title}>{resolution.name}</Text>
        <View style={{ width: 50 }} />
      </View>

      <Pressable style={styles.photoWell} onPress={() => pickFrom('camera')}>
        {photoUri ? (
          <Image source={{ uri: photoUri }} style={StyleSheet.absoluteFill} />
        ) : (
          <>
            <Ionicons name="camera-outline" size={34} color="#6E6E73" />
            <Text style={styles.photoWellText}>Add today's photo</Text>
          </>
        )}
      </Pressable>

      <View style={styles.actionsRow}>
        <PrimaryButton title="Take photo" icon="camera" variant="secondary" onPress={() => pickFrom('camera')} />
        <View style={{ width: 10 }} />
        <PrimaryButton title="Choose from library" icon="images" variant="secondary" onPress={() => pickFrom('library')} />
      </View>

      <TextInput
        style={styles.caption}
        placeholder="Caption (optional)"
        placeholderTextColor="#B8B6B2"
        multiline
        maxLength={CAPTION_LIMIT}
        value={caption}
        onChangeText={setCaption}
      />
      <Text style={styles.charCount}>
        {caption.length}/{CAPTION_LIMIT}
      </Text>

      <View style={{ flex: 1 }} />

      <PrimaryButton title="Post proof" icon="checkmark" disabled={!photoUri} loading={submitting} onPress={submit} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F6F3EF',
    padding: 16,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  cancel: {
    color: '#FF6B35',
    fontSize: 16,
    fontWeight: '600',
    width: 60,
  },
  title: {
    fontSize: 17,
    fontWeight: '700',
    color: '#1C1C1E',
  },
  photoWell: {
    aspectRatio: 1,
    borderRadius: 20,
    backgroundColor: '#FBFAF8',
    borderWidth: 1,
    borderStyle: 'dashed',
    borderColor: '#E5E2DC',
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
    marginBottom: 14,
  },
  photoWellText: {
    color: '#6E6E73',
    fontWeight: '600',
    fontSize: 13,
    marginTop: 8,
  },
  actionsRow: {
    flexDirection: 'row',
    marginBottom: 16,
  },
  caption: {
    borderWidth: 1,
    borderColor: '#E5E2DC',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 12,
    fontSize: 14.5,
    minHeight: 52,
  },
  charCount: {
    fontSize: 11.5,
    color: '#B8B6B2',
    textAlign: 'right',
    marginTop: 5,
  },
});
