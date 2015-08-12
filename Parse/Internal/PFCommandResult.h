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

@interface PFCommandResult : NSObject

@property (nonatomic, strong, readonly) id result;
@property (nullable, nonatomic, copy, readonly) NSString *resultString;
@property (nullable, nonatomic, strong, readonly) NSHTTPURLResponse *httpResponse;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithResult:(NSDictionary *)result
                  resultString:(nullable NSString *)resultString
                  httpResponse:(nullable NSHTTPURLResponse *)response NS_DESIGNATED_INITIALIZER;
+ (instancetype)commandResultWithResult:(NSDictionary *)result
                           resultString:(nullable NSString *)resultString
                           httpResponse:(nullable NSHTTPURLResponse *)response;

@end

NS_ASSUME_NONNULL_END
