import Foundation
@preconcurrency import CoreBluetooth

// MARK: - RestoredPeripheralInfo

struct RestoredPeripheralInfo: Sendable {
    let id: String
    let name: String?
}

// MARK: - StateRestoration

/// Handles CoreBluetooth state restoration for background BLE operations.
/// - Re-attaches delegates to restored peripherals
/// - Stores peripheral references strongly (CB does not retain them)
/// - Buffers restoration data until JS subscribes
actor StateRestoration {
    private var restoredPeripherals: [UUID: CBPeripheral] = [:]
    private var bufferedRestorationData: [[String: Any]] = []
    private var hasJSSubscribed = false

    let queue: DispatchQueue
    nonisolated var unownedExecutor: UnownedSerialExecutor { queue.asUnownedSerialExecutor() }

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// Process restoration data from willRestoreState.
    /// Called before didUpdateState, so we must buffer.
    func handleRestoration(
        dict: [String: Any],
        peripheralFactory: (CBPeripheral) -> PeripheralWrapper
    ) -> [PeripheralWrapper] {
        var wrappers: [PeripheralWrapper] = []

        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                // Store strong reference — CB does NOT retain restored peripherals
                restoredPeripherals[peripheral.identifier] = peripheral

                let wrapper = peripheralFactory(peripheral)
                wrappers.append(wrapper)
            }
        }

        // Buffer the restoration data for when JS subscribes
        bufferedRestorationData.append(dict)

        return wrappers
    }

    /// Called when JS subscribes to restoration events.
    /// Returns any buffered data, then clears the buffer.
    func getBufferedRestorationData() -> [[String: Any]] {
        hasJSSubscribed = true
        let data = bufferedRestorationData
        bufferedRestorationData.removeAll()
        return data
    }

    /// Get restored peripheral info for the JS RestoreStateEvent
    func getRestoredDeviceInfos() -> [PeripheralSnapshot] {
        restoredPeripherals.values.map { peripheral in
            EventSerializer.snapshot(from: peripheral)
        }
    }

    /// Clean up restored peripheral references
    func cleanup() {
        restoredPeripherals.removeAll()
        bufferedRestorationData.removeAll()
    }
}
