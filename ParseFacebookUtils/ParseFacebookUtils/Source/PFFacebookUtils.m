/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFacebookUtils.h"

#if __has_include(<Bolts/BFExecutor.h>)
#import <Bolts/BFExecutor.h>
#else
#import "BFExecutor.h"
#endif

#if __has_include(<Parse/Parse.h>)
#import <Parse/Parse.h>
#else
#import "Parse.h"
#endif

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "PFFacebookAuthenticationProvider.h"

@implementation PFFacebookUtils

+ (UIViewController *)applicationTopViewController {
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
    }
    return viewController;
}

///--------------------------------------
#pragma mark - User Authentication Data
///--------------------------------------

+ (NSDictionary *)userAuthenticationDataWithFacebookUserId:(NSString *)userId
                                               accessToken:(NSString *)accessToken
                                            expirationDate:(NSDate *)expirationDate {
    return @{ @"id" : userId,
              @"access_token" : accessToken,
              @"expiration_date" : [[NSDateFormatter pffb_preciseDateFormatter] stringFromDate:expirationDate] };
}

+ (nullable NSDictionary *)userAuthenticationDataFromAccessToken:(FBSDKAccessToken *)token {
    if (!token.userID || !token.tokenString || !token.expirationDate) {
        return nil;
    }

    return [self userAuthenticationDataWithFacebookUserId:token.userID
                                              accessToken:token.tokenString
                                           expirationDate:token.expirationDate];
}

+ (nullable FBSDKAccessToken *)facebookAccessTokenFromUserAuthenticationData:(nullable NSDictionary<NSString *, NSString *> *)authData {
    NSString *accessToken = authData[@"access_token"];
    NSString *expirationDateString = authData[@"expiration_date"];
    if (!accessToken || !expirationDateString) {
        return nil;
    }

NSDate *expirationDate = [[NSDateFormatter pffb_preciseDateFormatter] dateFromString:expirationDateString];
    FBSDKAccessToken *token = [[FBSDKAccessToken alloc] initWithTokenString: accessToken permissions:@[] declinedPermissions:@[] expiredPermissions:@[] appID: FBSDKSettings.sharedSettings.appID userID: authData[@"id"] expirationDate: expirationDate refreshDate: nil dataAccessExpirationDate: nil];
    return token;
}

///--------------------------------------
#pragma mark - Authentication Provider
///--------------------------------------

+ (void)_assertFacebookInitialized {
    if (!authenticationProvider_) {
        [NSException raise:NSInternalInconsistencyException format:@"You must initialize PFFacebookUtils with a call to +initializeFacebookWithApplicationLaunchOptions"];
    }
}

+ (PFFacebookAuthenticationProvider *)_authenticationProvider {
    return authenticationProvider_;
}

+ (void)_setAuthenticationProvider:(PFFacebookAuthenticationProvider *)provider {
    authenticationProvider_ = provider;
}

///--------------------------------------
#pragma mark - Logging In
///--------------------------------------

+ (BFTask<PFUser *> *)logInInBackgroundWithReadPermissions:(nullable NSArray<NSString *> *)permissions {
    return [self _logInAsyncWithReadPermissions:permissions publishPermissions:nil];
}

+ (void)logInInBackgroundWithReadPermissions:(nullable NSArray<NSString *> *)permissions
                                       block:(nullable PFUserResultBlock)block {
    [[self logInInBackgroundWithReadPermissions:permissions] pffb_continueWithMainThreadUserBlock:block];
}

+ (BFTask *)logInInBackgroundWithPublishPermissions:(nullable NSArray<NSString *> *)permissions {
    return [self _logInAsyncWithReadPermissions:nil publishPermissions:permissions];
}

+ (void)logInInBackgroundWithPublishPermissions:(nullable NSArray<NSString *> *)permissions
                                          block:(nullable PFUserResultBlock)block {
    [[self logInInBackgroundWithPublishPermissions:permissions] pffb_continueWithMainThreadUserBlock:block];
}

+ (BFTask<PFUser *> *)_logInAsyncWithReadPermissions:(NSArray<NSString *> *)readPermissions
                                  publishPermissions:(NSArray<NSString *> *)publishPermissions {
    [self _assertFacebookInitialized];

    PFFacebookAuthenticationProvider *provider = [self _authenticationProvider];
    return [[provider authenticateAsyncWithReadPermissions:readPermissions
                                        publishPermissions:publishPermissions] continueWithSuccessBlock:^id(BFTask *task) {
        return [PFUser logInWithAuthTypeInBackground:PFFacebookUserAuthenticationType authData:task.result];
    }];
}

+ (BFTask<PFUser *> *)logInInBackgroundWithAccessToken:(FBSDKAccessToken *)accessToken {
    [self _assertFacebookInitialized];

    NSDictionary *authData = [PFFacebookUtils userAuthenticationDataFromAccessToken:accessToken];
    if (!authData) {
        return [BFTask taskWithError:[NSError pffb_invalidFacebookSessionError]];
    }
    return [[PFUser logInWithAuthTypeInBackground:PFFacebookUserAuthenticationType
                                         authData:authData] continueWithSuccessBlock:^id(BFTask *task) {
        [FBSDKAccessToken setCurrentAccessToken:accessToken];
        return task; // Return the same result.
    }];
}

