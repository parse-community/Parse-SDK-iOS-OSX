/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTwitterUtils.h"

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTaskCompletionSource.h>

#import <Parse/Parse.h>

#import "PFTwitterAuthenticationProvider.h"
#import "PFTwitterPrivateUtilities.h"
#import "PF_Twitter.h"

@implementation PFTwitterUtils

///--------------------------------------
#pragma mark - Authentication Provider
///--------------------------------------

static PFTwitterAuthenticationProvider *authenticationProvider_;

+ (PFTwitterAuthenticationProvider *)_authenticationProvider {
    return authenticationProvider_;
}

+ (void)_setAuthenticationProvider:(PFTwitterAuthenticationProvider *)provider {
    authenticationProvider_ = provider;
}

///--------------------------------------
#pragma mark - Initialize
///--------------------------------------

+ (void)_assertTwitterInitialized {
    PFTWConsistencyAssert([self _authenticationProvider],
                          @"You must call PFTwitterUtils initializeWithConsumerKey:consumerSecret: to use PFTwitterUtils.");
}

+ (void)_assertParseInitialized {
    PFTWConsistencyAssert([Parse getApplicationId],
                          @"PFTwitterUtils should be initialized after setting up Parse.");
}

+ (void)initializeWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret {
    [self _assertParseInitialized];
    if (![self _authenticationProvider]) {
        PF_Twitter *twitter = [[PF_Twitter alloc] init];
        twitter.consumerKey = consumerKey;
        twitter.consumerSecret = consumerSecret;

        PFTwitterAuthenticationProvider *provider = [[PFTwitterAuthenticationProvider alloc] initWithTwitter:twitter];
        [PFUser registerAuthenticationDelegate:provider forAuthType:PFTwitterUserAuthenticationType];

        [self _setAuthenticationProvider:provider];
    }
}

+ (PF_Twitter *)twitter {
    return [self _authenticationProvider].twitter;
}

+ (BOOL)isLinkedWithUser:(PFUser *)user {
    return [user isLinkedWithAuthType:PFTwitterUserAuthenticationType];
}

+ (BOOL)unlinkUser:(PFUser *)user {
    return [self unlinkUser:user error:nil];
}

+ (BOOL)unlinkUser:(PFUser *)user error:(NSError **)error {
    return [[[self unlinkUserInBackground:user] pftw_waitForResult:error] boolValue];
}

+ (BFTask<NSNumber *> *)unlinkUserInBackground:(PFUser *)user {
    [self _assertTwitterInitialized];
    return [user unlinkWithAuthTypeInBackground:PFTwitterUserAuthenticationType];
}

+ (void)unlinkUserInBackground:(PFUser *)user block:(PFBooleanResultBlock)block {
    [[self unlinkUserInBackground:user] pftw_continueWithMainThreadBooleanBlock:block];
}

+ (void)unlinkUserInBackground:(PFUser *)user target:(id)target selector:(SEL)selector {
    [PFTwitterUtils unlinkUserInBackground:user block:^(BOOL succeeded, NSError *error) {
        [PFTwitterPrivateUtilities safePerformSelector:selector onTarget:target withObject:@(succeeded) object:error];
    }];
}

+ (void)linkUser:(PFUser *)user {
    // This is misnamed `*InBackground` method. Left as is for backward compatability.
    [self linkUserInBackground:user];
}

+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user {
    [self _assertTwitterInitialized];

    PFTwitterAuthenticationProvider *provider = [self _authenticationProvider];
    return [[provider authenticateAsync] continueWithSuccessBlock:^id(BFTask *task) {
        return [user linkWithAuthTypeInBackground:PFTwitterUserAuthenticationType authData:task.result];
    }];
}

+ (void)linkUser:(PFUser *)user block:(PFBooleanResultBlock)block {
    [[self linkUserInBackground:user] pftw_continueWithMainThreadBooleanBlock:block];
}

+ (void)linkUser:(PFUser *)user target:(id)target selector:(SEL)selector {
    [PFTwitterUtils linkUser:user block:^(BOOL succeeded, NSError *error) {
        [PFTwitterPrivateUtilities safePerformSelector:selector onTarget:target withObject:@(succeeded) object:error];
    }];
}

