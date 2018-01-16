/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTwitterAuthenticationProvider.h"

#import <Bolts/BFTask.h>

#import <Parse/PFConstants.h>

#import "PFTwitterPrivateUtilities.h"
#import "PF_Twitter.h"

NSString *const PFTwitterUserAuthenticationType = @"twitter";

static NSString *const _PFTwitterAuthDataIdKey = @"id";
static NSString *const _PFTwitterAuthDataScreenNameKey = @"screen_name";
static NSString *const _PFTwitterAuthDataAuthTokenKey = @"auth_token";
static NSString *const _PFTwitterAuthDataAuthTokenSecretKey = @"auth_token_secret";
static NSString *const _PFTwitterAuthDataConsumerKeyKey = @"consumer_key";
static NSString *const _PFTwitterAuthDataConsumerSecretKey = @"consumer_secret";

@implementation PFTwitterAuthenticationProvider

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFTWConsistencyAssert(NO, @"%@ is not a designated initializer for instances of %@.",
                          NSStringFromSelector(_cmd), NSStringFromClass([self class]));
    return nil;
}

- (instancetype)initWithTwitter:(PF_Twitter *)twitter {
    self = [super init];
    if (!self) return nil;

    _twitter = twitter;

    return self;
}

+ (instancetype)providerWithTwitter:(PF_Twitter *)twitter {
    return [[self alloc] initWithTwitter:twitter];
}

///--------------------------------------
#pragma mark - Auth Data
///--------------------------------------

- (NSDictionary *)authDataWithTwitterId:(NSString *)twitterId
                             screenName:(NSString *)screenName
                              authToken:(NSString *)authToken
                                 secret:(NSString *)authTokenSecret {
    NSDictionary *authData = @{_PFTwitterAuthDataIdKey : twitterId,
                               _PFTwitterAuthDataScreenNameKey : screenName,
                               _PFTwitterAuthDataAuthTokenKey : authToken,
                               _PFTwitterAuthDataAuthTokenSecretKey : authTokenSecret,
                               _PFTwitterAuthDataConsumerKeyKey : self.twitter.consumerKey,
                               _PFTwitterAuthDataConsumerSecretKey : self.twitter.consumerSecret};
    return authData;
}

///--------------------------------------
#pragma mark - Authentication
///--------------------------------------

- (BFTask *)authenticateAsync {
    return [[self.twitter authorizeInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        NSDictionary *authData = [self authDataWithTwitterId:self.twitter.userId
                                                  screenName:self.twitter.screenName
                                                   authToken:self.twitter.authToken
                                                      secret:self.twitter.authTokenSecret];
        return [BFTask taskWithResult:authData];
    }];
}

///--------------------------------------
#pragma mark - PFUserAuthenticationDelegate
///--------------------------------------

- (BOOL)restoreAuthenticationWithAuthData:(NSDictionary<NSString *, NSString *> *)authData {
    // If authData is nil, this is an unlink operation, which should succeed.
    if (!authData) {
        self.twitter.userId = nil;
        self.twitter.authToken = nil;
        self.twitter.authTokenSecret = nil;
        self.twitter.screenName = nil;
        return YES;
    }

    // Check that the authData contains the required fields, and if so, synchronize.
    NSString *userId = authData[_PFTwitterAuthDataIdKey];
    NSString *screenName = authData[_PFTwitterAuthDataScreenNameKey];
    NSString *authToken = authData[_PFTwitterAuthDataAuthTokenKey];
    NSString *authTokenSecret = authData[_PFTwitterAuthDataAuthTokenSecretKey];
    if (userId && screenName && authToken && authTokenSecret) {
        self.twitter.userId = userId;
        self.twitter.screenName = screenName;
        self.twitter.authToken = authToken;
        self.twitter.authTokenSecret = authTokenSecret;
        return YES;
    }
    return NO;
}

@end
