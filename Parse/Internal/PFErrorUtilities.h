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

@interface PFErrorUtilities : NSObject

/*!
 Construct an error object from a code and a message.

 @description Note that this logs all errors given to it.
 You should use `errorWithCode:message:shouldLog:` to explicitly control whether it logs.

 @param code    Parse Error Code
 @param message Error description

 @return `NSError` instance.
 */
+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message;
+ (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message shouldLog:(BOOL)shouldLog;

/*!
 Construct an error object from a result dictionary the API returned.

 @description Note that this logs all errors given to it.
 You should use `errorFromResult:shouldLog:` to explicitly control whether it logs.

 @param result Network command result.

 @return `NSError` instance.
 */
+ (NSError *)errorFromResult:(NSDictionary *)result;
+ (NSError *)errorFromResult:(NSDictionary *)result shouldLog:(BOOL)shouldLog;

@end

NS_ASSUME_NONNULL_END
