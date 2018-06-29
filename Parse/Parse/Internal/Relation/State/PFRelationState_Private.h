/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRelationState.h"

#import "PFMacros.h"

/**
 Returns NSString representation of a property.

 @param NAME The name of the property.

 @return NSString representation of a given property.
 */
#define PFRelationStatePropertyName(NAME) @keypath(PFRelationState, NAME)

@interface PFRelationState() {
@protected
    __weak PFObject *_parent;
    NSString *_parentClassName;
    NSString *_parentObjectId;
    NSSet *_knownObjects;
    NSString *_key;
}

@property (nonatomic, weak, readwrite) PFObject *parent;
@property (nonatomic, copy, readwrite) NSString *parentClassName;
@property (nonatomic, copy, readwrite) NSString *parentObjectId;
@property (nonatomic, copy, readwrite) NSString *targetClass;
@property (nonatomic, copy, readwrite) NSSet *knownObjects;
@property (nonatomic, copy, readwrite) NSString *key;

@end
