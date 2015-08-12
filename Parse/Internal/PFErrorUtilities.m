/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFErrorUtilities.h"

#import "PFConstants.h"
#import "PFLogging.h"

@implementation PFErrorUtilities

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message {
    return [self errorWithCode:code message:message shouldLog:YES];
}

+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message shouldLog:(BOOL)shouldLog {
    NSDictionary *result = @{ @"code" : @(code),
                              @"error" : message };
    return [self errorFromResult:result shouldLog:shouldLog];
}

+ (NSError *)errorFromResult:(NSDictionary *)result {
    return [self errorFromResult:result shouldLog:YES];
}

+ (NSError *)errorFromResult:(NSDictionary *)result shouldLog:(BOOL)shouldLog {
    NSInteger errorCode = [[result objectForKey:@"code"] integerValue];

    NSString *errorExplanation = [result objectForKey:@"error"];

    if (shouldLog) {
        PFLogError(PFLoggingTagCommon,
                   @"%@ (Code: %ld, Version: %@)", errorExplanation, (long)errorCode, PARSE_VERSION);
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:result];
    if (errorExplanation) {
        userInfo[NSLocalizedDescriptionKey] = errorExplanation;
    }
    return [NSError errorWithDomain:PFParseErrorDomain code:errorCode userInfo:userInfo];
}

@end
