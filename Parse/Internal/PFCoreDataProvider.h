/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#ifndef Parse_PFCoreDataProvider_h
#define Parse_PFCoreDataProvider_h

NS_ASSUME_NONNULL_BEGIN

///--------------------------------------
/// @name Object
///--------------------------------------

@class PFObjectController;

@protocol PFObjectControllerProvider <NSObject>

@property (nonatomic, strong) PFObjectController *objectController;

@end

@class PFObjectBatchController;

@protocol PFObjectBatchController <NSObject>

@property (nonatomic, strong, readonly) PFObjectBatchController *objectBatchController;

@end

@class PFObjectFilePersistenceController;

@protocol PFObjectFilePersistenceControllerProvider <NSObject>

@property (nonatomic, strong, readonly) PFObjectFilePersistenceController *objectFilePersistenceController;

@end

@class PFObjectLocalIdStore;

@protocol PFObjectLocalIdStoreProvider <NSObject>

@property (nonatomic, strong) PFObjectLocalIdStore *objectLocalIdStore;

@end

///--------------------------------------
/// @name User
///--------------------------------------

@class PFUserAuthenticationController;

@protocol PFUserAuthenticationControllerProvider <NSObject>

@property (nonatomic, strong) PFUserAuthenticationController *userAuthenticationController;

@end

@class PFCurrentUserController;

@protocol PFCurrentUserControllerProvider <NSObject>

@property (nonatomic, strong) PFCurrentUserController *currentUserController;

@end

@class PFUserController;

@protocol PFUserControllerProvider <NSObject>

@property (nonatomic, strong) PFUserController *userController;

@end

///--------------------------------------
/// @name Installation
///--------------------------------------

@class PFCurrentInstallationController;

@protocol PFCurrentInstallationControllerProvider <NSObject>

@property (nonatomic, strong) PFCurrentInstallationController *currentInstallationController;

@end

@class PFInstallationController;

@protocol PFInstallationControllerProvider <NSObject>

@property (nonatomic, strong) PFInstallationController *installationController;

@end

#endif

NS_ASSUME_NONNULL_END
