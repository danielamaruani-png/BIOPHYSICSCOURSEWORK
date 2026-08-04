import { Ionicons } from '@expo/vector-icons';
import React from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text } from 'react-native';

interface Props {
  title: string;
  icon?: React.ComponentProps<typeof Ionicons>['name'];
  onPress: () => void;
  disabled?: boolean;
  loading?: boolean;
  variant?: 'primary' | 'secondary' | 'danger';
}

export function PrimaryButton({ title, icon, onPress, disabled, loading, variant = 'primary' }: Props) {
  const isDisabled = disabled || loading;
  return (
    <Pressable
      onPress={onPress}
      disabled={isDisabled}
      style={({ pressed }) => [
        styles.base,
        variant === 'secondary' && styles.secondary,
        variant === 'danger' && styles.danger,
        isDisabled && styles.disabled,
        pressed && !isDisabled && styles.pressed,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={variant === 'secondary' ? '#FF6B35' : '#fff'} />
      ) : (
        <>
          {icon && (
            <Ionicons
              name={icon}
              size={18}
              color={variant === 'secondary' ? '#FF6B35' : variant === 'danger' ? '#E7414C' : '#fff'}
              style={{ marginRight: 8 }}
            />
          )}
          <Text
            style={[
              styles.text,
              variant === 'secondary' && styles.secondaryText,
              variant === 'danger' && styles.dangerText,
            ]}
          >
            {title}
          </Text>
        </>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  base: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FF6B35',
    borderRadius: 14,
    paddingVertical: 15,
  },
  secondary: {
    backgroundColor: '#F2F1F6',
  },
  danger: {
    backgroundColor: '#FDEBEC',
  },
  disabled: {
    opacity: 0.4,
  },
  pressed: {
    opacity: 0.85,
  },
  text: {
    color: '#fff',
    fontWeight: '700',
    fontSize: 16,
  },
  secondaryText: {
    color: '#FF6B35',
  },
  dangerText: {
    color: '#E7414C',
  },
});
