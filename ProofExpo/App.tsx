import { NavigationContainer } from '@react-navigation/native';
import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { RootNavigator } from './src/navigation/RootNavigator';
import { SignInScreen } from './src/screens/SignInScreen';
import { AppStateProvider, useAppState } from './src/state/AppState';

function Root() {
  const { signedIn } = useAppState();
  return signedIn ? <RootNavigator /> : <SignInScreen />;
}

export default function App() {
  return (
    <SafeAreaProvider>
      <AppStateProvider>
        <NavigationContainer>
          <Root />
        </NavigationContainer>
        <StatusBar style="auto" />
      </AppStateProvider>
    </SafeAreaProvider>
  );
}
