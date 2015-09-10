/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFCoreDataProvider.h"
#import "PFDataProvider.h"
#import "PFMacros.h"
#import "PFObjectControlling.h"

@class PFUser;
@class PFCommandResult;

NS_ASSUME_NONNULL_BEGIN

@interface PFUserController : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider> commonDataSource;
@property (nonatomic, weak, readonly) id<PFCurrentUserControllerProvider> coreDataSource;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                          coreDataSource:(id<PFCurrentUserControllerProvider>)coreDataSource;
+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                                coreDataSource:(id<PFCurrentUserControllerProvider>)coreDataSource;

///--------------------------------------
/// @name Log In
///--------------------------------------

- (BFTask PF_GENERIC(PFUser *)*)logInCurrentUserAsyncWithSessionToken:(NSString *)sessionToken;
- (BFTask PF_GENERIC(PFUser *)*)logInCurrentUserAsyncWithUsername:(NSString *)username
                                                         password:(NSString *)password
                                                 revocableSession:(BOOL)revocableSession;

//TODO: (nlutsenko) Move this method into PFUserAuthenticationController after PFUser is decoupled further.
- (BFTask PF_GENERIC(PFUser *)*)logInCurrentUserAsyncWithAuthType:(NSString *)authType
                                                         authData:(NSDictionary *)authData
                                                 revocableSession:(BOOL)revocableSession;

///--------------------------------------
/// @name Reset Password
///--------------------------------------

- (BFTask PF_GENERIC(PFVoid) *)requestPasswordResetAsyncForEmail:(NSString *)email;

///--------------------------------------
/// @name Log Out
///--------------------------------------

- (BFTask PF_GENERIC(PFVoid) *)logOutUserAsyncWithSessionToken:(NSString *)sessionToken;

@end

NS_ASSUME_NONNULL_END
