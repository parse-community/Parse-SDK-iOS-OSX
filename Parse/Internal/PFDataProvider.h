/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#ifndef Parse_PFDataProviders_h
#define Parse_PFDataProviders_h

NS_ASSUME_NONNULL_BEGIN

@protocol PFCommandRunning;

@protocol PFCommandRunnerProvider <NSObject>

@property (nonatomic, strong, readonly) id<PFCommandRunning> commandRunner;

@end

@class PFFileManager;

@protocol PFFileManagerProvider <NSObject>

@property (nonatomic, strong, readonly) PFFileManager *fileManager;

@end

@class PFOfflineStore;

@protocol PFOfflineStoreProvider <NSObject>

@property (nullable, nonatomic, strong) PFOfflineStore *offlineStore;
@property (nonatomic, assign, readonly, getter=isOfflineStoreLoaded) BOOL offlineStoreLoaded;

@end

@class PFEventuallyQueue;

@protocol PFEventuallyQueueProvider <NSObject>

@property (nonatomic, strong, readonly) PFEventuallyQueue *eventuallyQueue;

@end

@class PFKeychainStore;

@protocol PFKeychainStoreProvider <NSObject>

@property (nonatomic, strong, readonly) PFKeychainStore *keychainStore;

@end

@class PFKeyValueCache;

@protocol PFKeyValueCacheProvider <NSObject>

@property (nonatomic, strong, readonly) PFKeyValueCache *keyValueCache;

@end

@class PFLocationManager;

@protocol PFLocationManagerProvider <NSObject>

@property (nonatomic, strong, readonly) PFLocationManager *locationManager;

@end

@class PFPinningObjectStore;

@protocol PFPinningObjectStoreProvider <NSObject>

@property (nonatomic, strong) PFPinningObjectStore *pinningObjectStore;

@end

@class PFInstallationIdentifierStore;

@protocol PFInstallationIdentifierStoreProvider <NSObject>

@property (nonatomic, strong, readonly) PFInstallationIdentifierStore *installationIdentifierStore;

@end

#endif

NS_ASSUME_NONNULL_END
