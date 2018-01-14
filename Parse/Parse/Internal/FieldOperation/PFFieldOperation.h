/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFEncoder.h"

@class PFDecoder;
@class PFObject;

///--------------------------------------
#pragma mark - PFFieldOperation
///--------------------------------------

/**
 A PFFieldOperation represents a modification to a value in a PFObject.
 For example, setting, deleting, or incrementing a value are all different
 kinds of PFFieldOperations. PFFieldOperations themselves can be considered
 to be immutable.
 */
@interface PFFieldOperation : NSObject

/**
 Converts the PFFieldOperation to a data structure (typically an NSDictionary)
 that can be converted to JSON and sent to Parse as part of a save operation.

 @param objectEncoder encoder that will be used to encode the object.
 @return An object to be jsonified.
 */
- (id)encodeWithObjectEncoder:(PFEncoder *)objectEncoder;

/**
 Returns a field operation that is composed of a previous operation followed by
 this operation. This will not mutate either operation. However, it may return
 self if the current operation is not affected by previous changes. For example:
 [{increment by 2} mergeWithPrevious:{set to 5}] -> {set to 7}
 [{set to 5} mergeWithPrevious:{increment by 2}] -> {set to 5}
 [{add "foo"} mergeWithPrevious:{delete}] -> {set to ["foo"]}
 [{delete} mergeWithPrevious:{add "foo"}] -> {delete}

 @param previous The most recent operation on the field, or nil if none.
 @return A new PFFieldOperation or self.
 */
- (PFFieldOperation *)mergeWithPrevious:(PFFieldOperation *)previous;

/**
 Returns a new estimated value based on a previous value and this operation. This
 value is not intended to be sent to Parse, but it used locally on the client to
 inspect the most likely current value for a field.

 The key and object are used solely for PFRelation to be able to construct objects
 that refer back to its parent.

 @param oldValue The previous value for the field.
 @param key The key that this value is for.

 @return The new value for the field.
 */
- (id)applyToValue:(id)oldValue forKey:(NSString *)key;

@end

///--------------------------------------
#pragma mark - Independent Operations
///--------------------------------------

/**
 An operation where a field is set to a given value regardless of
 its previous value.
 */
@interface PFSetOperation : PFFieldOperation

@property (nonatomic, strong, readonly) id value;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithValue:(id)value NS_DESIGNATED_INITIALIZER;
+ (instancetype)setWithValue:(id)value;

@end

/**
 An operation where a field is deleted from the object.
 */
@interface PFDeleteOperation : PFFieldOperation

+ (instancetype)operation;

@end

///--------------------------------------
#pragma mark - Numeric Operations
///--------------------------------------

/**
 An operation that increases a numeric field's value by a given amount.
 */
@interface PFIncrementOperation : PFFieldOperation

@property (nonatomic, strong, readonly) NSNumber *amount;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAmount:(NSNumber *)amount NS_DESIGNATED_INITIALIZER;
+ (instancetype)incrementWithAmount:(NSNumber *)amount;

@end

///--------------------------------------
#pragma mark - Array Operations
///--------------------------------------

/**
 An operation that adds a new element to an array field.
 */
@interface PFAddOperation : PFFieldOperation

@property (nonatomic, strong, readonly) NSArray *objects;

+ (instancetype)addWithObjects:(NSArray *)array;

@end

/**
 An operation that adds a new element to an array field,
 only if it wasn't already present.
 */
@interface PFAddUniqueOperation : PFFieldOperation

@property (nonatomic, strong, readonly) NSArray *objects;

+ (instancetype)addUniqueWithObjects:(NSArray *)array;

@end

/**
 An operation that removes every instance of an element from
 an array field.
 */
@interface PFRemoveOperation : PFFieldOperation

@property (nonatomic, strong, readonly) NSArray *objects;

+ (instancetype)removeWithObjects:(NSArray *)array;

@end

///--------------------------------------
#pragma mark - Relation Operations
///--------------------------------------

/**
 An operation where a PFRelation's value is modified.
 */
@interface PFRelationOperation : PFFieldOperation

@property (nonatomic, copy) NSString *targetClass;
@property (nonatomic, strong) NSMutableSet *relationsToAdd;
@property (nonatomic, strong) NSMutableSet *relationsToRemove;

+ (instancetype)addRelationToObjects:(NSArray *)targets;
+ (instancetype)removeRelationToObjects:(NSArray *)targets;

@end
