/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFieldOperation.h"

#import "PFAssert.h"
#import "PFDecoder.h"
#import "PFInternalUtils.h"
#import "PFObject.h"
#import "PFOfflineStore.h"
#import "PFRelation.h"
#import "PFRelationPrivate.h"

///--------------------------------------
#pragma mark - PFFieldOperation
///--------------------------------------

//  PFFieldOperation and its subclasses encapsulate operations that can be done on a field.
@implementation PFFieldOperation

- (id)encodeWithObjectEncoder:(PFEncoder *)objectEncoder {
    PFConsistencyAssert(NO, @"Operation is invalid.");
    return nil;
}

- (PFFieldOperation *)mergeWithPrevious:(PFFieldOperation *)previous {
    PFConsistencyAssert(NO, @"Operation is invalid.");
    return nil;
}

- (id)applyToValue:(id)oldValue forKey:(NSString *)key {
    PFConsistencyAssert(NO, @"Operation is invalid.");
    return nil;
}

@end

///--------------------------------------
#pragma mark - Independent Operations
///--------------------------------------

@implementation PFSetOperation

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithValue:(id)value {
    self = [super init];
    if (!self) return nil;

    PFParameterAssert(value, @"Cannot set a nil value in a PFObject.");
    _value = value;

    return self;
}

+ (id)setWithValue:(id)newValue {
    return [[self alloc] initWithValue:newValue];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"set to %@", self.value];
}

- (id)encodeWithObjectEncoder:(PFEncoder *)objectEncoder {
    return [objectEncoder encodeObject:self.value];
}

- (PFSetOperation *)mergeWithPrevious:(PFFieldOperation *)previous {
    return self;
}

- (id)applyToValue:(id)oldValue forKey:(NSString *)key {
    return self.value;
}

@end

@implementation PFDeleteOperation

+ (instancetype)operation {
    return [[self alloc] init];
}

- (NSString *)description {
    return @"delete";
}

- (id)encodeWithObjectEncoder:(PFEncoder *)objectEncoder {
    return @{ @"__op" : @"Delete" };
}

- (PFFieldOperation *)mergeWithPrevious:(PFFieldOperation *)previous {
    return self;
}

- (id)applyToValue:(id)oldValue forKey:(NSString *)key {
    return nil;
}

@end

///--------------------------------------
#pragma mark - Numeric Operations
///--------------------------------------

@implementation PFIncrementOperation

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithAmount:(NSNumber *)amount {
    self = [super init];
    if (!self) return nil;

    _amount = amount;

    return self;
}

+ (instancetype)incrementWithAmount:(NSNumber *)newAmount {
    return [[self alloc] initWithAmount:newAmount];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"increment by %@", self.amount];
}

- (id)encodeWithObjectEncoder:(PFEncoder *)objectEncoder {
    return @{ @"__op" : @"Increment",
              @"amount" : self.amount };
}

- (PFFieldOperation *)mergeWithPrevious:(PFFieldOperation *)previous {
    if (!previous) {
        return self;
    } else if ([previous isKindOfClass:[PFDeleteOperation class]]) {
        return [PFSetOperation setWithValue:self.amount];
    } else if ([previous isKindOfClass:[PFSetOperation class]]) {
        id oldValue = ((PFSetOperation *)previous).value;
        PFParameterAssert([oldValue isKindOfClass:[NSNumber class]], @"You cannot increment a non-number.");
        return [PFSetOperation setWithValue:[PFInternalUtils addNumber:self.amount withNumber:oldValue]];
    } else if ([previous isKindOfClass:[PFIncrementOperation class]]) {
        NSNumber *newAmount = [PFInternalUtils addNumber:self.amount
                                              withNumber:((PFIncrementOperation *)previous).amount];
        return [PFIncrementOperation incrementWithAmount:newAmount];
    }
    [NSException raise:NSInternalInconsistencyException format:@"Operation is invalid after previous operation."];
    return nil;
}

- (id)applyToValue:(id)oldValue forKey:(NSString *)key {
    if (!oldValue) {
        return self.amount;
    }

    PFParameterAssert([oldValue isKindOfClass:[NSNumber class]], @"You cannot increment a non-number.");
    return [PFInternalUtils addNumber:self.amount withNumber:oldValue];
}

@end

///--------------------------------------
#pragma mark - Array Operations
///--------------------------------------

@implementation PFAddOperation

- (instancetype)initWithObjects:(NSArray *)array {
    self = [super init];
    if (!self) return nil;

    _objects = array;

    return self;
}

