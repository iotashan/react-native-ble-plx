import React, { useState, useCallback, useRef, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  TextInput,
  Switch,
  StyleSheet,
  Alert,
  ScrollView,
  Platform,
} from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { Subscription } from 'react-native-ble-plx';
import type { RootStackParamList } from '../App';

type Props = NativeStackScreenProps<RootStackParamList, 'Characteristic'>;

export default function CharacteristicScreen({ route }: Props) {
  const { manager, deviceId, serviceUuid, characteristicUuid, properties } =
    route.params;

  const [value, setValue] = useState<string>('(none)');
  const [writeValue, setWriteValue] = useState('');
  const [monitoring, setMonitoring] = useState(false);
  const monitorSub = useRef<Subscription | null>(null);

  useEffect(() => {
    return () => {
      monitorSub.current?.remove();
    };
  }, []);

  const readCharacteristic = useCallback(async () => {
    try {
      const result = await manager.readCharacteristicForDevice(
        deviceId,
        serviceUuid,
        characteristicUuid,
      );
      setValue(result.value ?? '(null)');
    } catch (e: any) {
      Alert.alert('Read Error', e.message || String(e));
    }
  }, [manager, deviceId, serviceUuid, characteristicUuid]);

  const writeCharacteristic = useCallback(async () => {
    try {
      await manager.writeCharacteristicForDevice(
        deviceId,
        serviceUuid,
        characteristicUuid,
        writeValue,
        properties.isWritableWithResponse,
      );
      Alert.alert('Write', 'Value written successfully');
    } catch (e: any) {
      Alert.alert('Write Error', e.message || String(e));
    }
  }, [manager, deviceId, serviceUuid, characteristicUuid, writeValue, properties]);

  const toggleMonitor = useCallback(
    (enabled: boolean) => {
      if (enabled) {
        monitorSub.current = manager.monitorCharacteristicForDevice(
          deviceId,
          serviceUuid,
          characteristicUuid,
          (error, event) => {
            if (error) {
              console.warn('Monitor error:', error);
              setMonitoring(false);
              return;
            }
            if (event) {
              setValue(event.value);
            }
          },
        );
        setMonitoring(true);
      } else {
        monitorSub.current?.remove();
        monitorSub.current = null;
        setMonitoring(false);
      }
    },
    [manager, deviceId, serviceUuid, characteristicUuid],
  );

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Characteristic</Text>
      <Text style={styles.uuid}>{characteristicUuid}</Text>
      <Text style={styles.service}>Service: {serviceUuid}</Text>

      <View style={styles.propsRow}>
        <Text style={styles.propLabel}>Properties:</Text>
        <Text style={styles.propValue}>
          {[
            properties.isReadable && 'Readable',
            properties.isWritableWithResponse && 'Writable (response)',
            properties.isWritableWithoutResponse && 'Writable (no response)',
            properties.isNotifying && 'Notifiable',
            properties.isIndicatable && 'Indicatable',
          ]
            .filter(Boolean)
            .join(', ') || 'None'}
        </Text>
      </View>

      <View style={styles.section}>
        <Text testID="value-display" style={styles.valueText}>
          Value: {value}
        </Text>
      </View>

      {properties.isReadable && (
        <TouchableOpacity
          testID="read-btn"
          style={styles.button}
          onPress={readCharacteristic}>
          <Text style={styles.buttonText}>Read</Text>
        </TouchableOpacity>
      )}

      {(properties.isWritableWithResponse ||
        properties.isWritableWithoutResponse) && (
        <View style={styles.writeSection}>
          <TextInput
            testID="write-input"
            style={styles.textInput}
            value={writeValue}
            onChangeText={setWriteValue}
            placeholder="Base64 value to write"
          />
          <TouchableOpacity
            testID="write-btn"
            style={styles.button}
            onPress={writeCharacteristic}>
            <Text style={styles.buttonText}>Write</Text>
          </TouchableOpacity>
        </View>
      )}

      {(properties.isNotifying || properties.isIndicatable) && (
        <View style={styles.monitorRow}>
          <Text style={styles.monitorLabel}>Monitor</Text>
          <Switch
            testID="monitor-toggle"
            value={monitoring}
            onValueChange={toggleMonitor}
          />
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  content: { padding: 16 },
  title: { fontSize: 20, fontWeight: '700' },
  uuid: { fontSize: 13, color: '#888', marginTop: 4 },
  service: { fontSize: 12, color: '#aaa', marginTop: 2 },
  propsRow: { marginTop: 12 },
  propLabel: { fontSize: 14, fontWeight: '600' },
  propValue: { fontSize: 13, color: '#555', marginTop: 2 },
  section: { marginTop: 16, marginBottom: 12 },
  valueText: { fontSize: 16, fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace' },
  button: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
    alignSelf: 'flex-start',
    marginTop: 8,
  },
  buttonText: { color: '#fff', fontWeight: '600' },
  writeSection: { marginTop: 12 },
  textInput: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 10,
    fontSize: 14,
  },
  monitorRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 16,
    paddingVertical: 8,
  },
  monitorLabel: { fontSize: 16, fontWeight: '600' },
});
