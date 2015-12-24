/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectEstimatedData.h"

#import "PFObjectUtilities.h"

@interface PFObjectEstimatedData () {
    NSMutableDictionary *_dataDictionary;
}

@end

@implementation PFObjectEstimatedData

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _dataDictionary = [NSMutableDictionary dictionary];

    return self;
}

- (instancetype)initWithServerData:(NSDictionary *)serverData
                 operationSetQueue:(NSArray *)operationSetQueue {
    self = [super init];
    if (!self) return nil;

    // Don't use mutableCopy to make sure we never initialize _dataDictionary to `nil`.
    _dataDictionary = [NSMutableDictionary dictionaryWithDictionary:serverData];
    for (PFOperationSet *operationSet in operationSetQueue) {
        [PFObjectUtilities applyOperationSet:operationSet toDictionary:_dataDictionary];
    }

    return self;
}

+ (instancetype)estimatedDataFromServerData:(NSDictionary *)serverData
                          operationSetQueue:(NSArray *)operationSetQueue {
    return [[self alloc] initWithServerData:serverData operationSetQueue:operationSetQueue];
}

///--------------------------------------
#pragma mark - Read
///--------------------------------------

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(NSString *key, id obj, BOOL *stop))block {
    [_dataDictionary enumerateKeysAndObjectsUsingBlock:block];
}

- (id)objectForKey:(NSString *)key {
    return [_dataDictionary objectForKey:key];
}

- (id)objectForKeyedSubscript:(NSString *)keyedSubscript {
    return [_dataDictionary objectForKeyedSubscript:keyedSubscript];
}

- (NSArray *)allKeys {
    return _dataDictionary.allKeys;
}

- (NSDictionary *)dictionaryRepresentation {
    return [_dataDictionary copy];
}

///--------------------------------------
#pragma mark - Write
///--------------------------------------

- (id)applyFieldOperation:(PFFieldOperation *)operation forKey:(NSString *)key {
    return [PFObjectUtilities newValueByApplyingFieldOperation:operation toDictionary:_dataDictionary forKey:key];
}

@end
