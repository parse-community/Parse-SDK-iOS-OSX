/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFInternalUtils.h"

#include <sys/stat.h>
#include <sys/xattr.h>

#import <Foundation/Foundation.h>

#import "PFACLPrivate.h"
#import "PFAssert.h"
#import "PFDateFormatter.h"
#import "BFTask+Private.h"
#import "PFFieldOperation.h"
#import "PFFile_Private.h"
#import "PFGeoPointPrivate.h"
#import "PFKeyValueCache.h"
#import "PFKeychainStore.h"
#import "PFLogging.h"
#import "PFEncoder.h"
#import "PFObjectPrivate.h"
#import "PFRelationPrivate.h"
#import "PFUserPrivate.h"
#import "Parse.h"
#import "PFFileManager.h"
#import "PFJSONSerialization.h"
#import "PFMultiProcessFileLockController.h"
#import "PFHash.h"
#import "Parse_Private.h"
#import "ParseClientConfiguration_Private.h"

#if TARGET_OS_IOS
#import "PFProduct.h"
#endif

static NSString *parseServer_;

@implementation PFInternalUtils

+ (void)initialize {
    if (self == [PFInternalUtils class]) {
        [self setParseServer:_ParseDefaultServerURLString];
    }
}

+ (NSString *)parseServerURLString {
    return parseServer_;
}

// Useful for testing.
// Beware of race conditions if you call setParseServer while something else may be using
// httpClient.
+ (void)setParseServer:(NSString *)server {
    parseServer_ = [server copy];
}

+ (NSString *)currentSystemTimeZoneName {
    static NSLock *methodLock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        methodLock = [[NSLock alloc] init];
    });

    [methodLock lock];
    [NSTimeZone resetSystemTimeZone];
    NSString *systemTimeZoneName = [[NSTimeZone systemTimeZone].name copy];
    [methodLock unlock];

    return systemTimeZoneName;
}

+ (void)safePerformSelector:(SEL)selector withTarget:(id)target object:(id)object object:(id)anotherObject {
    if (target == nil || selector == nil || ![target respondsToSelector:selector]) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [target performSelector:selector withObject:object withObject:anotherObject];
#pragma clang diagnostic pop
}

///--------------------------------------
#pragma mark - Serialization
///--------------------------------------

+ (NSNumber *)addNumber:(NSNumber *)first withNumber:(NSNumber *)second {
    const char *objcType = first.objCType;

    if (strcmp(objcType, @encode(BOOL)) == 0) {
        return @(first.boolValue + second.boolValue);
    } else if (strcmp(objcType, @encode(char)) == 0) {
        return @(first.charValue + second.charValue);
    } else if (strcmp(objcType, @encode(double)) == 0) {
        return @(first.doubleValue + second.doubleValue);
    } else if (strcmp(objcType, @encode(float)) == 0) {
        return @(first.floatValue + second.floatValue);
    } else if (strcmp(objcType, @encode(int)) == 0) {
        return @(first.intValue + second.intValue);
    } else if (strcmp(objcType, @encode(long)) == 0) {
        return @(first.longValue + second.longValue);
    } else if (strcmp(objcType, @encode(long long)) == 0) {
        return @(first.longLongValue + second.longLongValue);
    } else if (strcmp(objcType, @encode(short)) == 0) {
        return @(first.shortValue + second.shortValue);
    } else if (strcmp(objcType, @encode(unsigned char)) == 0) {
        return @(first.unsignedCharValue + second.unsignedCharValue);
    } else if (strcmp(objcType, @encode(unsigned int)) == 0) {
        return @(first.unsignedIntValue + second.unsignedIntValue);
    } else if (strcmp(objcType, @encode(unsigned long)) == 0) {
        return @(first.unsignedLongValue + second.unsignedLongValue);
    } else if (strcmp(objcType, @encode(unsigned long long)) == 0) {
        return @(first.unsignedLongLongValue + second.unsignedLongLongValue);
    } else if (strcmp(objcType, @encode(unsigned short)) == 0) {
        return @(first.unsignedShortValue + second.unsignedShortValue);
    }

    // Fall back to int?
    return @(first.intValue + second.intValue);
}

///--------------------------------------
#pragma mark - CacheKey
///--------------------------------------

#pragma mark Public

