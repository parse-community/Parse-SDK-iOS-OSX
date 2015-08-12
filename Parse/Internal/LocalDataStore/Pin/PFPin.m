/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPin.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFObject+Subclass.h"
#import "PFObjectPrivate.h"
#import "PFOfflineStore.h"
#import "PFQueryPrivate.h"
#import "Parse_Private.h"

NSString *const PFPinKeyName = @"_name";
NSString *const PFPinKeyObjects = @"_objects";

@implementation PFPin

///--------------------------------------
#pragma mark - PFSubclassing
///--------------------------------------

+ (NSString *)parseClassName {
    return @"_Pin";
}

// Validates a class name. We override this to only allow the pin class name.
+ (void)_assertValidInstanceClassName:(NSString *)className {
    PFParameterAssert([className isEqualToString:[self parseClassName]],
                      @"Cannot initialize a PFPin with a custom class name.");
}

- (BOOL)needsDefaultACL {
    return NO;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (!self) return nil;

    // Use property accessor, as there is no ivar here for `name`.
    self.name = name;

    return self;
}

+ (instancetype)pinWithName:(NSString *)name {
    return [[self alloc] initWithName:name];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (NSString *)name {
    return self[PFPinKeyName];
}

- (void)setName:(NSString *)name {
    self[PFPinKeyName] = [name copy];
}

- (NSMutableArray *)objects {
    return self[PFPinKeyObjects];
}

- (void)setObjects:(NSMutableArray *)objects {
    self[PFPinKeyObjects] = [objects mutableCopy];
}

@end
