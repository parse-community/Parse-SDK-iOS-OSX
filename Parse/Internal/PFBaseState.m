/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFBaseState.h"

#import <objc/message.h>
#import <objc/runtime.h>

#import "PFAssert.h"
#import "PFHash.h"
#import "PFMacros.h"
#import "PFPropertyInfo.h"

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

@implementation PFPropertyAttributes

- (instancetype)init {
    return [self initWithAssociationType:PFPropertyInfoAssociationTypeDefault];
}

- (instancetype)initWithAssociationType:(PFPropertyInfoAssociationType)associationType {
    self = [super init];
    if (!self) return nil;

    _associationType = associationType;

    return self;
}

+ (instancetype)attributes {
    return [[self alloc] init];
}

+ (instancetype)attributesWithAssociationType:(PFPropertyInfoAssociationType)associationType {
    return [[self alloc] initWithAssociationType:associationType];
}

@end

@interface PFBaseState () {
    BOOL _initializing;
}

@end

@implementation PFBaseState

///--------------------------------------
#pragma mark - Property Info
///--------------------------------------

+ (NSSet *)_propertyInfo {
    static void *_propertyMapKey = &_propertyMapKey;
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.parse.basestate.propertyinfo", DISPATCH_QUEUE_SERIAL);
    });

    __block NSMutableSet *results = nil;
    dispatch_sync(queue, ^{
        results = objc_getAssociatedObject(self, _propertyMapKey);
        if (results) {
            return;
        }

        NSDictionary *attributesMap = [(id<PFBaseStateSubclass>)self propertyAttributes];
        results = [[NSMutableSet alloc] initWithCapacity:attributesMap.count];

        [attributesMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [results addObject:[PFPropertyInfo propertyInfoWithClass:self
                                                                name:key
                                                     associationType:[obj associationType]]];
        }];

        objc_setAssociatedObject(self, _propertyMapKey, results, OBJC_ASSOCIATION_RETAIN);
    });

    return results;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    // To prevent a recursive init function.
    if (_initializing) {
        return [super init];
    }

    _initializing = YES;
    return [self initWithState:nil];
}

- (instancetype)initWithState:(id)otherState {
    if (!_initializing) {
        _initializing = YES;

        self = [self init];
        if (!self) return nil;
    }

    NSSet *ourProperties = [[self class] _propertyInfo];
    NSSet *theirProperties = [[otherState class] _propertyInfo];

    NSMutableSet *shared = [ourProperties mutableCopy];
    [shared intersectSet:theirProperties];

    for (PFPropertyInfo *property in shared) {
        [property takeValueFrom:otherState toObject:self];
    }

    return self;
}

+ (instancetype)stateWithState:(PFBaseState *)otherState {
    return [[self alloc] initWithState:otherState];
}

///--------------------------------------
#pragma mark - Hashing
///--------------------------------------

- (NSUInteger)hash {
    NSUInteger result = 0;

    for (PFPropertyInfo *property in [[self class] _propertyInfo]) {
        result = PFIntegerPairHash(result, [[property getWrappedValueFrom:self] hash]);
    }

    return result;
}

///--------------------------------------
#pragma mark - Comparison
///--------------------------------------

- (NSComparisonResult)compare:(PFBaseState *)other {
    PFParameterAssert([other isKindOfClass:[PFBaseState class]],
                      @"Cannot compatre to an object that isn't a PFBaseState");

    NSSet *ourProperties = [[self class] _propertyInfo];
    NSSet *theirProperties = [[other class] _propertyInfo];

    NSMutableSet *shared = [ourProperties mutableCopy];
    [shared intersectSet:theirProperties];

    for (PFPropertyInfo *info in shared) {
        id ourValue = [info getWrappedValueFrom:self];
        id theirValue = [info getWrappedValueFrom:other];

        if (![ourValue respondsToSelector:@selector(compare:)]) {
            continue;
        }

        NSComparisonResult result = [ourValue compare:theirValue];
        if (result != NSOrderedSame) {
            return result;
        }
    }

    return NSOrderedSame;
}

///--------------------------------------
#pragma mark - Equality
///--------------------------------------

- (BOOL)isEqual:(id)other {
    if (self == other) {
        return YES;
    }

    if (![other isKindOfClass:[PFBaseState class]]) {
        return NO;
    }

    NSSet *ourProperties = [[self class] _propertyInfo];
    NSSet *theirProperties = [[other class] _propertyInfo];

    NSMutableSet *shared = [ourProperties mutableCopy];
    [shared intersectSet:theirProperties];

    for (PFPropertyInfo *info in shared) {
        id ourValue = [info getWrappedValueFrom:self];
        id theirValue = [info getWrappedValueFrom:other];

        if (ourValue != theirValue && ![ourValue isEqual:theirValue]) {
            return NO;
        }
    }

    return YES;
}

///--------------------------------------
#pragma mark - Description
///--------------------------------------

// This allows us to easily use the same implementation for description and debugDescription
- (NSString *)descriptionWithValueSelector:(SEL)toPerform {
    NSMutableString *results = [NSMutableString stringWithFormat:@"<%@: %p", [self class], self];

    for (PFPropertyInfo *property in [[self class] _propertyInfo]) {
        id propertyValue = [property getWrappedValueFrom:self];
        NSString *propertyDescription = objc_msgSend_safe(NSString *)(propertyValue, toPerform);

        [results appendFormat:@", %@: %@", property.name, propertyDescription];
    }

    [results appendString:@">"];
    return results;
}

- (NSString *)description {
    return [self descriptionWithValueSelector:_cmd];
}

- (NSString *)debugDescription {
    return [self descriptionWithValueSelector:_cmd];
}

///--------------------------------------
#pragma mark - Dictionary/QuickLook representation
///--------------------------------------

- (id)nilValueForProperty:(NSString *)propertyName {
    return [NSNull null];
}

// Implementation detail - this returns a mutable dictionary with mutable leaves.
- (NSDictionary *)dictionaryRepresentation {
    NSSet *properties = [[self class] _propertyInfo];
    NSMutableDictionary *results = [[NSMutableDictionary alloc] initWithCapacity:properties.count];

    for (PFPropertyInfo *info in properties) {
        id value = [info getWrappedValueFrom:self];

        if (value == nil) {
            value = [self nilValueForProperty:info.name];

            if (value == nil) {
                continue;
            }
        }

        results[info.name] = value;
    }

    return results;
}

- (id)debugQuickLookObject {
    return [self dictionaryRepresentation].description;
}

@end
