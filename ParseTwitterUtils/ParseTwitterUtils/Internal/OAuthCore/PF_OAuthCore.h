/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PFOAuthConfiguration : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, copy) NSString *method;
@property (nullable, nonatomic, strong) NSData *body;

@property (nonatomic, copy) NSString *consumerKey;
@property (nonatomic, copy) NSString *consumerSecret;

@property (nullable, nonatomic, copy) NSString *token;
@property (nullable, nonatomic, copy) NSString *tokenSecret;

@property (nullable, nonatomic, copy) NSDictionary *additionalParameters;

@property (nonatomic, copy) NSString *nonce;
@property (nonatomic, strong) NSDate *timestampDate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)configurationForURL:(NSURL *)url
                             method:(NSString *)method
                               body:(nullable NSData *)body
               additionalParameters:(nullable NSDictionary *)additionalParams
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                              token:(nullable NSString *)token
                        tokenSecret:(nullable NSString *)tokenSecret;

@end

@interface PFOAuth : NSObject

+ (NSString *)authorizationHeaderFromConfiguration:(PFOAuthConfiguration *)configuration;

@end

@interface NSURL (PF_OAuthAdditions)

+ (NSDictionary *)PF_ab_parseURLQueryString:(NSString *)query;

@end

@interface NSString (PF_OAuthAdditions)

- (NSString *)PF_ab_RFC3986EncodedString;

@end

NS_ASSUME_NONNULL_END
