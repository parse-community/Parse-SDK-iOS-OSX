/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFObject.h"
#import "PFQuery.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The `PFRelation` class that is used to access all of the children of a many-to-many relationship.
 Each instance of `PFRelation` is associated with a particular parent object and key.
 */
@interface PFRelation<ObjectType : PFObject *> : NSObject

/**
 The name of the class of the target child objects.
 */
@property (nullable, nonatomic, copy) NSString *targetClass;

///--------------------------------------
#pragma mark - Accessing Objects
///--------------------------------------

/**
 Returns a `PFQuery` object that can be used to get objects in this relation.
 */
- (PFQuery<ObjectType> *)query;

///--------------------------------------
#pragma mark - Modifying Relations
///--------------------------------------

/**
 Adds a relation to the passed in object.

 @param object A `PFObject` object to add relation to.
 */
- (void)addObject:(ObjectType)object;

/**
 Removes a relation to the passed in object.

 @param object A `PFObject` object to add relation to.
 */
- (void)removeObject:(ObjectType)object;

@end

NS_ASSUME_NONNULL_END
