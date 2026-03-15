import Foundation
@preconcurrency import CoreBluetooth

/// Protocol for the event emitter (ObjC++ BlePlx module)
@objc public protocol BLEEventEmitter: AnyObject {
    func sendEvent(withName name: String, body: Any?)
}

// MARK: - Event names

private enum EventName {
    static let scanResult = "onScanResult"
    static let connectionStateChange = "onConnectionStateChange"
    static let characteristicValueUpdate = "onCharacteristicValueUpdate"
    static let stateChange = "onStateChange"
    static let restoreState = "onRestoreState"
    static let error = "onError"
    static let bondStateChange = "onBondStateChange"
    static let connectionEvent = "onConnectionEvent"
    static let l2capData = "onL2CAPData"
    static let l2capClose = "onL2CAPClose"
}

// MARK: - BLEModuleImpl

/// @objc Swift class that bridges between the ObjC++ TurboModule entry and the Swift actor.
/// All methods are called from the ObjC++ layer and delegate to BLEActor.
@objc public class BLEModuleImpl: NSObject {

    private var eventEmitterAdapter: EventEmitterAdapter?
    private var eventEmitter: BLEEventEmitter? { eventEmitterAdapter }
    private var actor: BLEActor?

    @objc public init(eventEmitter: RCTEventEmitter) {
        self.eventEmitterAdapter = EventEmitterAdapter(emitter: eventEmitter)
        super.init()
    }

    @objc public static func supportedEventNames() -> [String] {
        return [
            EventName.scanResult,
            EventName.connectionStateChange,
            EventName.characteristicValueUpdate,
            EventName.stateChange,
            EventName.restoreState,
            EventName.error,
            EventName.bondStateChange,
            EventName.connectionEvent,
            EventName.l2capData,
            EventName.l2capClose,
        ]
    }

    // MARK: - Private helpers

    private func sendEvent(_ name: String, body: Any?) {
        eventEmitter?.sendEvent(withName: name, body: body)
    }

    private func rejectWithError(_ reject: @escaping RCTPromiseRejectBlock, error: BleError) {
        reject(String(error.code.rawValue), error.message, nil)
        sendEvent(EventName.error, body: error.toDictionary())
    }

    private func rejectWithError(_ reject: @escaping RCTPromiseRejectBlock, error: Error) {
        if let bleError = error as? BleError {
            rejectWithError(reject, error: bleError)
        } else {
            let bleError = BleError(code: .unknown, message: error.localizedDescription)
            rejectWithError(reject, error: bleError)
        }
    }

    // MARK: - Lifecycle

    @objc public func createClient(
        restoreStateIdentifier: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        let emitter = self

        actor = BLEActor(
            onScanResult: { [weak emitter] snapshot in
                emitter?.sendEvent(EventName.scanResult, body: snapshot.toDictionary())
            },
            onConnectionStateChange: { [weak emitter] deviceId, state, error in
                var body: [String: Any] = [
                    "deviceId": deviceId,
                    "state": state,
                ]
                body["errorCode"] = error?.code.rawValue
                body["errorMessage"] = error?.message
                emitter?.sendEvent(EventName.connectionStateChange, body: body)
            },
            onCharacteristicValueUpdate: { [weak emitter] deviceId, serviceUuid, charUuid, value, transactionId in
                var body: [String: Any] = [
                    "deviceId": deviceId,
                    "serviceUuid": serviceUuid,
                    "characteristicUuid": charUuid,
                    "value": value ?? "",
                ]
                body["transactionId"] = transactionId
                emitter?.sendEvent(EventName.characteristicValueUpdate, body: body)
            },
            onStateChange: { [weak emitter] state in
                emitter?.sendEvent(EventName.stateChange, body: ["state": state])
            },
            onRestoreState: { [weak emitter] devices in
                let deviceDicts = devices.map { $0.toDictionary() }
                emitter?.sendEvent(EventName.restoreState, body: ["devices": deviceDicts])
            },
            onError: { [weak emitter] error in
                emitter?.sendEvent(EventName.error, body: error.toDictionary())
            },
            onL2CAPData: { [weak emitter] channelId, data in
                emitter?.sendEvent(EventName.l2capData, body: ["channelId": channelId, "data": data])
            },
            onL2CAPClose: { [weak emitter] channelId, error in
                emitter?.sendEvent(EventName.l2capClose, body: ["channelId": channelId, "error": error as Any])
            }
        )

        Task {
            await actor?.createClient(restoreStateIdentifier: restoreStateIdentifier)
            resolve(nil)
        }
    }