+ (instancetype)addWithObjects:(NSArray *)objects {
    return [(PFAddOperation *)[self alloc] initWithObjects:objects];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"add %@", self.objects];
}

- (id)encodeWithObjectEncoder:(PFEncoder *)objectEncoder {
    NSMutableArray *encodedObjects = [objectEncoder encodeObject:self.objects];
    return @{ @"__op" : @"Add",
              @"objects" : encodedObjects };
}

- (PFFieldOperation *)mergeWithPrevious:(PFFieldOperation *)previous {
    if (!previous) {
        return self;
    } else if ([previous isKindOfClass:[PFDeleteOperation class]]) {
        return [PFSetOperation setWithValue:self.objects];
    } else if ([previous isKindOfClass:[PFSetOperation class]]) {
        if ([((PFSetOperation *)previous).value isKindOfClass:[NSArray class]]) {
            NSArray *oldArray = (NSArray *)(((PFSetOperation *)previous).value);
            NSArray *newArray = [oldArray arrayByAddingObjectsFromArray:self.objects];
            return [PFSetOperation setWithValue:newArray];
        } else {
            [NSException raise:NSInternalInconsistencyException format:@"You can't add an item to a non-array."];
            return nil;
        }
    } else if ([previous isKindOfClass:[PFAddOperation class]]) {
        NSMutableArray *newObjects = [((PFAddOperation *)previous).objects mutableCopy];
        [newObjects addObjectsFromArray:self.objects];
        return [[self class] addWithObjects:newObjects];
    }
    [NSException raise:NSInternalInconsistencyException format:@"Operation is invalid after previous operation."];
    return nil;
}

- (id)applyToValue:(id)oldValue forKey:(NSString *)key {
    if (!oldValue) {
        return [self.objects mutableCopy];
    } else if ([oldValue isKindOfClass:[NSArray class]]) {
        return [((NSArray *)oldValue)arrayByAddingObjectsFromArray:self.objects];
    }
    [NSException raise:NSInternalInconsistencyException format:@"Operation is invalid after previous operation."];
    return nil;
}

@end

@implementation PFAddUniqueOperation

- (instancetype)initWithObjects:(NSArray *)array {
    self = [super init];
    if (!self) return nil;

    _objects = [[NSSet setWithArray:array] allObjects];

    return self;
}

+ (instancetype)addUniqueWithObjects:(NSArray *)objects {
    return [(PFAddUniqueOperation *)[self alloc] initWithObjects:objects];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"addToSet %@", self.objects];
}

- (id)encodeWithObjectEncoder:(PFEncoder *)objectEncoder {
    NSMutableArray *encodedObjects = [objectEncoder encodeObject:self.objects];
    return @{ @"__op" : @"AddUnique",
              @"objects" : encodedObjects };
}

- (PFFieldOperation *)mergeWithPrevious:(PFFieldOperation *)previous {
    if (!previous) {
        return self;
    } else if ([previous isKindOfClass:[PFDeleteOperation class]]) {
        return [PFSetOperation setWithValue:self.objects];
    } else if ([previous isKindOfClass:[PFSetOperation class]]) {
        if ([((PFSetOperation *)previous).value isKindOfClass:[NSArray class]]) {
            NSArray *oldArray = (((PFSetOperation *)previous).value);
            return [PFSetOperation setWithValue:[self applyToValue:oldArray forKey:nil]];
        } else {
            [NSException raise:NSInternalInconsistencyException format:@"You can't add an item to a non-array."];
            return nil;
        }
    } else if ([previous isKindOfClass:[PFAddUniqueOperation class]]) {
        NSArray *previousObjects = ((PFAddUniqueOperation *)previous).objects;
        return [[self class] addUniqueWithObjects:[self applyToValue:previousObjects forKey:nil]];
    }
    [NSException raise:NSInternalInconsistencyException format:@"Operation is invalid after previous operation."];
    return nil;
}

- (id)applyToValue:(id)oldValue forKey:(NSString *)key {
    if (!oldValue) {
        return [self.objects mutableCopy];
    } else if ([oldValue isKindOfClass:[NSArray class]]) {
        NSMutableArray *newValue = [oldValue mutableCopy];
        for (id objectToAdd in self.objects) {
            if ([objectToAdd isKindOfClass:[PFObject class]] && [objectToAdd objectId]) {
                // Check uniqueness by objectId instead of equality. If the PFObject
                // already exists in the array, replace it with the newer one.
                NSUInteger index = [newValue indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    return [obj isKindOfClass:[PFObject class]] &&
                    [[obj objectId] isEqualToString:[objectToAdd objectId]];
                }];
                if (index == NSNotFound) {
                    [newValue addObject:objectToAdd];
                } else {
                    [newValue replaceObjectAtIndex:index withObject:objectToAdd];
                }
            } else if (![newValue containsObject:objectToAdd]) {
                [newValue addObject:objectToAdd];
            }
        }
        return newValue;
    }
    [NSException raise:NSInternalInconsistencyException format:@"Operation is invalid after previous operation."];
    return nil;
}

