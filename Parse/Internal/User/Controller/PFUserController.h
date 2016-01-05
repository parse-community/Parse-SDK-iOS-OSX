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
#import "PFObjectControlling.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFUserController : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider> commonDataSource;
@property (nonatomic, weak, readonly) id<PFCurrentUserControllerProvider> coreDataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                          coreDataSource:(id<PFCurrentUserControllerProvider>)coreDataSource;
+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                                coreDataSource:(id<PFCurrentUserControllerProvider>)coreDataSource;

///--------------------------------------
#pragma mark - Log In
///--------------------------------------

- (BFTask *)logInCurrentUserAsyncWithSessionToken:(NSString *)sessionToken;
- (BFTask *)logInCurrentUserAsyncWithUsername:(NSString *)username
                                     password:(NSString *)password
                             revocableSession:(BOOL)revocableSession;

//TODO: (nlutsenko) Move this method into PFUserAuthenticationController after PFUser is decoupled further.
- (BFTask *)logInCurrentUserAsyncWithAuthType:(NSString *)authType
                                     authData:(NSDictionary *)authData
                             revocableSession:(BOOL)revocableSession;

///--------------------------------------
#pragma mark - Reset Password
///--------------------------------------

- (BFTask *)requestPasswordResetAsyncForEmail:(NSString *)email;

///--------------------------------------
#pragma mark - Log Out
///--------------------------------------

- (BFTask *)logOutUserAsyncWithSessionToken:(NSString *)sessionToken;

@end

NS_ASSUME_NONNULL_END