    @objc public func destroyClient(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            await actor?.destroyClient()
            actor = nil
            resolve(nil)
        }
    }

    @objc public func invalidate() {
        Task {
            await actor?.destroyClient()
            actor = nil
        }
    }

    // MARK: - State

    @objc public func state(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            let state = await actor?.state() ?? "Unknown"
            resolve(state)
        }
    }

    // MARK: - Scanning

    @objc public func startDeviceScan(
        uuids: [String]?,
        options: NSDictionary?
    ) {
        let serviceUuids = uuids?.compactMap { CBUUID(string: $0) }
        let opts = options as? [String: Any]

        Task {
            await actor?.startDeviceScan(serviceUuids: serviceUuids, options: opts)
        }
    }

    @objc public func stopDeviceScan(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            await actor?.stopDeviceScan()
            resolve(nil)
        }
    }

    // MARK: - Connection

    @objc public func connectToDevice(
        deviceId: String,
        options: NSDictionary?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        let opts = options as? [String: Any]

        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                let snapshot = try await actor.connectToDevice(deviceId: deviceId, options: opts)
                resolve(snapshot.toDictionary())
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    @objc public func cancelDeviceConnection(
        deviceId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                let snapshot = try await actor.cancelDeviceConnection(deviceId: deviceId)
                resolve(snapshot.toDictionary())
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    @objc public func isDeviceConnected(
        deviceId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                let connected = try await actor.isDeviceConnected(deviceId: deviceId)
                resolve(connected)
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    // MARK: - Discovery

    @objc public func discoverAllServicesAndCharacteristics(
        deviceId: String,
        transactionId: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                let snapshot = try await actor.discoverAllServicesAndCharacteristics(deviceId: deviceId)
                resolve(snapshot.toDictionary())
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    // MARK: - Read/Write

    @objc public func readCharacteristic(
        deviceId: String,
        serviceUuid: String,
        characteristicUuid: String,
        transactionId: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                let snapshot = try await actor.readCharacteristic(
                    deviceId: deviceId,
                    serviceUuid: serviceUuid,
                    characteristicUuid: characteristicUuid,
                    transactionId: transactionId
                )
                resolve(snapshot.toDictionary())
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    @objc public func writeCharacteristic(
        deviceId: String,
        serviceUuid: String,
        characteristicUuid: String,
        value: String,
        withResponse: Bool,
        transactionId: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                guard let data = Data(base64Encoded: value) else {
                    throw BleError(code: .invalidIdentifiers, message: "Invalid base64 value")
                }
                let snapshot = try await actor.writeCharacteristic(
                    deviceId: deviceId,
                    serviceUuid: serviceUuid,
                    characteristicUuid: characteristicUuid,
                    value: data,
                    withResponse: withResponse,
                    transactionId: transactionId
                )
                resolve(snapshot.toDictionary())
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    // MARK: - Monitor

    @objc public func monitorCharacteristic(
        deviceId: String,
        serviceUuid: String,
        characteristicUuid: String,
        subscriptionType: String?,
        transactionId: String?
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                try await actor.monitorCharacteristic(
                    deviceId: deviceId,
                    serviceUuid: serviceUuid,
                    characteristicUuid: characteristicUuid,
                    transactionId: transactionId
                )
            } catch {
                if let bleError = error as? BleError {
                    sendEvent(EventName.error, body: bleError.toDictionary())
                }
            }
        }
    }

    // MARK: - MTU

    @objc public func getMtu(
        deviceId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                let mtu = try await actor.getMtu(deviceId: deviceId)
                resolve(mtu)
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    @objc public func requestMtu(
        deviceId: String,
        mtu: NSInteger,
        transactionId: String?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                let snapshot = try await actor.requestMtu(deviceId: deviceId, mtu: mtu)
                resolve(snapshot.toDictionary())
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    // MARK: - PHY (Not supported on iOS)

    @objc public func requestPhy(
        deviceId: String,
        txPhy: NSInteger,
        rxPhy: NSInteger,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        // PHY selection is not available on iOS
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                let wrapper = try await actor.discoverAllServicesAndCharacteristics(deviceId: deviceId)
                resolve(wrapper.toDictionary())
            } catch {
                reject(String(BleErrorCode.operationStartFailed.rawValue),
                       "PHY selection is not supported on iOS", nil)
            }
        }
    }

    @objc public func readPhy(
        deviceId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        reject(String(BleErrorCode.operationStartFailed.rawValue),
               "PHY reading is not supported on iOS", nil)
    }

    // MARK: - Connection Priority (Not applicable on iOS)

    @objc public func requestConnectionPriority(
        deviceId: String,
        priority: NSInteger,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        // Connection priority is an Android-only concept
        reject(String(BleErrorCode.operationStartFailed.rawValue),
               "Connection priority is not supported on iOS", nil)
    }

    // MARK: - L2CAP

    @objc public func openL2CAPChannel(
        deviceId: String,
        psm: NSInteger,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                let channelId = try await actor.openL2CAPChannel(deviceId: deviceId, psm: UInt16(psm))
                resolve(["channelId": channelId])
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    @objc public func writeL2CAPChannel(
        channelId: NSInteger,
        data: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                guard let binaryData = Data(base64Encoded: data) else {
                    throw BleError(code: .invalidIdentifiers, message: "Invalid base64 data")
                }
                try await actor.writeL2CAPChannel(channelId: channelId, data: binaryData)
                resolve(nil)
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    @objc public func closeL2CAPChannel(
        channelId: NSInteger,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            do {
                guard let actor = actor else {
                    throw BleError(code: .bluetoothManagerDestroyed, message: "BLE manager not initialized")
                }
                try await actor.closeL2CAPChannel(channelId: channelId)
                resolve(nil)
            } catch {
                rejectWithError(reject, error: error)
            }
        }
    }

    // MARK: - Bonding (Limited on iOS)

    @objc public func getBondedDevices(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        // iOS doesn't expose bonded device list via CoreBluetooth
        resolve([])
    }

    // MARK: - Authorization

    @objc public func getAuthorizationStatus(
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .allowedAlways:
                resolve("authorized")
            case .denied:
                resolve("denied")
            case .restricted:
                resolve("restricted")
            case .notDetermined:
                resolve("notDetermined")
            @unknown default:
                resolve("notDetermined")
            }
        } else {
            // Before iOS 13.1, BLE was always authorized if the app had the permission
            resolve("authorized")
        }
    }

    // MARK: - Cancellation

    @objc public func cancelTransaction(
        transactionId: String,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        Task {
            await actor?.cancelTransaction(transactionId)
            resolve(nil)
        }
    }
}

// MARK: - RCTEventEmitter adapter

/// Wraps an RCTEventEmitter (from ObjC) to conform to BLEEventEmitter.
/// Since RCTEventEmitter is an ObjC class, we use a thin wrapper.
class EventEmitterAdapter: BLEEventEmitter {
    private weak var emitter: RCTEventEmitter?

    init(emitter: RCTEventEmitter) {
        self.emitter = emitter
    }

    func sendEvent(withName name: String, body: Any?) {
        emitter?.sendEvent(withName: name, body: body)
    }
}
