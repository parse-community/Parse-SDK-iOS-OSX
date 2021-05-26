/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCommandResult.h"

#import "PFAssert.h"

@implementation PFCommandResult

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithResult:(NSDictionary *)result
                  resultString:(NSString *)resultString
                  httpResponse:(NSHTTPURLResponse *)response {
    self = [super init];
    if (!self) return nil;

    _result = result;
    _resultString = [resultString copy];
    _httpResponse = response;

    return self;
}

+ (instancetype)commandResultWithResult:(NSDictionary *)result
                           resultString:(NSString *)resultString
                           httpResponse:(NSHTTPURLResponse *)response {
    return [[self alloc] initWithResult:result resultString:resultString httpResponse:response];
}

@end
