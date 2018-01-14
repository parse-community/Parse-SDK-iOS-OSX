/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectSubclassingController.h"

#import <objc/runtime.h>

#import <Parse/PFObject.h>
#import <Parse/PFSubclassing.h>

#import "PFAssert.h"
#import "PFMacros.h"
#import "PFObject.h"
#import "PFObject+Subclass.h"
#import "PFObjectSubclassInfo.h"
#import "PFPropertyInfo_Private.h"
#import "PFPropertyInfo_Runtime.h"

// CFNumber does not use number type 0, we take advantage of that here.
#define kCFNumberTypeUnknown 0

static CFNumberType PFNumberTypeForObjCType(const char *encodedType) {
// To save anyone in the future from some major headaches, sanity check here.
#if kCFNumberTypeMax > UINT8_MAX
#error kCFNumberTypeMax has been changed! This solution will no longer work.
#endif

    // Organizing the table this way makes it nicely fit into two cache lines. This makes lookups nearly free, even more
    // so if repeated.
    static uint8_t types[128] = {
        // Core types.
        ['c'] = kCFNumberCharType,
        ['i'] = kCFNumberIntType,
        ['s'] = kCFNumberShortType,
        ['l'] = kCFNumberLongType,
        ['q'] = kCFNumberLongLongType,

        // CFNumber (and NSNumber, actually) does not store unsigned types.
        // This may cause some strange issues when dealing with values near the max for that type.
        // We should investigate this if it becomes a problem.
        ['C'] = kCFNumberCharType,
        ['I'] = kCFNumberIntType,
        ['S'] = kCFNumberShortType,
        ['L'] = kCFNumberLongType,
        ['Q'] = kCFNumberLongLongType,

        // Floating point
        ['f'] = kCFNumberFloatType,
        ['d'] = kCFNumberDoubleType,

        // C99 & CXX boolean. We are keeping this here for decoding, as you can safely use CFNumberGetBytes on a
        // CFBoolean, and extract it into a char.
        ['B'] = kCFNumberCharType,
    };

    return (CFNumberType)types[encodedType[0]];
}

static NSNumber *PFNumberCreateSafe(const char *typeEncoding, const void *bytes) {
    // NOTE: This is required because NSJSONSerialization treats all NSNumbers with the 'char' type as numbers, not
    // booleans. As such, we must treat any and all boolean type encodings as explicit booleans, otherwise we will
    // send '1' and '0' to the api server rather than 'true' and 'false'.
    //
    // TODO (richardross): When we drop support for 10.9/iOS 7, remove the 'c' encoding and only use the new 'B'
    // encoding.
    if (typeEncoding[0] == 'B' || typeEncoding[0] == 'c') {
        return [NSNumber numberWithBool:*(BOOL *)bytes];
    }

    CFNumberType numberType = PFNumberTypeForObjCType(typeEncoding);
    PFConsistencyAssert(numberType != kCFNumberTypeUnknown, @"Unsupported type encoding %s!", typeEncoding);
    return (__bridge_transfer NSNumber *)CFNumberCreate(NULL, numberType, bytes);
}

@implementation PFObjectSubclassingController {
    dispatch_queue_t _registeredSubclassesAccessQueue;
    NSMutableDictionary *_registeredSubclasses;
    NSMutableDictionary *_unregisteredSubclasses;
    id<NSObject> _bundleLoadedSubscriptionToken;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _registeredSubclassesAccessQueue = dispatch_queue_create("com.parse.object.subclassing", DISPATCH_QUEUE_SERIAL);
    _registeredSubclasses = [NSMutableDictionary dictionary];
    _unregisteredSubclasses = [NSMutableDictionary dictionary];

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:_bundleLoadedSubscriptionToken
                                                    name:NSBundleDidLoadNotification
                                                  object:nil];
}

///--------------------------------------
#pragma mark - Public
///--------------------------------------

- (Class<PFSubclassing>)subclassForParseClassName:(NSString *)parseClassName {
    __block Class result = nil;
    pf_sync_with_throw(_registeredSubclassesAccessQueue, ^{
        result = [_registeredSubclasses[parseClassName] subclass];
    });
    return result;
}

