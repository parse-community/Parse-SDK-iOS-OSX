/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPropertyInfo.h"

#import <objc/runtime.h>

/**
 Safely sets an object's instance variable to the variable in the specified address.
 The Objective-C runtime's built-in methods for setting instance variables (`object_setIvar`) and
 (`object_setInstanceVariable`), are both terrible. They never read any more than a single pointer, so they
 fail for structs, as well as 64 bit numbers on 32 bit platforms. Because of this, we need a solution to allow us to
 safely set instance variable values whose sizes may be significantly more than a pointer.
 
 @note Like most Objective-C runtime methods, this WILL fail if you try and set a bitfield, so please don't do that.

 @param obj             The object to operate on.
 @param ivar            The ivar to set the new value for.
 @param fromMemory      The **address** of the new value to set.
 @param associationType The association type of the new value. One of <code>PFPropertyInfoAssociationType</code>.
 */
extern void object_setIvarValue_safe(__unsafe_unretained id obj, Ivar ivar, void *fromMemory, uint8_t associationType);

/**
 Safely gets an object's instance variable and puts it into the specified address.
  The Objective-C runtime's built-in methods for getting instance variables (`object_getIvar`) and
 (`object_getInstanceVariable`), are both terrible. They never read any more than a single pointer, so they
 fail for structs, as well as 64 bit numbers on 32 bit platforms. Because of this, we need a solution to allow us to
 safely get instance variable values whose sizes may be significantly more than a pointer.

 @note Like most Objective-C runtime methods, this WILL fail if you try and set a bitfield, so please don't do that.

 @param obj             The object to operate on.
 @param ivar            The ivar to get the value from.
 @param toMemory        The address to copy the value into.
 @param associationType The assocation type of the new value. One of <code>PFPrropertyInfoAssocationType</code>.
 */
extern void object_getIvarValue_safe(__unsafe_unretained id obj, Ivar ivar, void *toMemory, uint8_t associationType);