+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user
                                   twitterId:(NSString *)twitterId
                                  screenName:(NSString *)screenName
                                   authToken:(NSString *)authToken
                             authTokenSecret:(NSString *)authTokenSecret {
    [self _assertTwitterInitialized];

    PFTwitterAuthenticationProvider *provider = [self _authenticationProvider];
    NSDictionary *authData = [provider authDataWithTwitterId:twitterId
                                                  screenName:screenName
                                                   authToken:authToken
                                                      secret:authTokenSecret];
    return [user linkWithAuthTypeInBackground:PFTwitterUserAuthenticationType authData:authData];
}

+ (void)linkUser:(PFUser *)user
       twitterId:(NSString *)twitterId
      screenName:(NSString *)screenName
       authToken:(NSString *)authToken
 authTokenSecret:(NSString *)authTokenSecret
           block:(PFBooleanResultBlock)block {
    [[self linkUserInBackground:user
                      twitterId:twitterId
                     screenName:screenName
                      authToken:authToken
                authTokenSecret:authTokenSecret] pftw_continueWithMainThreadBooleanBlock:block];
}

+ (void)linkUser:(PFUser *)user
       twitterId:(NSString *)twitterId
      screenName:(NSString *)screenName
       authToken:(NSString *)authToken
 authTokenSecret:(NSString *)authTokenSecret
          target:(id)target
        selector:(SEL)selector {
    [PFTwitterUtils linkUser:user
                   twitterId:twitterId
                  screenName:screenName
                   authToken:authToken
             authTokenSecret:authTokenSecret
                       block:^(BOOL succeeded, NSError *error) {
                           [PFTwitterPrivateUtilities safePerformSelector:selector
                                                                 onTarget:target
                                                               withObject:@(succeeded)
                                                                   object:error];
                       }];
}

+ (BFTask<PFUser *> *)logInInBackground {
    [self _assertTwitterInitialized];

    PFTwitterAuthenticationProvider *provider = [self _authenticationProvider];
    return [[provider authenticateAsync] continueWithSuccessBlock:^id(BFTask *task) {
        return [PFUser logInWithAuthTypeInBackground:PFTwitterUserAuthenticationType authData:task.result];
    }];
}

+ (void)logInWithBlock:(PFUserResultBlock)block {
    [[self logInInBackground] pftw_continueWithMainThreadUserBlock:block];
}

+ (void)logInWithTarget:(id)target selector:(SEL)selector {
    [self logInWithBlock:^(PFUser *user, NSError *error) {
        [PFTwitterPrivateUtilities safePerformSelector:selector onTarget:target withObject:user object:error];
    }];
}

+ (BFTask<PFUser *> *)logInWithTwitterIdInBackground:(NSString *)twitterId
                                          screenName:(NSString *)screenName
                                           authToken:(NSString *)authToken
                                     authTokenSecret:(NSString *)authTokenSecret {
    [self _assertTwitterInitialized];

    PFTwitterAuthenticationProvider *provider = [self _authenticationProvider];
    NSDictionary *authData = [provider authDataWithTwitterId:twitterId
                                                  screenName:screenName
                                                   authToken:authToken
                                                      secret:authTokenSecret];
    return [PFUser logInWithAuthTypeInBackground:PFTwitterUserAuthenticationType authData:authData];
}

+ (void)logInWithTwitterId:(NSString *)twitterId
                screenName:(NSString *)screenName
                 authToken:(NSString *)authToken
           authTokenSecret:(NSString *)authTokenSecret
                     block:(PFUserResultBlock)block {
    [[self logInWithTwitterIdInBackground:twitterId
                               screenName:screenName
                                authToken:authToken
                          authTokenSecret:authTokenSecret] pftw_continueWithMainThreadUserBlock:block];
}

+ (void)logInWithTwitterId:(NSString *)twitterId
                screenName:(NSString *)screenName
                 authToken:(NSString *)authToken
           authTokenSecret:(NSString *)authTokenSecret
                    target:(id)target
                  selector:(SEL)selector {
    [self logInWithTwitterId:twitterId
                  screenName:screenName
                   authToken:authToken
             authTokenSecret:authTokenSecret
                       block:^(PFUser *user, NSError *error) {
                           [PFTwitterPrivateUtilities safePerformSelector:selector
                                                                 onTarget:target
                                                               withObject:user
                                                                   object:error];
                       }];
}

@end