- (void)scanForUnregisteredSubclasses:(BOOL)shouldSubscribe {
    // NOTE: Potential race-condition here - if another thread dynamically loads a bundle, we may end up accidentally
    // Skipping a bundle. Not entirely sure of the best solution to that here.
    if (shouldSubscribe && _bundleLoadedSubscriptionToken == nil) {
        @weakify(self);
        _bundleLoadedSubscriptionToken = [[NSNotificationCenter defaultCenter] addObserverForName:NSBundleDidLoadNotification
                                                                                           object:nil
                                                                                            queue:nil
                                                                                       usingBlock:^(NSNotification *note) {
                                                                                           @strongify(self);
                                                                                           [self _registerSubclassesInLoadedBundle:note.object];
                                                                                       }];
    }
    NSArray *bundles = [[NSBundle allFrameworks] arrayByAddingObjectsFromArray:[NSBundle allBundles]];
    for (NSBundle *bundle in bundles) {
        [self _registerSubclassesInLoadedBundle:bundle];
    }
}

- (void)registerSubclass:(Class<PFSubclassing>)kls {
    pf_sync_with_throw(_registeredSubclassesAccessQueue, ^{
        [self _rawRegisterSubclass:kls];
    });
}

- (void)unregisterSubclass:(Class<PFSubclassing>)class {
    pf_sync_with_throw(_registeredSubclassesAccessQueue, ^{
        NSString *parseClassName = [class parseClassName];
        Class registeredClass = [_registeredSubclasses[parseClassName] subclass];

        // Make it a no-op if the class itself is not registered or
        // if there is another class registered under the same name.
        if (registeredClass == nil ||
            ![registeredClass isEqual:class]) {
            return;
        }

        [_registeredSubclasses removeObjectForKey:parseClassName];
    });
}

- (BOOL)forwardObjectInvocation:(NSInvocation *)invocation withObject:(PFObject<PFSubclassing> *)object {
    PFObjectSubclassInfo *subclassInfo = [self _subclassInfoForClass:[object class]];

    BOOL isSetter = NO;
    PFPropertyInfo *propertyInfo = [subclassInfo propertyInfoForSelector:invocation.selector isSetter:&isSetter];
    if (!propertyInfo) {
        return NO;
    }

    if (isSetter) {
        [self _forwardSetterInvocation:invocation forProperty:propertyInfo withObject:object];
    } else {
        [self _forwardGetterInvocation:invocation forProperty:propertyInfo withObject:object];
    }
    return YES;
}

