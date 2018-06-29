/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMockURLResponse.h"

@interface PFMockURLResponse ()

@property (nonatomic, assign, readwrite) NSInteger statusCode;
@property (nonatomic, copy, readwrite) NSDictionary *httpHeaders;

@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, copy, readwrite) NSData *responseData;

@property (nonatomic, assign, readwrite) NSTimeInterval delay;

@end

@implementation PFMockURLResponse

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)responseWithError:(NSError *)error {
    return [self responseWithError:error delay:0.0];
}

+ (instancetype)responseWithError:(NSError *)error delay:(NSTimeInterval)delay {
    PFMockURLResponse *response = [[PFMockURLResponse alloc] init];
    response.error = error;
    response.delay = delay;
    return response;
}

+ (instancetype)responseWithString:(NSString *)string {
    return [self responseWithString:string statusCode:200 delay:0.0];
}

+ (instancetype)responseWithString:(NSString *)string
                        statusCode:(NSInteger)statusCode
                             delay:(NSTimeInterval)delay {
    NSDictionary *headers = @{ @"Content-Type" : @"application/json" };
    return [self responseWithString:string statusCode:statusCode delay:delay headers:headers];
}

+ (instancetype)responseWithString:(NSString *)string
                        statusCode:(NSInteger)statusCode
                             delay:(NSTimeInterval)delay
                           headers:(NSDictionary *)httpHeaders {
    return [self responseWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                       statusCode:statusCode
                            delay:delay
                          headers:httpHeaders];
}

+ (instancetype)responseWithData:(NSData *)data
                      statusCode:(NSInteger)statusCode
                           delay:(NSTimeInterval)delay
                         headers:(NSDictionary *)httpHeaders {
    PFMockURLResponse *response = [[PFMockURLResponse alloc] init];
    response.statusCode = statusCode;
    response.httpHeaders = httpHeaders;
    response.responseData = data;
    response.delay = delay;
    return response;
}

@end