@end

@implementation PFRemoveOperation

- (instancetype)initWithObjects:(NSArray *)array {
    self = [super init];

    _objects = array;

    return self;
}

+ (id)removeWithObjects:(NSArray *)objects {
    return [(PFRemoveOperation *)[self alloc] initWithObjects:objects];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"remove %@", self.objects];
}

- (id)encodeWithObjectEncoder:(PFEncoder *)objectEncoder {
    NSMutableArray *encodedObjects = [objectEncoder encodeObject:self.objects];
    return @{ @"__op" : @"Remove",
              @"objects" : encodedObjects };
}

- (PFFieldOperation *)mergeWithPrevious:(PFFieldOperation *)previous {
    if (!previous) {
        return self;
    } else if ([previous isKindOfClass:[PFDeleteOperation class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"You can't remove items from a deleted array."];
        return nil;
    } else if ([previous isKindOfClass:[PFSetOperation class]]) {
        if ([((PFSetOperation *)previous).value isKindOfClass:[NSArray class]]) {
            NSArray *oldArray = ((PFSetOperation *)previous).value;
            return [PFSetOperation setWithValue:[self applyToValue:oldArray forKey:nil]];
        } else {
            [NSException raise:NSInternalInconsistencyException format:@"You can't add an item to a non-array."];
            return nil;
        }
    } else if ([previous isKindOfClass:[PFRemoveOperation class]]) {
        NSArray *newObjects = [((PFRemoveOperation *)previous).objects arrayByAddingObjectsFromArray:self.objects];
        return [PFRemoveOperation removeWithObjects:newObjects];
    }

    [NSException raise:NSInternalInconsistencyException format:@"Operation is invalid after previous operation."];
    return nil;
}

- (id)applyToValue:(id)oldValue forKey:(NSString *)key {
    if (!oldValue) {
        return [self.objects mutableCopy];
    } else if ([oldValue isKindOfClass:[NSArray class]]) {
        NSMutableArray *newValue = [((NSArray *)oldValue)mutableCopy];
        [newValue removeObjectsInArray:self.objects];

        // Remove the removed objects from objectsToBeRemoved -- the items
        // remaining should be ones that weren't removed by object equality.
        NSMutableArray *objectsToBeRemoved = [self.objects mutableCopy];
        [objectsToBeRemoved removeObjectsInArray:newValue];
        for (id objectToRemove in objectsToBeRemoved) {
            if ([objectToRemove isKindOfClass:[PFObject class]] && [objectToRemove objectId]) {
                NSIndexSet *indexes = [newValue indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                    return ([obj isKindOfClass:[PFObject class]] &&
                            [[obj objectId] isEqualToString:[objectToRemove objectId]]);
                }];
                if ([indexes count] != 0) {
                    [newValue removeObjectsAtIndexes:indexes];
                }
            }
        }
        return newValue;
    }
    [NSException raise:NSInternalInconsistencyException format:@"Operation is invalid after previous operation."];
    return nil;
}

@end

///--------------------------------------
#pragma mark - Relation Operations
///--------------------------------------

@implementation PFRelationOperation
@synthesize targetClass;

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _relationsToAdd = [NSMutableSet set];
    _relationsToRemove = [NSMutableSet set];

    return self;
}

+ (instancetype)addRelationToObjects:(NSArray *)targets {
    PFRelationOperation *op = [[self alloc] init];
    if (targets.count > 0) {
        op.targetClass = [[targets firstObject] parseClassName];
    }

    for (PFObject *target in targets) {
        PFParameterAssert([target.parseClassName isEqualToString:op.targetClass],
                          @"All objects in a relation must be of the same class.");
        [op.relationsToAdd addObject:target];
    }

    return op;
}

