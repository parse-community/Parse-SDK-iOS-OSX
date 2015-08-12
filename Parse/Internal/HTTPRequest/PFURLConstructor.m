/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLConstructor.h"

#import "PFAssert.h"

@implementation PFURLConstructor

///--------------------------------------
#pragma mark - Basic
///--------------------------------------

+ (NSURL *)URLFromBaseURL:(NSURL *)baseURL
                     path:(NSString *)path {
    return [self URLFromBaseURL:baseURL path:path queryParameters:nil];
}

+ (NSURL *)URLFromBaseURL:(NSURL *)baseURL
          queryParameters:(NSDictionary *)queryParameters {
    return [self URLFromBaseURL:baseURL path:nil queryParameters:queryParameters];
}

+ (NSURL *)URLFromBaseURL:(NSURL *)baseURL
                     path:(NSString *)path
          queryParameters:(NSDictionary *)queryParameters {
    if (!baseURL) {
        return nil;
    }

    NSString *escapedPath = [self stringByAddingPercentEscapesToString:path
                                                   forURLComponentType:PFURLComponentTypePath];
    NSString *escapedQuery = [self _URLQueryStringFromQueryParameters:queryParameters];

    NSMutableString *relativeString = (escapedPath ? [escapedPath mutableCopy] : [NSMutableString string]);
    if (escapedQuery) {
        [relativeString appendFormat:@"?%@", escapedQuery];
    }

    return [NSURL URLWithString:relativeString relativeToURL:baseURL];
}

///--------------------------------------
#pragma mark - Escaping
///--------------------------------------

+ (NSString *)stringByAddingPercentEscapesToString:(NSString *)string
                               forURLComponentType:(PFURLComponentType)type {
    PFParameterAssert(type <= PFURLComponentTypeQuery, @"`type` should only be of PFURLComponentType");

    if (!string) {
        return nil;
    }

    static NSString *reservedCharacters = @"!*'();:@&=+$,/?%#[]";
    NSString *escapedString = nil;

    switch (type) {
        case PFURLComponentTypePath:
        {
            static NSString *pathSeparator = @"/";

            NSArray *components = [string componentsSeparatedByString:pathSeparator];
            if ([components count]) {
                NSMutableArray *escapedComponents = [NSMutableArray arrayWithCapacity:[components count]];
                for (NSString *component in components) {
                    NSString *escapedComponent = [self _stringByAddingPercentEscapesToString:component
                                                                      withReservedCharacters:reservedCharacters];
                    [escapedComponents addObject:escapedComponent];
                }
                escapedString = [escapedComponents componentsJoinedByString:pathSeparator];
            } else {
                escapedString = [self _stringByAddingPercentEscapesToString:string
                                                     withReservedCharacters:reservedCharacters];
            }
        }
            break;
        case PFURLComponentTypeQuery:
        {
            escapedString = [self _stringByAddingPercentEscapesToString:string
                                                 withReservedCharacters:reservedCharacters];
        }
            break;
        default:break;
    }

    return escapedString;
}

+ (NSString *)_stringByAddingPercentEscapesToString:(NSString *)string
                                 withReservedCharacters:(NSString *)reservedCharacters {
    CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                        (__bridge CFStringRef)string,
                                                                        NULL, // Allowed characters
                                                                        (__bridge CFStringRef)reservedCharacters,
                                                                        kCFStringEncodingUTF8);
    return CFBridgingRelease(escapedString);
}

///--------------------------------------
#pragma mark - URLQuery
///--------------------------------------

+ (NSString *)_URLQueryStringFromQueryParameters:(NSDictionary *)parameters {
    if ([parameters count] == 0) {
        return nil;
    }

    NSMutableArray *encodedParameters = [NSMutableArray array];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [encodedParameters addObject:[self _URLQueryParameterWithKey:key value:obj]];
    }];
    return [encodedParameters componentsJoinedByString:@"&"];

}

+ (NSString *)_URLQueryParameterWithKey:(NSString *)key value:(NSString *)value {
    NSString *string = [NSString stringWithFormat:@"%@=%@",
                        [self stringByAddingPercentEscapesToString:key forURLComponentType:PFURLComponentTypeQuery],
                        [self stringByAddingPercentEscapesToString:value forURLComponentType:PFURLComponentTypeQuery]];
    return string;
}

@end
