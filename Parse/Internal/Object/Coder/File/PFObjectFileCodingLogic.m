/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectFileCodingLogic.h"

#import "PFMutableObjectState.h"
#import "PFObjectPrivate.h"

@implementation PFObjectFileCodingLogic

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)codingLogic {
    return [[self alloc] init];
}

///--------------------------------------
#pragma mark - Logic
///--------------------------------------

- (void)updateObject:(PFObject *)object fromDictionary:(NSDictionary *)dictionary usingDecoder:(PFDecoder *)decoder {
    PFMutableObjectState *state = [object._state mutableCopy];
    NSString *newObjectId = dictionary[@"id"];
    if (newObjectId) {
        state.objectId = newObjectId;
    }
    NSString *createdAtString = dictionary[@"created_at"];
    if (createdAtString) {
        [state setCreatedAtFromString:createdAtString];
    }
    NSString *updatedAtString = dictionary[@"updated_at"];
    if (updatedAtString) {
        [state setUpdatedAtFromString:updatedAtString];
    }
    object._state = state;

    NSDictionary *newPointers = dictionary[@"pointers"];
    NSMutableDictionary *pointersDictionary = [NSMutableDictionary dictionaryWithCapacity:newPointers.count];
    [newPointers enumerateKeysAndObjectsUsingBlock:^(id key, NSArray *pointerArray, BOOL *stop) {
        PFObject *pointer = [PFObject objectWithoutDataWithClassName:[pointerArray firstObject]
                                                            objectId:[pointerArray lastObject]];
        pointersDictionary[key] = pointer;
    }];

    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionaryWithDictionary:dictionary[@"data"]];
    [dataDictionary addEntriesFromDictionary:pointersDictionary];
    [object _mergeAfterFetchWithResult:dataDictionary decoder:decoder completeData:YES];
}

@end
