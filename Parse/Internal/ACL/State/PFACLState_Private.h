/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFACLState.h"

#import "PFMacros.h"

/**
 Returns NSString representation of a property on PFACLState

 @param NAME The name of the property.

 @return NSString representaiton of a given property.
 */
#define PFACLStatePropertyName(NAME) @keypath(PFACLState, NAME)

@interface PFACLState () {
@protected
    NSDictionary<NSString *, id> *_permissions;
    BOOL _shared;
}

@property (nonatomic, copy, readwrite) NSDictionary<NSString *, id> *permissions;
@property (nonatomic, assign, readwrite, getter=isShared) BOOL shared;

@end
