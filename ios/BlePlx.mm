//
//  BlePlx.mm
//  react-native-ble-plx
//
//  TurboModule entry point — ObjC++ bridge to Swift implementation
//

#import <React/RCTLog.h>
#import <React/RCTUtils.h>

#ifdef RCT_NEW_ARCH_ENABLED
#import <NativeBlePlxSpec/NativeBlePlxSpec.h>
#endif

// Auto-generated Swift bridge header
#if __has_include("react_native_ble_plx-Swift.h")
#import "react_native_ble_plx-Swift.h"
#else
#import <react_native_ble_plx/react_native_ble_plx-Swift.h>
#endif

#ifdef RCT_NEW_ARCH_ENABLED
@interface BlePlx : NativeBlePlxSpec
@end
#else
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
@interface BlePlx : RCTEventEmitter <RCTBridgeModule>
@end
#endif

@implementation BlePlx {
    BLEModuleImpl *_impl;
}

RCT_EXPORT_MODULE(NativeBlePlx)

- (instancetype)init {
    self = [super init];
    if (self) {
        _impl = [[BLEModuleImpl alloc] initWithEventEmitter:self];
    }
    return self;
}

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

- (void)invalidate {
    [_impl invalidate];
    [super invalidate];
}

- (NSArray<NSString *> *)supportedEvents {
    return [BLEModuleImpl supportedEventNames];
}

// MARK: - Lifecycle

