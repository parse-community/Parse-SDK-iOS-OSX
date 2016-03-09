/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class PFFieldOperation;
@class PFOperationSet;

@interface PFObjectEstimatedData : NSObject

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithServerData:(NSDictionary *)serverData
                 operationSetQueue:(NSArray *)operationSetQueue;
+ (instancetype)estimatedDataFromServerData:(NSDictionary *)serverData
                          operationSetQueue:(NSArray *)operationSetQueue;

///--------------------------------------
#pragma mark - Read
///--------------------------------------

- (id)objectForKey:(NSString *)key;
- (id)objectForKeyedSubscript:(NSString *)keyedSubscript;

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(NSString *key, id obj, BOOL *stop))block;

@property (nonatomic, copy, readonly) NSArray *allKeys;
@property (nonatomic, copy, readonly) NSDictionary *dictionaryRepresentation;

///--------------------------------------
#pragma mark - Write
///--------------------------------------

- (id)applyFieldOperation:(PFFieldOperation *)operation forKey:(NSString *)key;

@end
