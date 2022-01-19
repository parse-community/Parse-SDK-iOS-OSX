/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTUserCommand.h"

#import "PFAssert.h"
#import "PFHTTPRequest.h"

static NSString *const PFRESTUserCommandRevocableSessionHeader = @"X-Parse-Revocable-Session";
static NSString *const PFRESTUserCommandRevocableSessionHeaderEnabledValue = @"1";

@interface PFRESTUserCommand ()

@property (nonatomic, assign, readwrite) BOOL revocableSessionEnabled;

@end

@implementation PFRESTUserCommand

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)_commandWithHTTPPath:(NSString *)path
                          httpMethod:(NSString *)httpMethod
                          parameters:(NSDictionary *)parameters
                        sessionToken:(NSString *)sessionToken
                    revocableSession:(BOOL)revocableSessionEnabled
                               error:(NSError **) error {
    PFRESTUserCommand *command = [self commandWithHTTPPath:path
                                                httpMethod:httpMethod
                                                parameters:parameters
                                              sessionToken:sessionToken
                                                     error:error];
    PFPreconditionBailOnError(command, error, nil);
    if (revocableSessionEnabled) {
        command.additionalRequestHeaders = @{ PFRESTUserCommandRevocableSessionHeader :
                                                  PFRESTUserCommandRevocableSessionHeaderEnabledValue};
    }
    command.revocableSessionEnabled = revocableSessionEnabled;
    return command;
}

///--------------------------------------
#pragma mark - Log In
///--------------------------------------

+ (instancetype)logInUserCommandWithUsername:(NSString *)username
                                    password:(NSString *)password
                            revocableSession:(BOOL)revocableSessionEnabled
                                       error:(NSError **) error {
    NSDictionary *parameters = @{ @"username" : username,
                                  @"password" : password };
    return [self _commandWithHTTPPath:@"login"
                           httpMethod:PFHTTPRequestMethodGET
                           parameters:parameters
                         sessionToken:nil
                     revocableSession:revocableSessionEnabled
                                error:error];
}

+ (instancetype)serviceLoginUserCommandWithAuthenticationType:(NSString *)authenticationType
                                           authenticationData:(NSDictionary *)authenticationData
                                             revocableSession:(BOOL)revocableSessionEnabled
                                                        error:(NSError **)error {
    NSDictionary *parameters = @{ @"authData" : @{ authenticationType : authenticationData } };
    return [self serviceLoginUserCommandWithParameters:parameters
                                      revocableSession:revocableSessionEnabled
                                          sessionToken:nil
                                                 error:error];
}

+ (instancetype)serviceLoginUserCommandWithParameters:(NSDictionary *)parameters
                                     revocableSession:(BOOL)revocableSessionEnabled
                                         sessionToken:(NSString *)sessionToken
                                                error:(NSError **)error {
    return [self _commandWithHTTPPath:@"users"
                           httpMethod:PFHTTPRequestMethodPOST
                           parameters:parameters
                         sessionToken:sessionToken
                     revocableSession:revocableSessionEnabled
                                error:error];
}

///--------------------------------------
#pragma mark - Sign Up
///--------------------------------------

+ (instancetype)signUpUserCommandWithParameters:(NSDictionary *)parameters
                               revocableSession:(BOOL)revocableSessionEnabled
                                   sessionToken:(NSString *)sessionToken
                                          error:(NSError **)error {
    return [self _commandWithHTTPPath:@"users"
                           httpMethod:PFHTTPRequestMethodPOST
                           parameters:parameters
                         sessionToken:sessionToken
                     revocableSession:revocableSessionEnabled
                                error:error];
}

///--------------------------------------
#pragma mark - Current User
///--------------------------------------

+ (instancetype)getCurrentUserCommandWithSessionToken:(NSString *)sessionToken error:(NSError **)error {
    return [self commandWithHTTPPath:@"users/me"
                          httpMethod:PFHTTPRequestMethodGET
                          parameters:nil
                        sessionToken:sessionToken
                               error:error];
}

+ (instancetype)upgradeToRevocableSessionCommandWithSessionToken:(NSString *)sessionToken error:(NSError **)error {
    return [self commandWithHTTPPath:@"upgradeToRevocableSession"
                          httpMethod:PFHTTPRequestMethodPOST
                          parameters:nil
                        sessionToken:sessionToken
                               error:error];
}

+ (instancetype)logOutUserCommandWithSessionToken:(NSString *)sessionToken error:(NSError **)error {
    return [self commandWithHTTPPath:@"logout"
                          httpMethod:PFHTTPRequestMethodPOST
                          parameters:nil
                        sessionToken:sessionToken
                               error:error];
}

///--------------------------------------
#pragma mark - Additional User Commands
///--------------------------------------

+ (instancetype)resetPasswordCommandForUserWithEmail:(NSString *)email error:(NSError **)error {
    return [self commandWithHTTPPath:@"requestPasswordReset"
                          httpMethod:PFHTTPRequestMethodPOST
                          parameters:@{ @"email" : email }
                        sessionToken:nil
                               error:error];
}

@end
