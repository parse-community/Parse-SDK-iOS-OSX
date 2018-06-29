/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PF_OAuthCore.h"

#import <CommonCrypto/CommonHMAC.h>

static NSData *PF_HMAC_SHA1(NSString *data, NSString *key) {
    unsigned char buf[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key length], [data UTF8String], [data length], buf);
    return [NSData dataWithBytes:buf length:CC_SHA1_DIGEST_LENGTH];
}

@implementation PFOAuthConfiguration

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _nonce = [[NSUUID UUID] UUIDString];
    _timestampDate = [NSDate date];

    return self;
}

+ (instancetype)configurationForURL:(NSURL *)url
                             method:(NSString *)method
                               body:(nullable NSData *)body
               additionalParameters:(nullable NSDictionary *)additionalParams
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                              token:(nullable NSString *)token
                        tokenSecret:(nullable NSString *)tokenSecret {
    PFOAuthConfiguration *configuration = [[self alloc] init];
    configuration.url = url;
    configuration.method = method;
    configuration.body = body;
    configuration.additionalParameters = additionalParams;
    configuration.consumerKey = consumerKey;
    configuration.consumerSecret = consumerSecret;
    configuration.token = token;
    configuration.tokenSecret = tokenSecret;
    return configuration;
}

@end

@implementation PFOAuth

+ (NSString *)authorizationHeaderFromConfiguration:(PFOAuthConfiguration *)configuration {
    NSString *authTimeStamp = [NSString stringWithFormat:@"%llu",
                               (unsigned long long)floor([configuration.timestampDate timeIntervalSince1970])];
    NSString *authSignatureMethod = @"HMAC-SHA1";
    NSString *authVersion = @"1.0";
    NSURL *url = configuration.url;

    // Don't use -mutableCopy here, as that will return nil if `additionalParams` is nil.
    NSMutableDictionary *oAuthAuthorizationParameters = [NSMutableDictionary dictionaryWithDictionary:configuration.additionalParameters];

    oAuthAuthorizationParameters[@"oauth_nonce"] = configuration.nonce;
    oAuthAuthorizationParameters[@"oauth_timestamp"] = authTimeStamp;
    oAuthAuthorizationParameters[@"oauth_signature_method"] = authSignatureMethod;
    oAuthAuthorizationParameters[@"oauth_version"] = authVersion;
    oAuthAuthorizationParameters[@"oauth_consumer_key"] = configuration.consumerKey;

    if (configuration.token) {
        oAuthAuthorizationParameters[@"oauth_token"] = configuration.token;
    }

    // get query and body parameters
    NSDictionary *additionalQueryParameters = [NSURL PF_ab_parseURLQueryString:[url query]];
    NSDictionary *additionalBodyParameters = nil;
    if (configuration.body) {
        NSString *string = [[NSString alloc] initWithData:configuration.body encoding:NSUTF8StringEncoding];
        additionalBodyParameters = [NSURL PF_ab_parseURLQueryString:string];
    }

    // combine all parameters
    NSMutableDictionary *parameters = [oAuthAuthorizationParameters mutableCopy];
    [parameters addEntriesFromDictionary:additionalQueryParameters];
    if (additionalBodyParameters) {
        [parameters addEntriesFromDictionary:additionalBodyParameters];
    }

    NSArray *sortedKeys = [[parameters allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2] ?: [parameters[obj1] compare:parameters[obj2]];
    }];

    NSMutableArray *parameterArray = [NSMutableArray array];
    for (NSString *key in sortedKeys) {
        [parameterArray addObject:[NSString stringWithFormat:@"%@=%@", key, [parameters[key] PF_ab_RFC3986EncodedString]]];
    }

    NSString *normalizedParameterString = [parameterArray componentsJoinedByString:@"&"];
    NSString *normalizedURLString = [NSString stringWithFormat:@"%@://%@%@", [url scheme], [url host], [url path]];

    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",
                                     [configuration.method PF_ab_RFC3986EncodedString],
                                     [normalizedURLString PF_ab_RFC3986EncodedString],
                                     [normalizedParameterString PF_ab_RFC3986EncodedString]];

    NSString *key = [NSString stringWithFormat:@"%@&%@",
                     [configuration.consumerSecret PF_ab_RFC3986EncodedString],
                     (configuration.tokenSecret ? [configuration.tokenSecret PF_ab_RFC3986EncodedString] : @"")];

    NSData *signature = PF_HMAC_SHA1(signatureBaseString, key);
    NSString *base64Signature = [signature base64EncodedStringWithOptions:0];

    oAuthAuthorizationParameters[@"oauth_signature"] = base64Signature;

    NSMutableArray *authorizationHeaderItems = [NSMutableArray array];
    [oAuthAuthorizationParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        [authorizationHeaderItems addObject:[NSString stringWithFormat:@"%@=\"%@\"",
                                             [key PF_ab_RFC3986EncodedString],
                                             [value PF_ab_RFC3986EncodedString]]];
    }];

    NSString *authorizationHeaderString = [authorizationHeaderItems componentsJoinedByString:@", "];
    authorizationHeaderString = [NSString stringWithFormat:@"OAuth %@", authorizationHeaderString];

    return authorizationHeaderString;
}

@end

@implementation NSURL (OAuthAdditions)

+ (NSDictionary *)PF_ab_parseURLQueryString:(NSString *)query {
    // Use NSURLComponents if available.
    if ([NSURLComponents class] != nil && [NSURLComponents instancesRespondToSelector:@selector(queryItems)]) {
        NSURLComponents *components = [[NSURLComponents alloc] init];
        [components setQuery:query];

        NSArray *queryItems = components.queryItems;

        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:components.queryItems.count];
        for (NSURLQueryItem *item in queryItems) {
            dictionary[item.name] = [item.value stringByRemovingPercentEncoding];
        }
        return dictionary;
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *keyValue = [pair componentsSeparatedByString:@"="];
        if ([keyValue count] == 2) {
            NSString *key = [keyValue objectAtIndex:0];
            NSString *value = [keyValue objectAtIndex:1];
            value = [value stringByRemovingPercentEncoding];
            if (key && value)
                [dict setObject:value forKey:key];
        }
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end

@implementation NSString (OAuthAdditions)

- (NSString *)PF_ab_RFC3986EncodedString // UTF-8 encodes prior to URL encoding
{
    NSMutableString *result = [NSMutableString string];
    const char *p = [self UTF8String];
    unsigned char c;

    for (; (c = *p); p++) {
        switch (c) {
            case '0' ... '9':
            case 'A' ... 'Z':
            case 'a' ... 'z':
            case '.':
            case '-':
            case '~':
            case '_':
                [result appendFormat:@"%c", c];
                break;
            default:
                [result appendFormat:@"%%%02X", c];
        }
    }
    return result;
}

@end
