/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSession.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCoreManager.h"
#import "PFCurrentUserController.h"
#import "PFObject+Subclass.h"
#import "PFObjectPrivate.h"
#import "PFSessionController.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

static BOOL _PFSessionIsWritablePropertyForKey(NSString *key) {
    static NSSet *protectedKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        protectedKeys = [NSSet setWithObjects:
                         @"sessionToken",
                         @"restricted",
                         @"createdWith",
                         @"installationId",
                         @"user",
                         @"expiresAt", nil];
    });
    return ![protectedKeys containsObject:key];
}

@implementation PFSession

@dynamic sessionToken;

///--------------------------------------
#pragma mark - PFSubclassing
///--------------------------------------

+ (NSString *)parseClassName {
    return @"_Session";
}

- (BOOL)needsDefaultACL {
    return NO;
}

///--------------------------------------
#pragma mark - Class
///--------------------------------------

+ (void)_assertValidInstanceClassName:(NSString *)className {
    PFParameterAssert([className isEqualToString:[PFSession parseClassName]],
                      @"Cannot initialize a PFSession with a custom class name.");
}

#pragma mark Get Current Session

+ (BFTask *)getCurrentSessionInBackground {
    PFCurrentUserController *controller = [[self class] currentUserController];
    return [[controller getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        return [[self sessionController] getCurrentSessionAsyncWithSessionToken:sessionToken];
    }];
}

+ (void)getCurrentSessionInBackgroundWithBlock:(PFSessionResultBlock)block {
    [[self getCurrentSessionInBackground] thenCallBackOnMainThreadAsync:block];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setObject:(id)object forKey:(NSString *)key {
    PFParameterAssert(_PFSessionIsWritablePropertyForKey(key),
                      @"Can't change the '%@' field of a PFSession.", key);
    [super setObject:object forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    PFParameterAssert(_PFSessionIsWritablePropertyForKey(key),
                      @"Can't remove the '%@' field of a PFSession.", key);
    [super removeObjectForKey:key];
}

- (void)removeObjectsInArray:(NSArray *)objects forKey:(NSString *)key {
    PFParameterAssert(_PFSessionIsWritablePropertyForKey(key),
                      @"Can't remove any object from '%@' field of a PFSession.", key);
    [super removeObjectsInArray:objects forKey:key];
}

///--------------------------------------
#pragma mark - Session Controller
///--------------------------------------

+ (PFSessionController *)sessionController {
    return [Parse _currentManager].coreManager.sessionController;
}

@end
