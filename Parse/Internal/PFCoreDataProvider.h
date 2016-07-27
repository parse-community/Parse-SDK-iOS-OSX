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
#pragma mark - Default ACL
///--------------------------------------

@class PFDefaultACLController;

@protocol PFDefaultACLControllerProvider <NSObject>

@property (nonatomic, strong, readonly) PFDefaultACLController *defaultACLController;

@end

///--------------------------------------
#pragma mark - Object
///--------------------------------------

@class PFObjectController;

@protocol PFObjectControllerProvider <NSObject>

@property (null_resettable, nonatomic, strong) PFObjectController *objectController;

@end

@class PFObjectSubclassingController;

@protocol PFObjectSubclassingControllerProvider <NSObject>

@property (null_resettable, nonatomic, strong) PFObjectSubclassingController *objectSubclassingController;

@end

@class PFObjectBatchController;

@protocol PFObjectBatchController <NSObject>

@property (nonatomic, strong, readonly) PFObjectBatchController *objectBatchController;

@end

@class PFObjectFilePersistenceController;

@protocol PFObjectFilePersistenceControllerProvider <NSObject>

@property (null_resettable, nonatomic, strong, readonly) PFObjectFilePersistenceController *objectFilePersistenceController;

@end

@class PFObjectLocalIdStore;

@protocol PFObjectLocalIdStoreProvider <NSObject>

@property (null_resettable, nonatomic, strong) PFObjectLocalIdStore *objectLocalIdStore;

@end

///--------------------------------------
#pragma mark - User
///--------------------------------------

@class PFUserAuthenticationController;

@protocol PFUserAuthenticationControllerProvider <NSObject>

@property (null_resettable, nonatomic, strong) PFUserAuthenticationController *userAuthenticationController;

@end

@class PFCurrentUserController;

@protocol PFCurrentUserControllerProvider <NSObject>

@property (null_resettable, nonatomic, strong) PFCurrentUserController *currentUserController;

@end

@class PFUserController;

@protocol PFUserControllerProvider <NSObject>

@property (null_resettable, nonatomic, strong) PFUserController *userController;

@end

///--------------------------------------
#pragma mark - Installation
///--------------------------------------

@class PFCurrentInstallationController;

@protocol PFCurrentInstallationControllerProvider <NSObject>

@property (null_resettable, nonatomic, strong) PFCurrentInstallationController *currentInstallationController;

@end

@class PFInstallationController;

@protocol PFInstallationControllerProvider <NSObject>

@property (null_resettable, nonatomic, strong) PFInstallationController *installationController;

@end

#endif

NS_ASSUME_NONNULL_END
