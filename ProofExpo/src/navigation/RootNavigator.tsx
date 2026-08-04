import { Ionicons } from '@expo/vector-icons';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import React from 'react';
import { CaptureProofScreen } from '../screens/CaptureProofScreen';
import { CreateResolutionScreen } from '../screens/CreateResolutionScreen';
import { FriendsScreen } from '../screens/FriendsScreen';
import { HomeScreen } from '../screens/HomeScreen';
import { PartnerProofScreen } from '../screens/PartnerProofScreen';
import { ProfileScreen } from '../screens/ProfileScreen';
import { ProgressScreen } from '../screens/ProgressScreen';
import { MainTabParamList, RootStackParamList } from './types';

const Tab = createBottomTabNavigator<MainTabParamList>();
const Stack = createNativeStackNavigator<RootStackParamList>();

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarActiveTintColor: '#FF6B35',
        tabBarInactiveTintColor: '#B8B6B2',
        tabBarIcon: ({ color, size }) => {
          const icons: Record<keyof MainTabParamList, string> = {
            Today: 'checkmark-circle-outline',
            Friends: 'people-outline',
            Profile: 'person-circle-outline',
          };
          return <Ionicons name={icons[route.name as keyof MainTabParamList] as any} size={size} color={color} />;
        },
      })}
    >
      <Tab.Screen name="Today" component={HomeScreen} />
      <Tab.Screen name="Friends" component={FriendsScreen} />
      <Tab.Screen name="Profile" component={ProfileScreen} />
    </Tab.Navigator>
  );
}

export function RootNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="MainTabs" component={MainTabs} options={{ headerShown: false }} />
      <Stack.Screen name="CaptureProof" component={CaptureProofScreen} options={{ presentation: 'modal', headerShown: false }} />
      <Stack.Screen name="CreateResolution" component={CreateResolutionScreen} options={{ presentation: 'modal', headerShown: false }} />
      <Stack.Screen name="Progress" component={ProgressScreen} options={{ title: '' }} />
      <Stack.Screen name="PartnerProof" component={PartnerProofScreen} options={{ title: '' }} />
    </Stack.Navigator>
  );
}
