import React, { useState, useCallback, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  FlatList,
  StyleSheet,
  Alert,
} from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import type { CharacteristicInfo } from 'react-native-ble-plx';
import type { RootStackParamList } from '../App';

type Props = NativeStackScreenProps<RootStackParamList, 'Device'>;

interface ServiceGroup {
  serviceUuid: string;
  characteristics: CharacteristicInfo[];
}

export default function DeviceScreen({ navigation, route }: Props) {
  const { manager, deviceId, deviceName } = route.params;
  const [mtu, setMtu] = useState<number | null>(null);
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [services, _setServices] = useState<ServiceGroup[]>([]);
  const [discovering, setDiscovering] = useState(false);

  useEffect(() => {
    manager.getMtu(deviceId).then(setMtu).catch(() => {});
  }, [manager, deviceId]);

  const discoverServices = useCallback(async () => {
    setDiscovering(true);
    try {
      await manager.discoverAllServicesAndCharacteristics(deviceId);
      // The v4 API returns DeviceInfo from discover, but characteristics
      // need to be read separately. For now we show the discovery was successful.
      // In a full implementation we'd query for services/characteristics.
      Alert.alert('Discovery', 'Services and characteristics discovered. Characteristic browsing requires servicesForDevice() API (not yet in v4 spec).');
    } catch (e: any) {
      Alert.alert('Discovery Error', e.message || String(e));
    } finally {
      setDiscovering(false);
    }
  }, [manager, deviceId]);

  const disconnect = useCallback(async () => {
    try {
      await manager.cancelDeviceConnection(deviceId);
      navigation.goBack();
    } catch (e: any) {
      Alert.alert('Disconnect Error', e.message || String(e));
    }
  }, [manager, deviceId, navigation]);

  return (
    <View style={styles.container}>
      <View style={styles.infoSection}>
        <Text style={styles.deviceName}>{deviceName || 'Unknown Device'}</Text>
        <Text style={styles.deviceId}>ID: {deviceId}</Text>
        {mtu != null && <Text style={styles.mtuText}>MTU: {mtu}</Text>}
      </View>

      <View style={styles.buttonRow}>
        <TouchableOpacity
          testID="discover-btn"
          style={[styles.button, discovering && styles.buttonDisabled]}
          onPress={discoverServices}
          disabled={discovering}>
          <Text style={styles.buttonText}>
            {discovering ? 'Discovering...' : 'Discover Services'}
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          testID="disconnect-btn"
          style={[styles.button, styles.disconnectButton]}
          onPress={disconnect}>
          <Text style={styles.buttonText}>Disconnect</Text>
        </TouchableOpacity>
      </View>

      {services.length > 0 && (
        <FlatList
          data={services}
          keyExtractor={(item) => item.serviceUuid}
          renderItem={({ item }) => (
            <View testID={`service-${item.serviceUuid}`} style={styles.serviceGroup}>
              <Text style={styles.serviceUuid}>Service: {item.serviceUuid}</Text>
              {item.characteristics.map((char) => (
                <TouchableOpacity
                  key={char.uuid}
                  testID={`char-${char.uuid}`}
                  style={styles.charRow}
                  onPress={() =>
                    navigation.navigate('Characteristic', {
                      manager,
                      deviceId,
                      serviceUuid: item.serviceUuid,
                      characteristicUuid: char.uuid,
                      properties: {
                        isReadable: char.isReadable,
                        isWritableWithResponse: char.isWritableWithResponse,
                        isWritableWithoutResponse: char.isWritableWithoutResponse,
                        isNotifying: char.isNotifying,
                        isIndicatable: char.isIndicatable,
                      },
                    })
                  }>
                  <Text style={styles.charUuid}>{char.uuid}</Text>
                  <Text style={styles.charProps}>
                    {[
                      char.isReadable && 'Read',
                      (char.isWritableWithResponse || char.isWritableWithoutResponse) && 'Write',
                      char.isNotifying && 'Notify',
                      char.isIndicatable && 'Indicate',
                    ]
                      .filter(Boolean)
                      .join(', ')}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          )}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, backgroundColor: '#fff' },
  infoSection: { marginBottom: 16 },
  deviceName: { fontSize: 20, fontWeight: '700' },
  deviceId: { fontSize: 13, color: '#888', marginTop: 4 },
  mtuText: { fontSize: 13, color: '#888', marginTop: 2 },
  buttonRow: { flexDirection: 'row', gap: 12, marginBottom: 16 },
  button: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
  },
  buttonDisabled: { backgroundColor: '#ccc' },
  disconnectButton: { backgroundColor: '#FF3B30' },
  buttonText: { color: '#fff', fontWeight: '600' },
  serviceGroup: { marginBottom: 16 },
  serviceUuid: { fontSize: 14, fontWeight: '600', marginBottom: 6 },
  charRow: {
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  charUuid: { fontSize: 13 },
  charProps: { fontSize: 11, color: '#888', marginTop: 2 },
});