RCT_EXPORT_METHOD(createClient:(NSString *)restoreStateIdentifier
                       resolve:(RCTPromiseResolveBlock)resolve
                        reject:(RCTPromiseRejectBlock)reject) {
    [_impl createClientWithRestoreStateIdentifier:restoreStateIdentifier resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(destroyClient:(RCTPromiseResolveBlock)resolve
                         reject:(RCTPromiseRejectBlock)reject) {
    [_impl destroyClientWithResolve:resolve reject:reject];
}

// MARK: - State

RCT_EXPORT_METHOD(state:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    [_impl stateWithResolve:resolve reject:reject];
}

// MARK: - Scanning

RCT_EXPORT_METHOD(startDeviceScan:(NSArray<NSString *> *)uuids
                          options:(NSDictionary *)options) {
    [_impl startDeviceScanWithUuids:uuids options:options];
}

RCT_EXPORT_METHOD(stopDeviceScan:(RCTPromiseResolveBlock)resolve
                          reject:(RCTPromiseRejectBlock)reject) {
    [_impl stopDeviceScanWithResolve:resolve reject:reject];
}

// MARK: - Connection

RCT_EXPORT_METHOD(connectToDevice:(NSString *)deviceId
                          options:(NSDictionary *)options
                          resolve:(RCTPromiseResolveBlock)resolve
                           reject:(RCTPromiseRejectBlock)reject) {
    [_impl connectToDeviceWithDeviceId:deviceId options:options resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(cancelDeviceConnection:(NSString *)deviceId
                                 resolve:(RCTPromiseResolveBlock)resolve
                                  reject:(RCTPromiseRejectBlock)reject) {
    [_impl cancelDeviceConnectionWithDeviceId:deviceId resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(isDeviceConnected:(NSString *)deviceId
                            resolve:(RCTPromiseResolveBlock)resolve
                             reject:(RCTPromiseRejectBlock)reject) {
    [_impl isDeviceConnectedWithDeviceId:deviceId resolve:resolve reject:reject];
}

// MARK: - Discovery

RCT_EXPORT_METHOD(discoverAllServicesAndCharacteristics:(NSString *)deviceId
                                          transactionId:(NSString *)transactionId
                                                resolve:(RCTPromiseResolveBlock)resolve
                                                 reject:(RCTPromiseRejectBlock)reject) {
    [_impl discoverAllServicesAndCharacteristicsWithDeviceId:deviceId transactionId:transactionId resolve:resolve reject:reject];
}

// MARK: - Read/Write

RCT_EXPORT_METHOD(readCharacteristic:(NSString *)deviceId
                         serviceUuid:(NSString *)serviceUuid
                  characteristicUuid:(NSString *)characteristicUuid
                       transactionId:(NSString *)transactionId
                             resolve:(RCTPromiseResolveBlock)resolve
                              reject:(RCTPromiseRejectBlock)reject) {
    [_impl readCharacteristicWithDeviceId:deviceId serviceUuid:serviceUuid characteristicUuid:characteristicUuid transactionId:transactionId resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(writeCharacteristic:(NSString *)deviceId
                          serviceUuid:(NSString *)serviceUuid
                   characteristicUuid:(NSString *)characteristicUuid
                                value:(NSString *)value
                         withResponse:(BOOL)withResponse
                        transactionId:(NSString *)transactionId
                              resolve:(RCTPromiseResolveBlock)resolve
                               reject:(RCTPromiseRejectBlock)reject) {
    [_impl writeCharacteristicWithDeviceId:deviceId serviceUuid:serviceUuid characteristicUuid:characteristicUuid value:value withResponse:withResponse transactionId:transactionId resolve:resolve reject:reject];
}

// MARK: - Monitor

RCT_EXPORT_METHOD(monitorCharacteristic:(NSString *)deviceId
                            serviceUuid:(NSString *)serviceUuid
                     characteristicUuid:(NSString *)characteristicUuid
                       subscriptionType:(NSString *)subscriptionType
                          transactionId:(NSString *)transactionId) {
    [_impl monitorCharacteristicWithDeviceId:deviceId serviceUuid:serviceUuid characteristicUuid:characteristicUuid subscriptionType:subscriptionType transactionId:transactionId];
}

// MARK: - MTU

RCT_EXPORT_METHOD(getMtu:(NSString *)deviceId
                 resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    [_impl getMtuWithDeviceId:deviceId resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(requestMtu:(NSString *)deviceId
                         mtu:(double)mtu
               transactionId:(NSString *)transactionId
                     resolve:(RCTPromiseResolveBlock)resolve
                      reject:(RCTPromiseRejectBlock)reject) {
    [_impl requestMtuWithDeviceId:deviceId mtu:(NSInteger)mtu transactionId:transactionId resolve:resolve reject:reject];
}

// MARK: - PHY

RCT_EXPORT_METHOD(requestPhy:(NSString *)deviceId
                       txPhy:(double)txPhy
                       rxPhy:(double)rxPhy
                     resolve:(RCTPromiseResolveBlock)resolve
                      reject:(RCTPromiseRejectBlock)reject) {
    [_impl requestPhyWithDeviceId:deviceId txPhy:(NSInteger)txPhy rxPhy:(NSInteger)rxPhy resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(readPhy:(NSString *)deviceId
                  resolve:(RCTPromiseResolveBlock)resolve
                   reject:(RCTPromiseRejectBlock)reject) {
    [_impl readPhyWithDeviceId:deviceId resolve:resolve reject:reject];
}

// MARK: - Connection Priority

RCT_EXPORT_METHOD(requestConnectionPriority:(NSString *)deviceId
                                   priority:(double)priority
                                    resolve:(RCTPromiseResolveBlock)resolve
                                     reject:(RCTPromiseRejectBlock)reject) {
    [_impl requestConnectionPriorityWithDeviceId:deviceId priority:(NSInteger)priority resolve:resolve reject:reject];
}

// MARK: - L2CAP

RCT_EXPORT_METHOD(openL2CAPChannel:(NSString *)deviceId
                               psm:(double)psm
                           resolve:(RCTPromiseResolveBlock)resolve
                            reject:(RCTPromiseRejectBlock)reject) {
    [_impl openL2CAPChannelWithDeviceId:deviceId psm:(NSInteger)psm resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(writeL2CAPChannel:(double)channelId
                                data:(NSString *)data
                             resolve:(RCTPromiseResolveBlock)resolve
                              reject:(RCTPromiseRejectBlock)reject) {
    [_impl writeL2CAPChannelWithChannelId:(NSInteger)channelId data:data resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(closeL2CAPChannel:(double)channelId
                             resolve:(RCTPromiseResolveBlock)resolve
                              reject:(RCTPromiseRejectBlock)reject) {
    [_impl closeL2CAPChannelWithChannelId:(NSInteger)channelId resolve:resolve reject:reject];
}

// MARK: - Bonding

RCT_EXPORT_METHOD(getBondedDevices:(RCTPromiseResolveBlock)resolve
                            reject:(RCTPromiseRejectBlock)reject) {
    [_impl getBondedDevicesWithResolve:resolve reject:reject];
}

// MARK: - Authorization

RCT_EXPORT_METHOD(getAuthorizationStatus:(RCTPromiseResolveBlock)resolve
                                  reject:(RCTPromiseRejectBlock)reject) {
    [_impl getAuthorizationStatusWithResolve:resolve reject:reject];
}

// MARK: - Cancellation

RCT_EXPORT_METHOD(cancelTransaction:(NSString *)transactionId
                            resolve:(RCTPromiseResolveBlock)resolve
                             reject:(RCTPromiseRejectBlock)reject) {
    [_impl cancelTransactionWithTransactionId:transactionId resolve:resolve reject:reject];
}

#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeBlePlxSpecJSI>(params);
}
#endif

@end
