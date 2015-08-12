/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRelation.h"
#import "PFRelationPrivate.h"

#import <Foundation/Foundation.h>

#import "PFAssert.h"
#import "PFFieldOperation.h"
#import "PFInternalUtils.h"
#import "PFMacros.h"
#import "PFMutableRelationState.h"
#import "PFObjectPrivate.h"
#import "PFQueryPrivate.h"

NSString *const PFRelationKeyClassName = @"className";
NSString *const PFRelationKeyType = @"__type";
NSString *const PFRelationKeyObjects = @"objects";

@interface PFRelation () {
    //
    // Use this queue as follows:
    // Because state is defined as an atomic property, there's no need to use the queue if you're only reading from
    // self.state once during the method.
    //
    // If you ever need to use self.state more than once, either take a copy at the top of the function, or use a
    // dispatch_sync block.
    //
    // If you are ever changing the state variable, you should use dispatch_sync.
    //
    dispatch_queue_t _stateAccessQueue;
}

@property (atomic, copy) PFMutableRelationState *state;

@end

@implementation PFRelation

@dynamic targetClass;

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _stateAccessQueue = dispatch_queue_create("com.parse.relation.state.access", DISPATCH_QUEUE_SERIAL);
    _state = [[PFMutableRelationState alloc] init];

    return self;
}

- (instancetype)initWithParent:(PFObject *)newParent key:(NSString *)newKey {
    self = [self init];
    if (!self) return nil;

    _state.parent = newParent;
    _state.key = newKey;

    return self;
}

- (instancetype)initWithTargetClass:(NSString *)newTargetClass {
    self = [self init];
    if (!self) return nil;

    _state.targetClass = newTargetClass;

    return self;
}

- (instancetype)initFromDictionary:(NSDictionary *)dictionary withDecoder:(PFDecoder *)decoder {
    self = [self init];
    if (!self) return nil;

    NSArray *array = dictionary[PFRelationKeyObjects];
    NSMutableSet *known = [[NSMutableSet alloc] initWithCapacity:array.count];

    // Decode the result
    for (id encodedObject in array) {
        [known addObject:[decoder decodeObject:encodedObject]];
    }

    _state.targetClass = dictionary[PFRelationKeyClassName];
    [_state.knownObjects setSet:known];

    return self;
}

+ (PFRelation *)relationForObject:(PFObject *)parent forKey:(NSString *)key {
    return [[PFRelation alloc] initWithParent:parent key:key];
}

+ (PFRelation *)relationWithTargetClass:(NSString *)targetClass {
    return [[PFRelation alloc] initWithTargetClass:targetClass];
}

+ (PFRelation *)relationFromDictionary:(NSDictionary *)dictionary withDecoder:(PFDecoder *)decoder {
    return [[PFRelation alloc] initFromDictionary:dictionary withDecoder:decoder];
}

- (void)ensureParentIs:(PFObject *)someParent andKeyIs:(NSString *)someKey {
    pf_sync_with_throw(_stateAccessQueue, ^{
        __strong PFObject *sparent = self.state.parent;

        if (!sparent) {
            sparent = self.state.parent = someParent;
        }

        if (!self.state.key) {
            self.state.key = someKey;
        }

        PFConsistencyAssert(sparent == someParent,
                            @"Internal error. One PFRelation retrieved from two different PFObjects.");

        PFConsistencyAssert([self.state.key isEqualToString:someKey],
                            @"Internal error. One PFRelation retrieved from two different keys.");
    });
}

- (NSString *)description {
    PFRelationState *state = [self.state copy];

    return [NSString stringWithFormat:@"<%@: %p, %p.%@ -> %@>",
            [self class],
            self,
            state.parent,
            state.key,
            state.targetClass];
}

- (PFQuery *)query {
    PFRelationState *state = [self.state copy];
    __strong PFObject *sparent = state.parent;

    PFQuery *query = nil;
    if (state.targetClass) {
        query = [PFQuery queryWithClassName:state.targetClass];
    } else {
        query = [PFQuery queryWithClassName:state.parentClassName];
        [query redirectClassNameForKey:state.key];
    }
    if (sparent) {
        [query whereRelatedToObject:sparent fromKey:state.key];
    } else if (state.parentClassName) {
        PFObject *object = [PFObject objectWithoutDataWithClassName:state.parentClassName
                                                           objectId:state.parentObjectId];
        [query whereRelatedToObject:object fromKey:state.key];
    }

    return query;
}

- (NSString *)targetClass {
    return self.state.targetClass;
}

- (void)setTargetClass:(NSString *)targetClass {
    dispatch_sync(_stateAccessQueue, ^{
        self.state.targetClass = targetClass;
    });
}

- (void)addObject:(PFObject *)object {
    pf_sync_with_throw(_stateAccessQueue, ^{
        PFRelationState *state = self.state;

        PFRelationOperation *op = [PFRelationOperation addRelationToObjects:@[ object ]];
        [state.parent performOperation:op forKey:state.key];

        self.state.targetClass = op.targetClass;
        [self.state.knownObjects addObject:object];
    });
}

- (void)removeObject:(PFObject *)object {
    pf_sync_with_throw(_stateAccessQueue, ^{
        PFRelationState *state = self.state;

        PFRelationOperation *op = [PFRelationOperation removeRelationToObjects:@[ object ]];
        [state.parent performOperation:op forKey:state.key];

        self.state.targetClass = op.targetClass;
        [self.state.knownObjects removeObject:object];
    });
}

- (NSDictionary *)encodeIntoDictionary {
    PFRelationState *state = [self.state copy];
    NSMutableArray *encodedObjects = [NSMutableArray arrayWithCapacity:state.knownObjects.count];

    for (PFObject *knownObject in state.knownObjects) {
        [encodedObjects addObject:[[PFPointerObjectEncoder objectEncoder] encodeObject:knownObject]];
    }

    return @{
             PFRelationKeyType : @"Relation",
             PFRelationKeyClassName : state.targetClass,
             PFRelationKeyObjects : encodedObjects
             };
}

/*!
 Returns true if and only if this object was ever known to be in the relation.
 This is used for offline caching.
 */
- (BOOL)_hasKnownObject:(PFObject *)object {
    __block BOOL results = NO;

    dispatch_sync(_stateAccessQueue, ^{
        results = [self.state.knownObjects containsObject:object];
    });

    return results;
}

- (void)_addKnownObject:(PFObject *)object {
    dispatch_sync(_stateAccessQueue, ^{
        [self.state.knownObjects addObject:object];
    });
}

- (void)_removeKnownObject:(PFObject *)object {
    dispatch_sync(_stateAccessQueue, ^{
        [self.state.knownObjects removeObject:object];
    });
}

@end