- (NSMethodSignature *)forwardingMethodSignatureForSelector:(SEL)cmd ofClass:(Class<PFSubclassing>)kls {
    PFObjectSubclassInfo *subclassInfo = [self _subclassInfoForClass:kls];
    return [subclassInfo forwardingMethodSignatureForSelector:cmd];
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

- (void)_forwardGetterInvocation:(NSInvocation *)invocation
                     forProperty:(PFPropertyInfo *)propertyInfo
                      withObject:(PFObject *)object {
    PFConsistencyAssert(invocation.methodSignature.numberOfArguments == 2, @"Getter should take no arguments!");
    PFConsistencyAssert(invocation.methodSignature.methodReturnType[0] != 'v', @"A getter cannot return void!");

    const char *methodReturnType = invocation.methodSignature.methodReturnType;
    void *returnValueBytes = alloca(invocation.methodSignature.methodReturnLength);

    if (propertyInfo.ivar) {
        object_getIvarValue_safe(object, propertyInfo.ivar, returnValueBytes, propertyInfo.associationType);
    } else {
        __autoreleasing id dictionaryValue = nil;
        if ([propertyInfo.typeEncoding isEqualToString:@"@\"PFRelation\""]) {
            dictionaryValue = [object relationForKey:propertyInfo.name];
        } else {
            dictionaryValue = object[propertyInfo.name];

            // TODO: (richardross) Investigate why we were orignally copying the result of -objectForKey,
            // as this doens't seem right.
            if (propertyInfo.associationType == PFPropertyInfoAssociationTypeCopy) {
                dictionaryValue = [dictionaryValue copy];
            }
        }

        if (dictionaryValue == nil || [dictionaryValue isKindOfClass:[NSNull class]]) {
            memset(returnValueBytes, 0, invocation.methodSignature.methodReturnLength);
        } else if (methodReturnType[0] == '@') {
            memcpy(returnValueBytes, (void *) &dictionaryValue, sizeof(id));
        } else if ([dictionaryValue isKindOfClass:[NSNumber class]]) {
            CFNumberGetValue((__bridge CFNumberRef) dictionaryValue,
                             PFNumberTypeForObjCType(methodReturnType),
                             returnValueBytes);
        } else {
            // TODO:(richardross)Support C-style structs that automatically convert to JSON via NSValue?
            PFConsistencyAssert(false, @"Unsupported type encoding %s!", methodReturnType);
        }
    }

    [invocation setReturnValue:returnValueBytes];
}

- (void)_forwardSetterInvocation:(NSInvocation *)invocation
                     forProperty:(PFPropertyInfo *)propertyInfo
                      withObject:(PFObject *)object {
    PFConsistencyAssert(invocation.methodSignature.numberOfArguments == 3, @"Setter should only take 1 argument!");

    PFObject *sourceObject = object;
    const char *argumentType = [invocation.methodSignature getArgumentTypeAtIndex:2];

    NSUInteger argumentValueSize = 0;
    NSGetSizeAndAlignment(argumentType, &argumentValueSize, NULL);

    void *argumentValueBytes = alloca(argumentValueSize);
    [invocation getArgument:argumentValueBytes atIndex:2];

    if (propertyInfo.ivar) {
        object_setIvarValue_safe(sourceObject, propertyInfo.ivar, argumentValueBytes, propertyInfo.associationType);
    } else {
        id dictionaryValue = nil;

        if (argumentType[0] == '@') {
            dictionaryValue = *(__unsafe_unretained id *)argumentValueBytes;

            if (propertyInfo.associationType == PFPropertyInfoAssociationTypeCopy) {
                dictionaryValue = [dictionaryValue copy];
            }
        } else {
            dictionaryValue = PFNumberCreateSafe(argumentType, argumentValueBytes);
        }

        if (dictionaryValue == nil) {
            [sourceObject removeObjectForKey:propertyInfo.name];
        } else {
            sourceObject[propertyInfo.name] = dictionaryValue;
        }
    }
}

- (PFObjectSubclassInfo *)_subclassInfoForClass:(Class<PFSubclassing>)kls {
    __block PFObjectSubclassInfo *result = nil;
    pf_sync_with_throw(_registeredSubclassesAccessQueue, ^{
        if (class_respondsToSelector(object_getClass(kls), @selector(parseClassName))) {
            result = _registeredSubclasses[[kls parseClassName]];
        }

        // TODO: (nlutsenko, richardross) Don't let unregistered subclasses have dynamic property resolution.
        if (!result) {
            result = [PFObjectSubclassInfo subclassInfoWithSubclass:kls];
            _unregisteredSubclasses[NSStringFromClass(kls)] = result;
        }
    });
    return result;
}

// Reverse compatibility note: many people may have built PFObject subclasses before
// we officially supported them. Our implementation can do cool stuff, but requires
// the parseClassName class method.
- (void)_rawRegisterSubclass:(Class)kls {
    PFConsistencyAssert([kls conformsToProtocol:@protocol(PFSubclassing)],
                        @"Can only call +registerSubclass on subclasses conforming to PFSubclassing.");

    NSString *parseClassName = [kls parseClassName];

    // Bug detection: don't allow subclasses of subclasses (i.e. custom user classes)
    // to change the value of +parseClassName
    if ([kls superclass] != [PFObject class]) {
        // We compare Method definitions against the PFObject version witout invoking it
        // because that Method could throw on an intermediary class which is
        // not meant for direct use.
        Method baseImpl = class_getClassMethod([PFObject class], @selector(parseClassName));
        Method superImpl = class_getClassMethod([kls superclass], @selector(parseClassName));

        PFConsistencyAssert(superImpl == baseImpl ||
                            [parseClassName isEqualToString:[[kls superclass] parseClassName]],
                            @"Subclasses of subclasses may not have separate +parseClassName "
                            "definitions. %@ should inherit +parseClassName from %@.",
                            kls, [kls superclass]);
    }

    Class current = [_registeredSubclasses[parseClassName] subclass];
    if (current && current != kls) {
        // We've already registered a more specific subclass (i.e. we're calling
        // registerSubclass:PFUser after MYUser
        if ([current isSubclassOfClass:kls]) {
            return;
        }

        PFConsistencyAssert([kls isSubclassOfClass:current],
                            @"Tried to register both %@ and %@ as the native PFObject subclass "
                            "of %@. Cannot determine the right class to use because neither "
                            "inherits from the other.", current, kls, parseClassName);
    }

    // Move the subclass info from unregisteredSubclasses dictionary to registered ones, or create if it doesn't exist.
    NSString *className = NSStringFromClass(kls);
    PFObjectSubclassInfo *subclassInfo = _unregisteredSubclasses[className];
    if (subclassInfo) {
        [_unregisteredSubclasses removeObjectForKey:className];
    } else {
        subclassInfo = [PFObjectSubclassInfo subclassInfoWithSubclass:kls];
    }
    _registeredSubclasses[[kls parseClassName]] = subclassInfo;
}

- (void)_registerSubclassesInLoadedBundle:(NSBundle *)bundle {
    // Skip bundles that aren't loaded yet.
    if (![bundle isKindOfClass:NSBundle.class] || !bundle.loaded || !bundle.executablePath) {
        return;
    }
    // Filter out any system bundles
    if ([bundle.bundlePath hasPrefix:@"/System/"] || [bundle.bundlePath hasPrefix:@"/Library/"] || [bundle.bundlePath rangeOfString:@"iPhoneSimulator.sdk"].location != NSNotFound) {
        return;
    }
    [self _registerSubclassesInBundle:bundle];
}

- (void)_registerSubclassesInBundle:(NSBundle *)bundle {
    PFConsistencyAssert(bundle.loaded, @"Cannot register subclasses in an unloaded bundle: %@", bundle);

    const char *executablePath = bundle.executablePath.UTF8String;
    if (executablePath == NULL) {
        return;
    }

    dispatch_sync(_registeredSubclassesAccessQueue, ^{
        Class pfObjectClass = [PFObject class];

        // There are two different paths that we will need to check for the bundle, depending on the platform.
        // - First, we need to check the raw executable path fom the bundle.
        //   This should be valid for most frameworks on macOS, and iOS/watchOS/tvOS simulators.
        // - Second, we need to check the symlink resolved path - including /private/var on iOS.
        //   This should be valid for iOS, watchOS, and tvOS devices.
        // In case there are other platforms that require checking multiple paths that we add support for,
        // just use a simple array here.
        char potentialPaths[2][PATH_MAX] = { };

        strncpy(potentialPaths[0], executablePath, PATH_MAX);
        realpath(potentialPaths[0], potentialPaths[1]);

        const char **classNames = NULL;
        unsigned bundleClassCount = 0;

        for (int i = 0; i < sizeof(potentialPaths) / sizeof(*potentialPaths); i++) {
            classNames = objc_copyClassNamesForImage(potentialPaths[i], &bundleClassCount);
            if (bundleClassCount) {
                break;
            }

            free(classNames);
            classNames = NULL;
        }

        for (unsigned i = 0; i < bundleClassCount; i++) {
            Class bundleClass = objc_getClass(classNames[i]);
            // For obvious reasons, don't register the PFObject class.
            if (bundleClass == pfObjectClass) {
                continue;
            }
            // NOTE: Cannot use isSubclassOfClass here. Some classes may be part of a system bundle (even
            // though we attempt to filter those out) that may be an internal class which doesn't inherit from NSObject.
            // Scary, I know!
            for (Class kls = bundleClass; kls != nil; kls = class_getSuperclass(kls)) {
                if (kls == pfObjectClass) {
                    // Do -conformsToProtocol: as late in the checking as possible, as its SUUUPER slow.
                    // Behind the scenes this is a strcmp (lolwut?)
                    if ([bundleClass conformsToProtocol:@protocol(PFSubclassing)] &&
                        ![bundleClass conformsToProtocol:@protocol(PFSubclassingSkipAutomaticRegistration)]) {
                        [self _rawRegisterSubclass:bundleClass];
                    }
                    break;
                }
            }
        }
        free(classNames);
    });
}

@end
