/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFACL.h"
#import "PFACLPrivate.h"

#import "BFTask+Private.h"
#import "PFACLState.h"
#import "PFAssert.h"
#import "PFDefaultACLController.h"
#import "PFMacros.h"
#import "PFMutableACLState.h"
#import "PFObjectPrivate.h"
#import "PFObjectUtilities.h"
#import "PFRole.h"
#import "PFUser.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"
#import "PFCoreManager.h"

static NSString *const PFACLPublicKey_ = @"*";
static NSString *const PFACLUnresolvedKey_ = @"*unresolved";
static NSString *const PFACLCodingDataKey_ = @"ACL";

@interface PFACL ()

@property (atomic, strong, readwrite) PFACLState *state;

@end

@implementation PFACL {
    PFUser *unresolvedUser;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _state = [[PFACLState alloc] init];

    return self;
}

///--------------------------------------
#pragma mark - Default ACL
///--------------------------------------

+ (instancetype)ACL {
    return [[self alloc] init];
}

+ (instancetype)ACLWithUser:(PFUser *)user {
    PFACL *acl = [self ACL];
    [acl setReadAccess:YES forUser:user];
    [acl setWriteAccess:YES forUser:user];
    return acl;
}

+ (instancetype)ACLWithDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithDictionary:dictionary];
}

+ (PFACL *)defaultACL {
    PFDefaultACLController *controller = [Parse _currentManager].coreManager.defaultACLController;
    return [[controller getDefaultACLAsync] waitForResult:NULL withMainThreadWarning:NO];
}

+ (void)setDefaultACL:(PFACL *)acl withAccessForCurrentUser:(BOOL)currentUserAccess {
    PFDefaultACLController *controller = [Parse _currentManager].coreManager.defaultACLController;
    // TODO: (nlutsenko) Remove this in favor of assert on `_currentManager`.
    PFConsistencyAssert(controller, @"Can't set default ACL before Parse is initialized.");
    [controller setDefaultACLAsync:acl withCurrentUserAccess:currentUserAccess];
}

- (void)setShared:(BOOL)newShared {
    self.state = [self.state copyByMutatingWithBlock:^(PFMutableACLState *newState) {
        newState.shared = newShared;
    }];
}

- (BOOL)isShared {
    return self.state.shared;
}

- (instancetype)createUnsharedCopy {
    PFACL *newACL = [[self class] ACLWithDictionary:self.state.permissions];
    if (unresolvedUser) {
        [newACL setReadAccess:[self getReadAccessForUser:unresolvedUser] forUser:unresolvedUser];
        [newACL setWriteAccess:[self getWriteAccessForUser:unresolvedUser] forUser:unresolvedUser];
    }
    return newACL;
}

- (BOOL)resolveUser:(PFUser *)user {
    if (user != unresolvedUser) {
        return YES;
    }
    if (!user || !user.objectId) {
        return NO;
    }
    NSMutableDictionary *unresolvedPermissions = self.state.permissions[PFACLUnresolvedKey_];
    if (unresolvedPermissions) {
        self.state = [self.state copyByMutatingWithBlock:^(PFMutableACLState *newState) {
            newState.permissions[user.objectId] = unresolvedPermissions;
            [newState.permissions removeObjectForKey:PFACLUnresolvedKey_];
        }];
    }
    unresolvedUser = nil;
    return YES;
}

- (BOOL)hasUnresolvedUser {
    return unresolvedUser != nil;
}

- (void)setAccess:(NSString *)accessType to:(BOOL)allowed forUserId:(NSString *)userId {
    NSDictionary *permissions = self.state.permissions[userId];

    // No change needed.
    if ([permissions[accessType] boolValue] == allowed) {
        return;
    }

    NSMutableDictionary *newPermissions = [NSMutableDictionary dictionaryWithDictionary:permissions];
    if (allowed) {
        newPermissions[accessType] = @YES;
    } else {
        [newPermissions removeObjectForKey:accessType];
    }

    self.state = [self.state copyByMutatingWithBlock:^(PFMutableACLState *newState) {
        if (newPermissions.count) {
            newState.permissions[userId] = [newPermissions copy];
        } else {
            [newState.permissions removeObjectForKey:userId];
        }
    }];
}

