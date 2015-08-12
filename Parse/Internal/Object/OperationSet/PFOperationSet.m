/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFOperationSet.h"

#import "PFACL.h"
#import "PFACLPrivate.h"
#import "PFDecoder.h"
#import "PFEncoder.h"
#import "PFFieldOperation.h"
#import "PFInternalUtils.h"

NSString *const PFOperationSetKeyUUID = @"__uuid";
NSString *const PFOperationSetKeyIsSaveEventually = @"__isSaveEventually";
NSString *const PFOperationSetKeyUpdatedAt = @"__updatedAt";
NSString *const PFOperationSetKeyACL = @"ACL";

@interface PFOperationSet()

@property (nonatomic, strong) NSMutableDictionary *dictionary;

@end

@implementation PFOperationSet

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    return [self initWithUUID:[[NSUUID UUID] UUIDString]];
}

- (instancetype)initWithUUID:(NSString *)uuid {
    self = [super init];
    if (!self) return nil;

    _dictionary = [NSMutableDictionary dictionary];
    _uuid = [uuid copy];

    _updatedAt = [NSDate date];

    return self;
}

///--------------------------------------
#pragma mark - Merge
///--------------------------------------

- (void)mergeOperationSet:(PFOperationSet *)other {
    [other.dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        PFFieldOperation *localOperation = self.dictionary[key];
        PFFieldOperation *remoteOperation = other.dictionary[key];
        if (localOperation != nil) {
            localOperation = [localOperation mergeWithPrevious:remoteOperation];
            self.dictionary[key] = localOperation;
        } else {
            self.dictionary[key] = remoteOperation;
        }
    }];
    self.updatedAt = [NSDate date];
}

///--------------------------------------
#pragma mark - Encoding
///--------------------------------------

- (NSDictionary *)RESTDictionaryUsingObjectEncoder:(PFEncoder *)objectEncoder
                                 operationSetUUIDs:(NSArray **)operationSetUUIDs {
    NSMutableDictionary *operationSetResult = [[NSMutableDictionary alloc] init];
    [self.dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        operationSetResult[key] = [obj encodeWithObjectEncoder:objectEncoder];
    }];

    operationSetResult[PFOperationSetKeyUUID] = self.uuid;
    operationSetResult[PFOperationSetKeyUpdatedAt] = [objectEncoder encodeObject:self.updatedAt];

    if (self.saveEventually) {
        operationSetResult[PFOperationSetKeyIsSaveEventually] = @YES;
    }
    *operationSetUUIDs = @[ self.uuid ];
    return operationSetResult;
}

+ (PFOperationSet *)operationSetFromRESTDictionary:(NSDictionary *)data
                                      usingDecoder:(PFDecoder *)decoder {
    NSMutableDictionary *mutableData = [data mutableCopy];
    NSString *inputUUID = mutableData[PFOperationSetKeyUUID];
    [mutableData removeObjectForKey:PFOperationSetKeyUUID];
    PFOperationSet *operationSet = nil;
    if (inputUUID == nil) {
        operationSet = [[PFOperationSet alloc] init];
    } else {
        operationSet = [[PFOperationSet alloc] initWithUUID:inputUUID];
    }

    NSNumber *saveEventuallyFlag = mutableData[PFOperationSetKeyIsSaveEventually];
    if (saveEventuallyFlag) {
        operationSet.saveEventually = [saveEventuallyFlag boolValue];
        [mutableData removeObjectForKey:PFOperationSetKeyIsSaveEventually];
    }

    NSDate *updatedAt = mutableData[PFOperationSetKeyUpdatedAt];
    [mutableData removeObjectForKey:PFOperationSetKeyUpdatedAt];

    [mutableData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = [decoder decodeObject:obj];
        PFFieldOperation *fieldOperation = nil;
        if ([key isEqualToString:PFOperationSetKeyACL]) {
            // TODO (hallucinogen): where to use the decoder?
            value = [PFACL ACLWithDictionary:obj];
        }
        if ([value isKindOfClass:[PFFieldOperation class]]) {
            fieldOperation = value;
        } else {
            fieldOperation = [PFSetOperation setWithValue:value];
        }
        operationSet[key] = fieldOperation;
    }];
    operationSet.updatedAt = updatedAt ? [decoder decodeObject:updatedAt] : nil;

    return operationSet;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (id)objectForKey:(id)aKey {
    return self.dictionary[aKey];
}

- (id)objectForKeyedSubscript:(id)aKey {
    return [self objectForKey:aKey];
}

- (NSUInteger)count {
    return [self.dictionary count];
}

- (NSEnumerator *)keyEnumerator {
    return [self.dictionary keyEnumerator];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(NSString *key, PFFieldOperation *operation, BOOL *stop))block {
    [self.dictionary enumerateKeysAndObjectsUsingBlock:block];
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    self.dictionary[aKey] = anObject;
    self.updatedAt = [NSDate date];
}

- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key {
    [self setObject:anObject forKey:key];
}

- (void)removeObjectForKey:(id)key {
    [self.dictionary removeObjectForKey:key];
    self.updatedAt = [NSDate date];
}

///--------------------------------------
#pragma mark - NSFastEnumeration
///--------------------------------------

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
    return [self.dictionary countByEnumeratingWithState:state objects:buffer count:len];
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (instancetype)copyWithZone:(NSZone *)zone {
    PFOperationSet *operationSet = [[[self class] allocWithZone:zone] initWithUUID:self.uuid];
    operationSet.dictionary = [self.dictionary mutableCopy];
    operationSet.updatedAt = [self.updatedAt copy];
    operationSet.saveEventually = self.saveEventually;
    return operationSet;
}

@end
