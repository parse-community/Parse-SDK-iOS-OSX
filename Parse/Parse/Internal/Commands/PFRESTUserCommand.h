/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFRESTUserCommand : PFRESTCommand

@property (nonatomic, assign, readonly) BOOL revocableSessionEnabled;

///--------------------------------------
#pragma mark - Log In
///--------------------------------------

+ (instancetype)logInUserCommandWithUsername:(NSString *)username
                                    password:(NSString *)password
                            revocableSession:(BOOL)revocableSessionEnabled;
+ (instancetype)serviceLoginUserCommandWithAuthenticationType:(NSString *)authenticationType
                                           authenticationData:(NSDictionary *)authenticationData
                                             revocableSession:(BOOL)revocableSessionEnabled;
+ (instancetype)serviceLoginUserCommandWithParameters:(NSDictionary *)parameters
                                     revocableSession:(BOOL)revocableSessionEnabled
                                         sessionToken:(nullable NSString *)sessionToken;

///--------------------------------------
#pragma mark - Sign Up
///--------------------------------------

+ (instancetype)signUpUserCommandWithParameters:(NSDictionary *)parameters
                               revocableSession:(BOOL)revocableSessionEnabled
                                   sessionToken:(nullable NSString *)sessionToken;

///--------------------------------------
#pragma mark - Current User
///--------------------------------------

+ (instancetype)getCurrentUserCommandWithSessionToken:(NSString *)sessionToken;
+ (instancetype)upgradeToRevocableSessionCommandWithSessionToken:(NSString *)sessionToken;
+ (instancetype)logOutUserCommandWithSessionToken:(NSString *)sessionToken;

///--------------------------------------
#pragma mark - Password Rest
///--------------------------------------

+ (instancetype)resetPasswordCommandForUserWithEmail:(NSString *)email;

@end

NS_ASSUME_NONNULL_END
