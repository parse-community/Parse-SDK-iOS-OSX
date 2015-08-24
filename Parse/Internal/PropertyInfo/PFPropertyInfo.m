/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPropertyInfo_Private.h"

#import <objc/message.h>

#import "PFAssert.h"
#import "PFMacros.h"
#import "PFPropertyInfo_Runtime.h"

static inline NSString *safeStringWithPropertyAttributeValue(objc_property_t property, const char *attribute) {
    char *value = property_copyAttributeValue(property, attribute);
    if (!value)
        return nil;

    // NSString initWithBytesNoCopy doesn't seem to work, so fall back to the CF counterpart.
    return (__bridge_transfer NSString *)CFStringCreateWithCStringNoCopy(NULL,
                                                                         value,
                                                                         kCFStringEncodingUTF8,
                                                                         kCFAllocatorMalloc);
}

static inline NSString *stringByCapitalizingFirstCharacter(NSString *string) {
    return [NSString stringWithFormat:@"%C%@",
            (unichar)toupper([string characterAtIndex:0]),
            [string substringFromIndex:1]];
}

@implementation PFPropertyInfo

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithClass:(Class)kls name:(NSString *)propertyName {
    return [self initWithClass:kls name:propertyName associationType:_associationType];
}

- (instancetype)initWithClass:(Class)kls name:(NSString *)propertyName
              associationType:(PFPropertyInfoAssociationType)associationType {
    self = [super init];
    if (!self) return nil;

    _sourceClass = kls;
    _name = [propertyName copy];
    _associationType = associationType;

    objc_property_t objcProperty = class_getProperty(kls, [_name UTF8String]);

    do {
        _ivar = class_getInstanceVariable(kls, [safeStringWithPropertyAttributeValue(objcProperty, "V") UTF8String]);
        if (_ivar) break;

        // Walk the superclass heirarchy for the property definition. Because property attributes are not inherited
        // (but property definitions *are*), we must be careful to ensure that the variable was never actually
        // implemented and synthesized in a superclass. Note if the same property is synthesized in multiple classes
        // with different iVars, we take the class furthest from the root class as the 'source of truth'.
        Class superClass = class_getSuperclass(kls);
        while (superClass) {
            objc_property_t superProperty = class_getProperty(superClass, [_name UTF8String]);
            if (!superProperty) break;

            _ivar = class_getInstanceVariable(superClass, [safeStringWithPropertyAttributeValue(superProperty, "V") UTF8String]);
            if (_ivar) break;

            superClass = class_getSuperclass(superClass);
        }

        if (_ivar) break;

        // Attempt to infer the variable name.
        _ivar = class_getInstanceVariable(kls, [[@"_" stringByAppendingString:_name] UTF8String]);
        if (_ivar) break;

        _ivar = class_getInstanceVariable(kls, [_name UTF8String]);
    } while (0);

    _typeEncoding = safeStringWithPropertyAttributeValue(objcProperty, "T");
    _object = [_typeEncoding hasPrefix:@"@"];

    NSString *propertyGetter = safeStringWithPropertyAttributeValue(objcProperty, "G") ?: _name;
    _getterSelector = NSSelectorFromString(propertyGetter);

    BOOL readonly = safeStringWithPropertyAttributeValue(objcProperty, "R") != nil;
    NSString *propertySetter = safeStringWithPropertyAttributeValue(objcProperty, "S");
    if (propertySetter == nil && !readonly) {
        propertySetter = [NSString stringWithFormat:@"set%@:", stringByCapitalizingFirstCharacter(_name)];
    }

    _setterSelector = NSSelectorFromString(propertySetter);

    if (_associationType == PFPropertyInfoAssociationTypeDefault) {
        BOOL isCopy = safeStringWithPropertyAttributeValue(objcProperty, "C") != nil;
        BOOL isWeak = safeStringWithPropertyAttributeValue(objcProperty, "W") != nil;
        BOOL isRetain = safeStringWithPropertyAttributeValue(objcProperty, "&") != nil;

        if (isWeak) {
            _associationType = PFPropertyInfoAssociationTypeWeak;
        } else if (isCopy) {
            _associationType = PFPropertyInfoAssociationTypeCopy;
        } else if (isRetain) {
            _associationType = PFPropertyInfoAssociationTypeStrong;
        } else {
            _associationType = PFPropertyInfoAssociationTypeAssign;
        }
    }

    return self;
}

+ (instancetype)propertyInfoWithClass:(Class)kls name:(NSString *)propertyName {
    return [[self alloc] initWithClass:kls name:propertyName];
}

+ (instancetype)propertyInfoWithClass:(Class)kls name:(NSString *)propertyName
                      associationType:(PFPropertyInfoAssociationType)associationType {
    return [[self alloc] initWithClass:kls name:propertyName associationType:associationType];
}

///--------------------------------------
#pragma mark - Wrapping
///--------------------------------------

- (id)getWrappedValueFrom:(id)object {
    if (self.object) {
        return objc_msgSend_safe(id)(object, self.getterSelector);
    }

    return [object valueForKey:self.name];
}

- (void)setWrappedValue:(id)value forObject:(id)object {
    if (self.object && self.setterSelector) {
        objc_msgSend_safe(void, id)(object, self.setterSelector, value);
        return;
    }

    [object setValue:value forKey:self.name];
}

///--------------------------------------
#pragma mark - Taking
///--------------------------------------

- (void)takeValueFrom:(id)one toObject:(id)two {
    if (!self.ivar) {
        id wrappedValue = [self getWrappedValueFrom:one];
        [self setWrappedValue:wrappedValue forObject:two];

        return;
    }

    NSUInteger size = 0;
    NSGetSizeAndAlignment(ivar_getTypeEncoding(self.ivar), &size, NULL);

    char valuePtr[size];
    bzero(valuePtr, size);

    NSInvocation *invocation = nil;

    // TODO: (richardross) Cache the method signatures, as those are fairly slow to calculate.
    if (one && [one respondsToSelector:self.getterSelector]) {
        NSMethodSignature *methodSignature = [one methodSignatureForSelector:self.getterSelector];
        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];

        [invocation setTarget:one];
        [invocation setSelector:self.getterSelector];
    }

    [invocation invoke];
    [invocation getReturnValue:valuePtr];

    object_setIvarValue_safe(two, self.ivar, valuePtr, self.associationType);
}

///--------------------------------------
#pragma mark - Equality
///--------------------------------------

- (NSUInteger)hash {
    return 0;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    PFPropertyInfo *other = object;

    // If they're the same property and one of them subclasses the other, do no further checking.
    return [self.name isEqual:other.name] &&
    ([self.sourceClass isSubclassOfClass:other.sourceClass] ||
     [other.sourceClass isSubclassOfClass:self.sourceClass]);
}

@end
