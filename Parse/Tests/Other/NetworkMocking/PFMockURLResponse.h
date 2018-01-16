/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Foundation;

@interface PFMockURLResponse : NSObject

@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, copy, readonly) NSDictionary *httpHeaders;

@property (nonatomic, strong, readonly) NSError *error;
@property (nonatomic, copy, readonly) NSData *responseData;

@property (nonatomic, assign, readonly) NSTimeInterval delay;


+ (instancetype)responseWithError:(NSError *)error;
+ (instancetype)responseWithError:(NSError *)error delay:(NSTimeInterval)delay;

+ (instancetype)responseWithString:(NSString *)string;
+ (instancetype)responseWithString:(NSString *)string
                        statusCode:(NSInteger)statusCode
                             delay:(NSTimeInterval)delay;
+ (instancetype)responseWithString:(NSString *)string
                        statusCode:(NSInteger)statusCode
                             delay:(NSTimeInterval)delay
                           headers:(NSDictionary *)httpHeaders;

+ (instancetype)responseWithData:(NSData *)data
                      statusCode:(NSInteger)statusCode
                           delay:(NSTimeInterval)delay
                         headers:(NSDictionary *)httpHeaders;

@end
