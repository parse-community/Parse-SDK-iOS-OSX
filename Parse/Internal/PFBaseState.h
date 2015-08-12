/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint8_t, PFPropertyInfoAssociationType) {
    PFPropertyInfoAssociationTypeDefault, // Assign for c-types, strong for objc-types.
    PFPropertyInfoAssociationTypeAssign,
    PFPropertyInfoAssociationTypeStrong,
    PFPropertyInfoAssociationTypeWeak,
    PFPropertyInfoAssociationTypeCopy,
    PFPropertyInfoAssociationTypeMutableCopy,
};

@interface PFPropertyAttributes : NSObject

@property (nonatomic, assign, readonly) PFPropertyInfoAssociationType associationType;

- (instancetype)initWithAssociationType:(PFPropertyInfoAssociationType)associationType NS_DESIGNATED_INITIALIZER;

+ (instancetype)attributes;
+ (instancetype)attributesWithAssociationType:(PFPropertyInfoAssociationType)associationType;

@end

@protocol PFBaseStateSubclass <NSObject>

/*!
 This is the list of properties that should be used automatically for the methods implemented by PFBaseState.

 It should be a dictionary in the format of @{ @"<#property name#>": [PFPropertyAttributes attributes] }
 This will be automatically cached by PFBaseState, no need for you to cache it yourself.

 @return a dictionary of property attributes
 */
+ (NSDictionary *)propertyAttributes;

@end

/*!
 Shared base class for all state objects.
 Implements -init, -description, -debugDescription, -hash, -isEqual:, -compareTo:, etc. for you.
 */
@interface PFBaseState : NSObject

- (instancetype)initWithState:(PFBaseState *)otherState;
+ (instancetype)stateWithState:(PFBaseState *)otherState;

- (NSComparisonResult)compare:(PFBaseState *)other;

/*!
 Returns a dictionary representation of this object.

 Essentially, it takes the values for the keys of this object, and stuffs them in the dictionary.
 It will call -dictionaryRepresentation on any objects it contains, in order to handle base states
 contained in this base state.

 If a value is `nil`, it will be replaced with [NSNull null], to ensure all keys exist in the dictionary.

 If you don't like this behavior, you can overwrite the method
 -nilValueForProperty:(NSString *) property
 to return either nil to skip the key, or a value to use in it's place.

 @return A dictionary representation of this object state.
 */
- (NSDictionary *)dictionaryRepresentation;

- (id)debugQuickLookObject;

@end