+ (instancetype)removeRelationToObjects:(NSArray *)targets {
    PFRelationOperation *operation = [[self alloc] init];
    if (targets.count > 0) {
        operation.targetClass = [targets[0] parseClassName];
    }

    for (PFObject *target in targets) {
        PFParameterAssert([target.parseClassName isEqualToString:operation.targetClass],
                          @"All objects in a relation must be of the same class.");
        [operation.relationsToRemove addObject:target];
    }

    return operation;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"PFRelationOperation<%@> add:%@ remove:%@",
            self.targetClass,
            self.relationsToAdd,
            self.relationsToRemove];
}

- (NSArray *)_convertToArrayInSet:(NSSet *)set withObjectEncoder:(PFEncoder *)objectEncoder {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:set.count];
    for (PFObject *object in set) {
        id encodedDict = [objectEncoder encodeObject:object];
        [array addObject:encodedDict];
    }
    return array;
}

- (id)encodeWithObjectEncoder:(PFEncoder *)objectEncoder {
    NSDictionary *addDict = nil;
    NSDictionary *removeDict = nil;
    if (self.relationsToAdd.count > 0) {
        NSArray *array = [self _convertToArrayInSet:self.relationsToAdd withObjectEncoder:objectEncoder];
        addDict = @{ @"__op" : @"AddRelation",
                     @"objects" : array };
    }
    if (self.relationsToRemove.count > 0) {
        NSArray *array = [self _convertToArrayInSet:self.relationsToRemove withObjectEncoder:objectEncoder];
        removeDict = @{ @"__op" : @"RemoveRelation",
                        @"objects" : array };
    }

    if (addDict && removeDict) {
        return @{ @"__op" : @"Batch",
                  @"ops" : @[ addDict, removeDict ] };
    }

    if (addDict) {
        return addDict;
    }

    if (removeDict) {
        return removeDict;
    }

    [NSException raise:NSInternalInconsistencyException format:@"A PFRelationOperation was created without any data."];
    return nil;
}

- (PFFieldOperation *)mergeWithPrevious:(PFFieldOperation *)previous {
    if (!previous) {
        return self;
    }

    PFConsistencyAssert(![previous isKindOfClass:[PFDeleteOperation class]], @"You can't modify a relation after deleting it");
    PFConsistencyAssert([previous isKindOfClass:[PFRelationOperation class]], @"Operation is invalid after previous operation");

    PFRelationOperation *previousOperation = (PFRelationOperation *)previous;

    PFParameterAssert(!previousOperation.targetClass || [previousOperation.targetClass isEqualToString:self.targetClass],
                      @"Related object object must be of class %@, but %@ was passed in",
                      previousOperation.targetClass, self.targetClass);

    //TODO: (nlutsenko) This logic seems to be messed up. We should return a new operation here, also merging logic seems funky.
    NSSet *newRelationsToAdd = [self.relationsToAdd copy];
    NSSet *newRelationsToRemove = [self.relationsToRemove copy];
    [self.relationsToAdd removeAllObjects];
    [self.relationsToRemove removeAllObjects];

    for (NSString *objectId in previousOperation.relationsToAdd) {
        [self.relationsToRemove removeObject:objectId];
        [self.relationsToAdd addObject:objectId];
    }
    for (NSString *objectId in previousOperation.relationsToRemove) {
        [self.relationsToRemove removeObject:objectId];
        [self.relationsToRemove addObject:objectId];
    }

    for (NSString *objectId in newRelationsToAdd) {
        [self.relationsToRemove removeObject:objectId];
        [self.relationsToAdd addObject:objectId];
    }
    for (NSString *objectId in newRelationsToRemove) {
        [self.relationsToRemove removeObject:objectId];
        [self.relationsToRemove addObject:objectId];
    }
    return self;
}

- (id)applyToValue:(id)oldValue forKey:(NSString *)key {
    PFRelation *relation = nil;
    if (!oldValue) {
        relation = [PFRelation relationWithTargetClass:self.targetClass];
    } else if ([oldValue isKindOfClass:[PFRelation class]]) {
        relation = oldValue;
        if (self.targetClass) {
            if (relation.targetClass) {
                PFParameterAssert([relation.targetClass isEqualToString:targetClass],
                                  @"Related object object must be of class %@, but %@ was passed in",
                                  relation.targetClass, self.targetClass);
            } else {
                relation.targetClass = self.targetClass;
            }
        }
    } else {
        [NSException raise:NSInternalInconsistencyException format:@"Operation is invalid after previous operation."];
        return nil;
    }

    for (PFObject *object in self.relationsToAdd) {
        [relation _addKnownObject:object];
    }
    for (PFObject *object in self.relationsToRemove) {
        [relation _removeKnownObject:object];
    }

    return relation;
}

@end
