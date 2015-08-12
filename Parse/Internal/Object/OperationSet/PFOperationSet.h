/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class PFDecoder;
@class PFEncoder;
@class PFFieldOperation;

/*!
 A set of field-level operations that can be performed on an object, corresponding to one
 command. For example, all the data for a single call to save() will be packaged here. It is
 assumed that the PFObject that owns the operations handles thread-safety.
 */
@interface PFOperationSet : NSObject <NSCopying, NSFastEnumeration>

/*!
 Returns true if this set corresponds to a call to saveEventually.
 */
@property (nonatomic, assign, getter=isSaveEventually) BOOL saveEventually;

/*!
 A unique id for this operation set.
 */
@property (nonatomic, copy, readonly) NSString *uuid;

@property (nonatomic, copy) NSDate *updatedAt;

/*!
 Merges the changes from the given operation set into this one. Most typically, this is what
 happens when a save fails and changes need to be rolled into the next save.
 */
- (void)mergeOperationSet:(PFOperationSet *)other;

/*!
 Converts this operation set into its REST format for serializing to the pinning store
 */
- (NSDictionary *)RESTDictionaryUsingObjectEncoder:(PFEncoder *)objectEncoder
                                 operationSetUUIDs:(NSArray **)operationSetUUIDs;

/*!
 The inverse of RESTDictionaryUsingObjectEncoder.
 Creates a new OperationSet from the given NSDictionary
 */
+ (PFOperationSet *)operationSetFromRESTDictionary:(NSDictionary *)data
                                      usingDecoder:(PFDecoder *)decoder;

///--------------------------------------
/// @name Accessors
///--------------------------------------

- (id)objectForKey:(id)aKey;
- (id)objectForKeyedSubscript:(id)aKey;
- (NSUInteger)count;
- (NSEnumerator *)keyEnumerator;

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(NSString *key, PFFieldOperation *operation, BOOL *stop))block;

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)aKey;
- (void)removeObjectForKey:(id)aKey;

@end
