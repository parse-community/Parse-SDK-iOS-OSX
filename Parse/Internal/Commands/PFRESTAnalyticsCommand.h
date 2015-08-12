/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTCommand.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const PFRESTAnalyticsEventNameAppOpened;
extern NSString *const PFRESTAnalyticsEventNameCrashReport;

@interface PFRESTAnalyticsCommand : PFRESTCommand

+ (instancetype)trackAppOpenedEventCommandWithPushHash:(nullable NSString *)pushHash
                                          sessionToken:(nullable NSString *)sessionToken;

+ (instancetype)trackEventCommandWithEventName:(NSString *)eventName
                                    dimensions:(nullable NSDictionary *)dimensions
                                  sessionToken:(nullable NSString *)sessionToken;

+ (instancetype)trackCrashReportCommandWithBreakpadDumpParameters:(NSDictionary *)parameters
                                                     sessionToken:(nullable NSString *)sessionToken;

@end

NS_ASSUME_NONNULL_END