+ (void)logInInBackgroundWithAccessToken:(FBSDKAccessToken *)accessToken
                                   block:(nullable PFUserResultBlock)block {
    [[self logInInBackgroundWithAccessToken:accessToken] pffb_continueWithMainThreadUserBlock:block];
}

///--------------------------------------
#pragma mark - Linking Users
///--------------------------------------

+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user
                         withReadPermissions:(nullable NSArray<NSString *> *)permissions {
    return [self _linkUserAsync:user withReadPermissions:permissions publishPermissions:nil];
}

+ (void)linkUserInBackground:(PFUser *)user
         withReadPermissions:(nullable NSArray<NSString *> *)permissions
                       block:(nullable PFBooleanResultBlock)block {
    [[self linkUserInBackground:user withReadPermissions:permissions] pffb_continueWithMainThreadBooleanBlock:block];
}

+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user
                      withPublishPermissions:(NSArray<NSString *> *)permissions {
    return [self _linkUserAsync:user withReadPermissions:nil publishPermissions:permissions];
}

+ (void)linkUserInBackground:(PFUser *)user
      withPublishPermissions:(NSArray<NSString *> *)permissions
                       block:(nullable PFBooleanResultBlock)block {
    [[self linkUserInBackground:user withPublishPermissions:permissions] pffb_continueWithMainThreadBooleanBlock:block];
}

+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user withAccessToken:(FBSDKAccessToken *)accessToken {
    [self _assertFacebookInitialized];

    NSDictionary *authData = [PFFacebookUtils userAuthenticationDataFromAccessToken:accessToken];
    if (!authData) {
        return [BFTask taskWithError:[NSError pffb_invalidFacebookSessionError]];
    }
    return [user linkWithAuthTypeInBackground:PFFacebookUserAuthenticationType authData:authData];
}

+ (void)linkUserInBackground:(PFUser *)user
             withAccessToken:(FBSDKAccessToken *)accessToken
                       block:(nullable PFBooleanResultBlock)block {
    [[self linkUserInBackground:user withAccessToken:accessToken] pffb_continueWithMainThreadBooleanBlock:block];
}

+ (BFTask *)_linkUserAsync:(PFUser *)user
       withReadPermissions:(nullable NSArray<NSString *> *)readPermissions
        publishPermissions:(nullable NSArray<NSString *> *)publishPermissions {
    [self _assertFacebookInitialized];

    PFFacebookAuthenticationProvider *authenticationProvider = [self _authenticationProvider];
    return [[authenticationProvider authenticateAsyncWithReadPermissions:readPermissions
                                                      publishPermissions:publishPermissions] continueWithSuccessBlock:^id(BFTask *task) {
        return [user linkWithAuthTypeInBackground:PFFacebookUserAuthenticationType authData:task.result];
    }];
}

///--------------------------------------
#pragma mark - Unlinking
///--------------------------------------

+ (BFTask<NSNumber *> *)unlinkUserInBackground:(PFUser *)user {
    [self _assertFacebookInitialized];
    return [user unlinkWithAuthTypeInBackground:PFFacebookUserAuthenticationType];
}

+ (void)unlinkUserInBackground:(PFUser *)user block:(nullable PFBooleanResultBlock)block {
    [[self unlinkUserInBackground:user] pffb_continueWithMainThreadBooleanBlock:block];
}

///--------------------------------------
#pragma mark - Getting Linked State
///--------------------------------------

+ (BOOL)isLinkedWithUser:(PFUser *)user {
    return [user isLinkedWithAuthType:PFFacebookUserAuthenticationType];
}

@end

@implementation BFTask (ParseFacebookUtils)

- (instancetype)pffb_continueWithMainThreadUserBlock:(PFUserResultBlock)block {
    return [self pffb_continueWithMainThreadBlock:^id(BFTask *task) {
        if (block) {
            block(task.result, task.error);
        }
        return nil;
    }];
}

- (instancetype)pffb_continueWithMainThreadBooleanBlock:(PFBooleanResultBlock)block {
    return [self pffb_continueWithMainThreadBlock:^id(BFTask *task) {
        if (block) {
            block([task.result boolValue], task.error);
        }
        return nil;
    }];
}

- (instancetype)pffb_continueWithMainThreadBlock:(BFContinuationBlock)block {
    return [self continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:block];
}

@end

@implementation NSError (ParseFacebookUtils)

+ (instancetype)pffb_invalidFacebookSessionError {
    return [NSError errorWithDomain:PFParseErrorDomain
                               code:kPFErrorFacebookInvalidSession
                           userInfo:@{ NSLocalizedDescriptionKey : @"Supplied access token is missing required data." }];
}

@end

@implementation NSDateFormatter (ParseFacebookUtils)

+ (instancetype)pffb_preciseDateFormatter {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    return formatter;
}

@end
