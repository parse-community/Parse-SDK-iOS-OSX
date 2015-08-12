/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectUtilities.h"

#import "PFFieldOperation.h"
#import "PFOperationSet.h"

@implementation PFObjectUtilities

///--------------------------------------
#pragma mark - Operations
///--------------------------------------

+ (id)newValueByApplyingFieldOperation:(PFFieldOperation *)operation
                          toDictionary:(NSMutableDictionary *)dictionary
                                forKey:(NSString *)key {
    id oldValue = dictionary[key];
    id newValue = [operation applyToValue:oldValue forKey:key];
    if (newValue) {
        dictionary[key] = newValue;
    } else {
        [dictionary removeObjectForKey:key];
    }
    return newValue;
}

+ (void)applyOperationSet:(PFOperationSet *)operationSet toDictionary:(NSMutableDictionary *)dictionary {
    [operationSet enumerateKeysAndObjectsUsingBlock:^(NSString *key, PFFieldOperation *obj, BOOL *stop) {
        [self newValueByApplyingFieldOperation:obj toDictionary:dictionary forKey:key];
    }];
}

///--------------------------------------
#pragma mark - Equality
///--------------------------------------

+ (BOOL)isObject:(id<NSObject>)objectA equalToObject:(id<NSObject>)objectB {
    return (objectA == objectB || (objectA != nil && [objectA isEqual:objectB]));
}

@end