- (BOOL)getAccess:(NSString *)accessType forUserId:(NSString *)userId {
    return [self.state.permissions[userId][accessType] boolValue];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
    if (!self) return nil;

    // We iterate over the input ACL rather than just copying to
    // permissionsById so that we can ensure it is the right format.
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *userId, NSDictionary *permissions, BOOL *stop) {
        [permissions enumerateKeysAndObjectsUsingBlock:^(NSString *accessType, id obj, BOOL *stop) {
            [self setAccess:accessType to:[obj boolValue] forUserId:userId];
        }];
    }];

    return self;
}

- (void)setReadAccess:(BOOL)allowed forUserId:(NSString *)userId {
    PFParameterAssert(userId, @"Can't setReadAccess for nil userId.");
    [self setAccess:@"read" to:allowed forUserId:userId];
}

- (BOOL)getReadAccessForUserId:(NSString *)userId {
    PFParameterAssert(userId, @"Can't getReadAccessForUserId for nil userId.");
    return [self getAccess:@"read" forUserId:userId];
}

- (void)setWriteAccess:(BOOL)allowed forUserId:(NSString *)userId {
    PFParameterAssert(userId, @"Can't setWriteAccess for nil userId.");
    [self setAccess:@"write" to:allowed forUserId:userId];
}

- (BOOL)getWriteAccessForUserId:(NSString *)userId {
    PFParameterAssert(userId, @"Can't getWriteAccessForUserId for nil userId.");
    return [self getAccess:@"write" forUserId:userId];
}

- (void)setPublicReadAccess:(BOOL)allowed {
    [self setReadAccess:allowed forUserId:PFACLPublicKey_];
}

- (BOOL)getPublicReadAccess {
    return [self getReadAccessForUserId:PFACLPublicKey_];
}

- (void)setPublicWriteAccess:(BOOL)allowed {
    [self setWriteAccess:allowed forUserId:PFACLPublicKey_];
}

- (BOOL)getPublicWriteAccess {
    return [self getWriteAccessForUserId:PFACLPublicKey_];
}

- (BOOL)getReadAccessForRoleWithName:(NSString *)name {
    PFParameterAssert(name, @"Can't get read access for nil role name.");
    return [self getReadAccessForUserId:[@"role:" stringByAppendingString:name]];
}

- (void)setReadAccess:(BOOL)allowed forRoleWithName:(NSString *)name {
    PFParameterAssert(name, @"Can't set read access for nil role name.");
    [self setReadAccess:allowed forUserId:[@"role:" stringByAppendingString:name]];
}

- (BOOL)getWriteAccessForRoleWithName:(NSString *)name {
    PFParameterAssert(name, @"Can't get write access for nil role name.");
    return [self getWriteAccessForUserId:[@"role:" stringByAppendingString:name]];
}

- (void)setWriteAccess:(BOOL)allowed forRoleWithName:(NSString *)name {
    PFParameterAssert(name, @"Can't set write access for nil role name.");
    [self setWriteAccess:allowed forUserId:[@"role:" stringByAppendingString:name]];
}

- (void)validateRoleState:(PFRole *)role {
    // Validates that a role has already been saved to the server, and thus can be used in an ACL.
    PFParameterAssert(role.objectId, @"Roles must be saved to the server before they can be used in an ACL.");
}

- (BOOL)getReadAccessForRole:(PFRole *)role {
    [self validateRoleState:role];
    return [self getReadAccessForRoleWithName:role.name];
}

- (void)setReadAccess:(BOOL)allowed forRole:(PFRole *)role {
    [self validateRoleState:role];
    [self setReadAccess:allowed forRoleWithName:role.name];
}

- (BOOL)getWriteAccessForRole:(PFRole *)role {
    [self validateRoleState:role];
    return [self getWriteAccessForRoleWithName:role.name];
}

- (void)setWriteAccess:(BOOL)allowed forRole:(PFRole *)role {
    [self validateRoleState:role];
    [self setWriteAccess:allowed forRoleWithName:role.name];
}

