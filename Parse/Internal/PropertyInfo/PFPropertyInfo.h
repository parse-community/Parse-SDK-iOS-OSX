/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFBaseState.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFPropertyInfo : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithClass:(Class)kls
                         name:(NSString *)propertyName;

- (instancetype)initWithClass:(Class)kls
                         name:(NSString *)propertyName
              associationType:(PFPropertyInfoAssociationType)associationType NS_DESIGNATED_INITIALIZER;

+ (instancetype)propertyInfoWithClass:(Class)kls
                                 name:(NSString *)propertyName;

+ (instancetype)propertyInfoWithClass:(Class)kls
                                 name:(NSString *)propertyName
                      associationType:(PFPropertyInfoAssociationType)associationType;

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, readonly) PFPropertyInfoAssociationType associationType;

/*!
 Returns the value of this property,
 properly wrapped from the target object.
 When possible, just invokes the property.
 When not, uses -valueForKey:.
 */
- (nullable id)getWrappedValueFrom:(id)object;
- (void)setWrappedValue:(nullable id)value forObject:(id)object;

// Moves the value from one object to the other, based on the association type given.
- (void)takeValueFrom:(id)one toObject:(id)two;

@end

NS_ASSUME_NONNULL_END
