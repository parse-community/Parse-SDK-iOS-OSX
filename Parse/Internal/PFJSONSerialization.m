/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFJSONSerialization.h"

#import "PFLogging.h"

@implementation PFJSONSerialization

+ (NSData *)dataFromJSONObject:(id)object {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (!data || error != nil) {
        [NSException raise:NSInvalidArgumentException
                    format:@"PFObject values must be serializable to JSON"];
    }
    return data;
}

+ (NSString *)stringFromJSONObject:(id)object {
    NSData *data = [self dataFromJSONObject:object];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

+ (id)JSONObjectFromData:(NSData *)data {
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data
                                                options:0
                                                  error:&error];
    if (!object || error != nil) {
        PFLogError(PFLoggingTagCommon, @"JSON deserialization failed with error: %@", [error description]);
    }

    return object;
}

+ (id)JSONObjectFromString:(NSString *)string {
    return [self JSONObjectFromData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
