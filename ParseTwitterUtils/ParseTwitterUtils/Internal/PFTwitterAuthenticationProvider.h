/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFUserAuthenticationDelegate.h>

@class BFTask<__covariant BFGenericType>;
@class PF_Twitter;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PFTwitterUserAuthenticationType;

@interface PFTwitterAuthenticationProvider : NSObject <PFUserAuthenticationDelegate>

@property (nonatomic, strong, readonly) PF_Twitter *twitter;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTwitter:(PF_Twitter *)twitter NS_DESIGNATED_INITIALIZER;
+ (instancetype)providerWithTwitter:(PF_Twitter *)twitter;

- (BFTask *)authenticateAsync;

- (NSDictionary *)authDataWithTwitterId:(NSString *)twitterId
                             screenName:(NSString *)screenName
                              authToken:(NSString *)authToken
                                 secret:(NSString *)authTokenSecret;

@end

NS_ASSUME_NONNULL_END
