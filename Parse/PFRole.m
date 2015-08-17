/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRole.h"

#import <Bolts/BFTask.h>

#import "PFAssert.h"
#import "PFObject+Subclass.h"
#import "PFObjectPrivate.h"
#import "PFQuery.h"

@implementation PFRole

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithName:(NSString *)name {
    return [self initWithName:name acl:nil];
}

- (instancetype)initWithName:(NSString *)name acl:(PFACL *)acl {
    self = [super init];
    if (!self) return nil;

    self.name = name;
    self.ACL = acl;

    return self;
}

+ (instancetype)roleWithName:(NSString *)name {
    return [[self alloc] initWithName:name];
}

+ (instancetype)roleWithName:(NSString *)name acl:(PFACL *)acl {
    return [[self alloc] initWithName:name acl:acl];
}

///--------------------------------------
#pragma mark - Role-specific Properties
///--------------------------------------

@dynamic name;

// Dynamic synthesizers would use objectForKey, not relationForKey
- (PFRelation *)roles {
    return [self relationForKey:@keypath(PFRole, roles)];
}

- (PFRelation *)users {
    return [self relationForKey:@keypath(PFRole, users)];
}

///--------------------------------------
#pragma mark - PFObject Overrides
///--------------------------------------

- (void)setObject:(id)object forKey:(NSString *)key {
    if ([key isEqualToString:@keypath(PFRole, name)]) {
        PFConsistencyAssert(!self.objectId, @"A role's name can only be set before it has been saved.");
        PFParameterAssert([object isKindOfClass:[NSString class]], @"A role's name must be an NSString.");
        PFParameterAssert([object rangeOfString:@"^[0-9a-zA-Z_\\- ]+$" options:NSRegularExpressionSearch].location != NSNotFound,
                          @"A role's name can only contain alphanumeric characters, _, -, and spaces.");
    }
    [super setObject:object forKey:key];
}

- (BFTask *)saveInBackground {
    PFConsistencyAssert(self.objectId || self.name, @"New roles must specify a name.");
    return [super saveInBackground];
}

// Validates a class name. We override this to only allow the role class name.
+ (void)_assertValidInstanceClassName:(NSString *)className {
    PFParameterAssert([className isEqualToString:[self parseClassName]],
                      @"Cannot initialize a PFRole with a custom class name.");
}

+ (NSString *)parseClassName {
    return @"_Role";
}

@end