- (void)prepareUnresolvedUser:(PFUser *)user {
    // TODO: (nlutsenko) Consider making @synchronized.
    if (unresolvedUser != user) {
        // If the unresolved user changed, register the save listener on the new user.  This listener
        // will call resolveUser with the user.
        self.state = [self.state copyByMutatingWithBlock:^(PFMutableACLState *newState) {
            [newState.permissions removeObjectForKey:PFACLUnresolvedKey_];
        }];

        unresolvedUser = user;

        // Note: callback is a reference back to the same block so that it can unregister itself.
        @weakify(self);
        __weak __block void (^weakCallback)(id result, NSError *error) = nil;
        __block void (^callback)(id result, NSError *error) = [^(id result, NSError *error) {
            @strongify(self);
            if ([self resolveUser:result]) {
                [result unregisterSaveListener:weakCallback];
            }
        } copy];
        weakCallback = callback;
        [user registerSaveListener:callback];
    }
}

- (void)setUnresolvedReadAccess:(BOOL)allowed forUser:(PFUser *)user {
    [self prepareUnresolvedUser:user];
    [self setReadAccess:allowed forUserId:PFACLUnresolvedKey_];
}

- (void)setReadAccess:(BOOL)allowed forUser:(PFUser *)user {
    NSString *objectId = user.objectId;
    if (!objectId) {
        if (user._lazy) {
            [self setUnresolvedReadAccess:allowed forUser:user];
            return;
        }
        PFParameterAssert(objectId, @"Can't setReadAcccess for unsaved user.");
    }
    [self setReadAccess:allowed forUserId:objectId];
}

- (BOOL)getReadAccessForUser:(PFUser *)user {
    if (user == unresolvedUser) {
        return [self getReadAccessForUserId:PFACLUnresolvedKey_];
    }
    NSString *objectId = user.objectId;
    PFParameterAssert(objectId, @"Can't getReadAccessForUser who isn't saved.");
    return [self getReadAccessForUserId:objectId];
}

- (void)setUnresolvedWriteAccess:(BOOL)allowed forUser:(PFUser *)user {
    [self prepareUnresolvedUser:user];
    [self setWriteAccess:allowed forUserId:PFACLUnresolvedKey_];
}

- (void)setWriteAccess:(BOOL)allowed forUser:(PFUser *)user {
    NSString *objectId = user.objectId;
    if (!objectId) {
        if (user._lazy) {
            [self setUnresolvedWriteAccess:allowed forUser:user];
            return;
        }
        PFParameterAssert(objectId, @"Can't setWriteAccess for unsaved user.");
    }
    [self setWriteAccess:allowed forUserId:objectId];
}

- (BOOL)getWriteAccessForUser:(PFUser *)user {
    if (user == unresolvedUser) {
        return [self getWriteAccessForUserId:PFACLUnresolvedKey_];
    }
    NSString *objectId = user.objectId;
    PFParameterAssert(objectId, @"Can't getWriteAccessForUser who isn't saved.");
    return [self getWriteAccessForUserId:objectId];
}

- (NSDictionary *)encodeIntoDictionary:(NSError **)error {
    return self.state.permissions;
}

///--------------------------------------
#pragma mark - NSObject
///--------------------------------------

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[PFACL class]]) {
        return NO;
    }

    PFACL *acl = (PFACL *)object;
    return [self.state isEqual:acl.state] && [PFObjectUtilities isObject:self->unresolvedUser
                                                           equalToObject:acl->unresolvedUser];
}

- (NSUInteger)hash {
    return self.state.hash ^ unresolvedUser.hash;
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[PFACL allocWithZone:zone] initWithDictionary:self.state.permissions];
}

///--------------------------------------
#pragma mark - NSCoding
///--------------------------------------

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSDictionary *dictionary = [coder decodeObjectForKey:PFACLCodingDataKey_];
    return [self initWithDictionary:dictionary];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:[self encodeIntoDictionary:nil] forKey:PFACLCodingDataKey_];
}

@end
