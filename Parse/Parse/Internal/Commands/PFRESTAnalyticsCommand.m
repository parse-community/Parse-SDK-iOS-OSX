/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTAnalyticsCommand.h"

#import "PFHTTPRequest.h"

/**
 * Predefined events - AppOpened, CrashReport
 * Coming soon - Log, ...
 */
NSString *const PFRESTAnalyticsEventNameAppOpened = @"AppOpened";
NSString *const PFRESTAnalyticsEventNameCrashReport = @"_CrashReport";

@implementation PFRESTAnalyticsCommand

+ (instancetype)trackAppOpenedEventCommandWithPushHash:(NSString *)pushHash
                                          sessionToken:(NSString *)sessionToken {
    NSDictionary *parameters = (pushHash ? @{ @"push_hash" : pushHash } : nil);
    return [self _trackEventCommandWithEventName:PFRESTAnalyticsEventNameAppOpened
                                      parameters:parameters
                                    sessionToken:sessionToken];
}

+ (instancetype)trackEventCommandWithEventName:(NSString *)eventName
                                    dimensions:(NSDictionary *)dimensions
                                  sessionToken:(NSString *)sessionToken {
    NSDictionary *parameters = (dimensions ? @{ @"dimensions" : dimensions } : nil);
    return [self _trackEventCommandWithEventName:eventName parameters:parameters sessionToken:sessionToken];
}

+ (instancetype)trackCrashReportCommandWithBreakpadDumpParameters:(NSDictionary *)parameters
                                                     sessionToken:(NSString *)sessionToken {
    return [self _trackEventCommandWithEventName:PFRESTAnalyticsEventNameCrashReport
                                      parameters:@{ @"breakpadDump" : parameters }
                                    sessionToken:sessionToken];
}

+ (instancetype)_trackEventCommandWithEventName:(NSString *)eventName
                                     parameters:(NSDictionary *)parameters
                                   sessionToken:(NSString *)sessionToken {
    NSString *httpPath = [NSString stringWithFormat:@"events/%@", eventName];

    NSMutableDictionary *dictionary = (parameters ? [parameters mutableCopy] : [NSMutableDictionary dictionary]);
    if (!dictionary[@"at"]) {
        dictionary[@"at"] = [NSDate date];
    }

    return [self commandWithHTTPPath:httpPath
                          httpMethod:PFHTTPRequestMethodPOST
                          parameters:dictionary
                        sessionToken:sessionToken];
}

@end
