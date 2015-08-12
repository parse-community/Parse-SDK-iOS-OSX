/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTCommand.h"

@class PFQueryState;

NS_ASSUME_NONNULL_BEGIN

@interface PFRESTQueryCommand : PFRESTCommand

///--------------------------------------
/// @name Find
///--------------------------------------

+ (instancetype)findCommandForQueryState:(PFQueryState *)queryState withSessionToken:(nullable NSString *)sessionToken;

+ (instancetype)findCommandForClassWithName:(NSString *)className
                                      order:(nullable NSString *)order
                                 conditions:(nullable NSDictionary *)conditions
                               selectedKeys:(nullable NSSet *)selectedKeys
                               includedKeys:(nullable NSSet *)includedKeys
                                      limit:(NSInteger)limit
                                       skip:(NSInteger)skip
                               extraOptions:(nullable NSDictionary *)extraOptions
                             tracingEnabled:(BOOL)trace
                               sessionToken:(nullable NSString *)sessionToken;

///--------------------------------------
/// @name Count
///--------------------------------------

+ (instancetype)countCommandFromFindCommand:(PFRESTQueryCommand *)findCommand;

///--------------------------------------
/// @name Parameters
///--------------------------------------

+ (NSDictionary *)findCommandParametersForQueryState:(PFQueryState *)queryState;
+ (NSDictionary *)findCommandParametersWithOrder:(nullable NSString *)order
                                      conditions:(nullable NSDictionary *)conditions
                                    selectedKeys:(nullable NSSet *)selectedKeys
                                    includedKeys:(nullable NSSet *)includedKeys
                                           limit:(NSInteger)limit
                                            skip:(NSInteger)skip
                                    extraOptions:(nullable NSDictionary *)extraOptions
                                  tracingEnabled:(BOOL)trace;

@end

NS_ASSUME_NONNULL_END
