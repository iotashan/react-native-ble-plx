import React, { useEffect, useState, useCallback, useRef } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  Platform,
  PermissionsAndroid,
  Alert,
} from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { ScanResult } from 'react-native-ble-plx';
import type { RootStackParamList } from '../App';

type Props = NativeStackScreenProps<RootStackParamList, 'Scan'>;

async function requestAndroidPermissions(): Promise<boolean> {
  if (Platform.OS !== 'android') return true;

  try {
    const granted = await PermissionsAndroid.requestMultiple([
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_SCAN,
      PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT,
      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
    ]);
    return Object.values(granted).every(
      (v) => v === PermissionsAndroid.RESULTS.GRANTED,
    );
  } catch {
    return false;
  }
}

export default function ScanScreen({ navigation, route }: Props) {
  const manager = route.params.manager;
  const [scanning, setScanning] = useState(false);
  const [bleState, setBleState] = useState<string>('Unknown');
  const [devices, setDevices] = useState<Map<string, ScanResult>>(new Map());
  const devicesRef = useRef<Map<string, ScanResult>>(new Map());

  useEffect(() => {
    const sub = manager.onStateChange((state: string) => {
      setBleState(state);
    }, true);

    requestAndroidPermissions().then((ok) => {
      if (!ok) {
        Alert.alert('Permissions', 'BLE permissions not granted');
      }
    });

    return () => sub.remove();
  }, [manager]);

  const startScan = useCallback(() => {
    devicesRef.current = new Map();
    setDevices(new Map());
    setScanning(true);

    manager.startDeviceScan(null, null, (error, result) => {
      if (error) {
        console.warn('Scan error:', error);
        setScanning(false);
        return;
      }
      if (result) {
        devicesRef.current.set(result.id, result);
        setDevices(new Map(devicesRef.current));
      }
    });
  }, [manager]);

  const stopScan = useCallback(() => {
    manager.stopDeviceScan();
    setScanning(false);
  }, [manager]);

  const connectToDevice = useCallback(
    async (deviceId: string) => {
      stopScan();
      try {
        const device = await manager.connectToDevice(deviceId);
        navigation.navigate('Device', { manager, deviceId: device.id, deviceName: device.name });
      } catch (e: any) {
        Alert.alert('Connection Error', e.message || String(e));
      }
    },
    [manager, navigation, stopScan],
  );

  const deviceList = Array.from(devices.values());

  return (
    <View style={styles.container}>
      <Text style={styles.stateText}>BLE State: {bleState}</Text>

      <View style={styles.buttonRow}>
        <TouchableOpacity
          testID="scan-start-btn"
          style={[styles.button, scanning && styles.buttonDisabled]}
          onPress={startScan}
          disabled={scanning}>
          <Text style={styles.buttonText}>Start Scan</Text>
        </TouchableOpacity>
        <TouchableOpacity
          testID="scan-stop-btn"
          style={[styles.button, !scanning && styles.buttonDisabled]}
          onPress={stopScan}
          disabled={!scanning}>
          <Text style={styles.buttonText}>Stop Scan</Text>
        </TouchableOpacity>
      </View>

      <Text style={styles.countText}>
        {deviceList.length} device(s) found
      </Text>

      <FlatList
        testID="device-list"
        data={deviceList}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity
            testID={`device-item-${item.id}`}
            style={styles.deviceRow}
            onPress={() => connectToDevice(item.id)}>
            <Text style={styles.deviceName}>
              {item.name || 'Unknown Device'}
            </Text>
            <Text style={styles.deviceId}>{item.id}</Text>
            <Text style={styles.deviceRssi}>RSSI: {item.rssi}</Text>
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  stateText: { fontSize: 16, fontWeight: '600', marginBottom: 12 },
  buttonRow: { flexDirection: 'row', gap: 12, marginBottom: 12 },
  button: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
  },
  buttonDisabled: { backgroundColor: '#ccc' },
  buttonText: { color: '#fff', fontWeight: '600' },
  countText: { fontSize: 14, color: '#666', marginBottom: 8 },
  deviceRow: {
    padding: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  deviceName: { fontSize: 16, fontWeight: '500' },
  deviceId: { fontSize: 12, color: '#888', marginTop: 2 },
  deviceRssi: { fontSize: 12, color: '#888', marginTop: 2 },
});