+ (NSString *)cacheKeyForObject:(id)object {
    NSMutableString *string = [NSMutableString string];
    [self appendObject:object toString:string];
    return string;
}

#pragma mark Private

+ (void)appendObject:(id)object toString:(NSMutableString *)string {
    if ([object isKindOfClass:[NSDictionary class]]) {
        [self appendDictionary:object toString:string];
    } else if ([object isKindOfClass:[NSArray class]]) {
        [self appendArray:object toString:string];
    } else if ([object isKindOfClass:[NSString class]]) {
        [string appendFormat:@"\"%@\"", object];
    } else if ([object isKindOfClass:[NSNumber class]]) {
        [self appendNumber:object toString:string];
    } else if ([object isKindOfClass:[NSNull class]]) {
        [self appendNullToString:string];
    } else {
        PFParameterAssertionFailure(@"Couldn't create cache key from %@", object);
    }
}

+ (void)appendDictionary:(NSDictionary *)dictionary toString:(NSMutableString *)string {
    [string appendString:@"{"];

    NSArray *keys = [dictionary.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        [string appendFormat:@"%@:", key];

        id value = dictionary[key];
        [self appendObject:value toString:string];

        [string appendString:@","];
    }

    [string appendString:@"}"];
}

+ (void)appendArray:(NSArray *)array toString:(NSMutableString *)string {
    [string appendString:@"["];
    for (id object in array) {
        [self appendObject:object toString:string];
        [string appendString:@","];
    }
    [string appendString:@"]"];
}

+ (void)appendNumber:(NSNumber *)number toString:(NSMutableString *)string {
    [string appendFormat:@"%@", number.stringValue];
}

+ (void)appendNullToString:(NSMutableString *)string {
    [string appendString:@"null"];
}

+ (id)traverseObject:(id)object usingBlock:(id (^)(id object))block seenObjects:(NSMutableSet *)seen {
    if ([object isKindOfClass:[PFObject class]]) {
        if ([seen containsObject:object]) {
            // We've already visited this object in this call.
            return object;
        }
        [seen addObject:object];

        for (NSString *key in ((PFObject *)object).allKeys) {
            [self traverseObject:object[key] usingBlock:block seenObjects:seen];
        }

        return block(object);
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArray = [object mutableCopy];
        [object enumerateObjectsUsingBlock:^(id child, NSUInteger idx, BOOL *stop) {
            id newChild = [self traverseObject:child usingBlock:block seenObjects:seen];
            if (newChild) {
                newArray[idx] = newChild;
            }
        }];
        return block(newArray);
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *newDictionary = [object mutableCopy];
        [object enumerateKeysAndObjectsUsingBlock:^(id key, id child, BOOL *stop) {
            id newChild = [self traverseObject:child usingBlock:block seenObjects:seen];
            if (newChild) {
                newDictionary[key] = newChild;
            }
        }];
        return block(newDictionary);
    }

    return block(object);
}

+ (id)traverseObject:(id)object usingBlock:(id (^)(id object))block {
    NSMutableSet *seen = [[NSMutableSet alloc] init];
    id result = [self traverseObject:object usingBlock:block seenObjects:seen];
    return result;
}

+ (NSArray *)arrayBySplittingArray:(NSArray *)array withMaximumComponentsPerSegment:(NSUInteger)components {
    if (array.count <= components) {
        return @[ array ];
    }

    NSMutableArray *splitArray = [NSMutableArray array];
    NSInteger index = 0;

    while (index < array.count) {
        NSInteger length = MIN(array.count - index, components);

        NSArray *subarray = [array subarrayWithRange:NSMakeRange(index, length)];
        [splitArray addObject:subarray];

        index += length;
    }

    return splitArray;
}

+ (id)_stringWithFormat:(NSString *)format arguments:(NSArray *)arguments {
    // We cannot reliably construct a va_list for 64-bit, so hard code up to N args.
    const int maxNumArgs = 10;
    PFRangeAssert(arguments.count <= maxNumArgs, @"Maximum of %d format args allowed", maxNumArgs);
    NSMutableArray *args = [arguments mutableCopy];
    for (NSUInteger i = arguments.count; i < maxNumArgs; i++) {
        [args addObject:@""];
    }
    return [NSString stringWithFormat:format,
            args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9]];
}

@end
