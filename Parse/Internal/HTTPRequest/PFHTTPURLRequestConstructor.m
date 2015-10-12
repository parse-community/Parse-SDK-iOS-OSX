/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFHTTPURLRequestConstructor.h"

#import "PFAssert.h"
#import "PFHTTPRequest.h"
#import "PFURLConstructor.h"

static NSString *const PFHTTPURLRequestContentTypeJSON = @"application/json; charset=utf-8";

@implementation PFHTTPURLRequestConstructor

///--------------------------------------
#pragma mark - Public
///--------------------------------------

+ (NSMutableURLRequest *)urlRequestWithURL:(NSURL *)url
                                httpMethod:(NSString *)httpMethod
                               httpHeaders:(NSDictionary *)httpHeaders
                                parameters:(NSDictionary *)parameters {
    NSParameterAssert(url != nil);
    NSParameterAssert(httpMethod != nil);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = httpMethod;
    request.allHTTPHeaderFields = httpHeaders;

    if (parameters != nil) {
        PFConsistencyAssert([httpMethod isEqualToString:PFHTTPRequestMethodPOST] ||
                            [httpMethod isEqualToString:PFHTTPRequestMethodPUT],
                            @"Can't create %@ request with json body.", httpMethod);

        [request setValue:PFHTTPURLRequestContentTypeJSON forHTTPHeaderField:PFHTTPRequestHeaderNameContentType];

        NSError *error = nil;
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters
                                                             options:(NSJSONWritingOptions)0
                                                               error:&error]];
        PFConsistencyAssert(error == nil, @"Failed to serialize JSON with error = %@", error);
    }
    return request;
}

@end
