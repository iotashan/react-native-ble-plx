# Maestro Hardware Integration Tests

These flows test the react-native-ble-plx library against real BLE hardware
using the [Maestro](https://maestro.mobile.dev) mobile UI testing framework.

## Prerequisites

### Hardware

- A **BlePlxTest** peripheral must be flashed with the test firmware and powered
  on within BLE range of the device under test.
- The firmware is located in `integration-tests/hardware/peripheral-firmware/`.

### App

- The example app (`example/`) must be built and installed on the test device.
- Android package: `com.bleplxexample`
- iOS bundle ID: `org.reactjs.native.example.BlePlxExample`

### BLE Permissions

BLE permissions must be granted before the flows run. Maestro does not handle
system permission dialogs reliably on all platforms.

#### Android (API 31+)

Run the following `adb` commands after installing the app:

```bash
adb shell pm grant com.bleplxexample android.permission.BLUETOOTH_SCAN
adb shell pm grant com.bleplxexample android.permission.BLUETOOTH_CONNECT
adb shell pm grant com.bleplxexample android.permission.ACCESS_FINE_LOCATION
```

For Android API 28–30 (legacy location permission only):

```bash
adb shell pm grant com.bleplxexample android.permission.ACCESS_FINE_LOCATION
```

#### iOS

iOS BLE (`NSBluetoothAlwaysUsageDescription`) and location permissions must be
granted manually on first launch. Open the app on the device, accept all
permission prompts, then terminate and re-launch before running the flows.

Alternatively, if using an iOS simulator with a paired BLE adapter, no
permission prompt appears.

## Running the Flows

Ensure the `maestro` CLI is installed (`brew install maestro` on macOS).

### Individual flows

```bash
# Full happy path: scan, connect, read characteristic, disconnect
maestro test integration-tests/hardware/maestro/scan-pair-sync.yaml

# Write a value to echo characteristic and read it back
maestro test integration-tests/hardware/maestro/write-read-roundtrip.yaml

# Simulate unexpected disconnection and verify recovery
maestro test integration-tests/hardware/maestro/disconnect-recovery.yaml

# Sustained indication stream for 30 seconds
maestro test integration-tests/hardware/maestro/indicate-stress.yaml
```

### All flows in sequence

```bash
maestro test integration-tests/hardware/maestro/
```

## Flow Descriptions

| File | What it tests |
|------|---------------|
| `scan-pair-sync.yaml` | Full happy path: BLE scan, connect, discover, read, disconnect |
| `write-read-roundtrip.yaml` | Write to echo characteristic and verify read-back matches |
| `disconnect-recovery.yaml` | Unexpected peripheral disconnect; re-scan and reconnect |
| `indicate-stress.yaml` | 30-second indication stream stress test on CharacteristicScreen |

## TestIDs Reference

The example app uses the following `testID` props for Maestro assertions:

**ScanScreen** (`example/src/screens/ScanScreen.tsx`)

| testID | Element |
|--------|---------|
| `scan-start-btn` | Start Scan button |
| `scan-stop-btn` | Stop Scan button |
| `device-list` | FlatList of discovered devices |
| `device-item-{id}` | Individual device row (id = MAC address or UUID) |

**DeviceScreen** (`example/src/screens/DeviceScreen.tsx`)

| testID | Element |
|--------|---------|
| `discover-btn` | Discover Services button |
| `disconnect-btn` | Disconnect button |
| `service-{uuid}` | Service group container (populated after discovery) |
| `char-{uuid}` | Characteristic row (tap to navigate to CharacteristicScreen) |

**CharacteristicScreen** (`example/src/screens/CharacteristicScreen.tsx`)

| testID | Element |
|--------|---------|
| `read-btn` | Read button (visible when characteristic is readable) |
| `write-input` | TextInput for base64 write value |
| `write-btn` | Write button (visible when characteristic is writable) |
| `monitor-toggle` | Switch to enable/disable notifications or indications |
| `value-display` | Text showing the current characteristic value |

## Notes

- The `disconnect-recovery.yaml` flow requires a manual or automated step to
  trigger an unexpected disconnection from the firmware side. Annotated
  comments in the flow indicate where to insert a relay command or serial call.
- The `write-read-roundtrip.yaml` flow uses base64-encoded values. "Hello"
  encodes to `SGVsbG8=`.
- Discovery on DeviceScreen currently shows an alert because the v4 API's
  `servicesForDevice()` is not yet implemented; characteristic rows (char-{uuid})
  only appear once that API is available. Until then, flows that navigate to a
  characteristic require the service list to be populated by the firmware.
