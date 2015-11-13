/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAnalyticsUtilities.h"

#import "PFHash.h"

@implementation PFAnalyticsUtilities

+ (NSString *)md5DigestFromPushPayload:(id)payload {
    if (!payload || payload == [NSNull null]) {
        payload = @"";
    } else if ([payload isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = payload;
        NSArray *keys = [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)];
        NSMutableArray *components = [NSMutableArray arrayWithCapacity:[dict count] * 2];
        [keys enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
            [components addObject:key];

            // alert[@"loc-args"] can be an NSArray
            id value = dict[key];
            if ([value isKindOfClass:[NSArray class]]) {
                value = [value componentsJoinedByString:@""];
            }
            [components addObject:value];
        }];
        payload = [components componentsJoinedByString:@""];
    }
    return PFMD5HashFromString([payload description]);
}

@end
