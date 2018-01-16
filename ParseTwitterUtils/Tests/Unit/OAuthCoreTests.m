/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import ObjectiveC.runtime;

#import "PFTwitterTestCase.h"
#import "PF_OAuthCore.h"

@implementation NSURLComponents (OAuthCoreTests)

+ (Class)class {
    return [super class];
}

+ (Class)_nilClass {
    return nil;
}

@end

@interface OAuthCoreTests : PFTwitterTestCase

@property (nonatomic, strong) NSDate *authDate;
@property (nonatomic, copy) NSString *authNonce;

@end

@implementation OAuthCoreTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (NSURL *)sampleURL {
    return [NSURL URLWithString:@"https://localhost/foo/bar"];
}

- (NSData *)sampleData {
    return [@"sampe=@!value" dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)assertAuthHeader:(NSString *)authHeader matchesExpectedSignature:(NSString *)signature {
    XCTAssertTrue([authHeader hasPrefix:@"OAuth "]);

    PFAssertStringContains(authHeader,
                           ([NSString stringWithFormat:@"oauth_timestamp=\"%llu\"",
                             (unsigned long long)[_authDate timeIntervalSince1970]]));

    PFAssertStringContains(authHeader, ([NSString stringWithFormat:@"oauth_nonce=\"%@\"", _authNonce]));
    PFAssertStringContains(authHeader, @"oauth_version=\"1.0\"");
    PFAssertStringContains(authHeader, @"oauth_consumer_key=\"consumer_key\"");
    PFAssertStringContains(authHeader, @"oauth_signature_method=\"HMAC-SHA1\"");
    PFAssertStringContains(authHeader, ([NSString stringWithFormat:@"oauth_signature=\"%@\"", signature]));
}

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    _authDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0.0];
    _authNonce = @"UUID-STRING";
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testBasic {
    PFOAuthConfiguration *configuration = [PFOAuthConfiguration configurationForURL:[self sampleURL]
                                                                             method:@"POST"
                                                                               body:[self sampleData]
                                                               additionalParameters:nil
                                                                        consumerKey:@"consumer_key"
                                                                     consumerSecret:@"consumer_secret"
                                                                              token:nil
                                                                        tokenSecret:nil];
    configuration.nonce = self.authNonce;
    configuration.timestampDate = self.authDate;
    NSString *authHeader = [PFOAuth authorizationHeaderFromConfiguration:configuration];

    [self assertAuthHeader:authHeader matchesExpectedSignature:@"3Nvy4O1Ok3qkeKcjvtv4wtyjc%2FY%3D"];
}

- (void)testNoBody {
    PFOAuthConfiguration *configuration = [PFOAuthConfiguration configurationForURL:[self sampleURL]
                                                                             method:@"POST"
                                                                               body:nil
                                                               additionalParameters:nil
                                                                        consumerKey:@"consumer_key"
                                                                     consumerSecret:@"consumer_secret"
                                                                              token:nil
                                                                        tokenSecret:nil];
    configuration.nonce = self.authNonce;
    configuration.timestampDate = self.authDate;
    NSString *authHeader = [PFOAuth authorizationHeaderFromConfiguration:configuration];

    [self assertAuthHeader:authHeader matchesExpectedSignature:@"rXtmqPIUmMbl4e1%2Bz4JgJUuVIz0%3D"];
}

- (void)testWithToken {
    PFOAuthConfiguration *configuration = [PFOAuthConfiguration configurationForURL:[self sampleURL]
                                                                             method:@"POST"
                                                                               body:nil
                                                               additionalParameters:nil
                                                                        consumerKey:@"consumer_key"
                                                                     consumerSecret:@"consumer_secret"
                                                                              token:@"token"
                                                                        tokenSecret:nil];
    configuration.nonce = self.authNonce;
    configuration.timestampDate = self.authDate;
    NSString *authHeader = [PFOAuth authorizationHeaderFromConfiguration:configuration];

    XCTAssertTrue([authHeader rangeOfString:@"oauth_token=\"token\""].location != NSNotFound);
    [self assertAuthHeader:authHeader matchesExpectedSignature:@"iRsvN%2FUCXyzhf3o9tIL0DAX%2F4HY%3D"];
}

- (void)testNoNSURLComponents {
    // Disable NSURLComponents for a single test.
    Method originalMethod = class_getClassMethod([NSURLComponents class], @selector(class));
    Method replacementMethod = class_getClassMethod([NSURLComponents class], @selector(_nilClass));
    method_exchangeImplementations(originalMethod, replacementMethod);

    @try {
        PFOAuthConfiguration *configuration = [PFOAuthConfiguration configurationForURL:[self sampleURL]
                                                                                 method:@"POST"
                                                                                   body:[self sampleData]
                                                                   additionalParameters:nil
                                                                            consumerKey:@"consumer_key"
                                                                         consumerSecret:@"consumer_secret"
                                                                                  token:nil
                                                                            tokenSecret:nil];
        configuration.nonce = self.authNonce;
        configuration.timestampDate = self.authDate;
        NSString *authHeader = [PFOAuth authorizationHeaderFromConfiguration:configuration];

        [self assertAuthHeader:authHeader matchesExpectedSignature:@"3Nvy4O1Ok3qkeKcjvtv4wtyjc%2FY%3D"];
    } @finally {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}

- (void)testWithQuery {
    NSURL *url = [NSURL URLWithString:[[[self sampleURL] absoluteString] stringByAppendingString:@"?key=value"]];

    PFOAuthConfiguration *configuration = [PFOAuthConfiguration configurationForURL:url
                                                                             method:@"GET"
                                                                               body:nil
                                                               additionalParameters:nil
                                                                        consumerKey:@"consumer_key"
                                                                     consumerSecret:@"consumer_secret"
                                                                              token:nil
                                                                        tokenSecret:nil];
    configuration.nonce = self.authNonce;
    configuration.timestampDate = self.authDate;
    NSString *authHeader = [PFOAuth authorizationHeaderFromConfiguration:configuration];
    [self assertAuthHeader:authHeader matchesExpectedSignature:@"LecftA2NX%2FvSD4KakdTFjPZlmc0%3D"];
}

@end
