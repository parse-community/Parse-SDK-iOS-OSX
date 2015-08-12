/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDefaultACLController.h"

#import <Bolts/BFTask.h>

#import "PFACLPrivate.h"
#import "PFAsyncTaskQueue.h"
#import "PFCoreManager.h"
#import "PFCurrentUserController.h"
#import "Parse_Private.h"

@implementation PFDefaultACLController {
    PFAsyncTaskQueue *_taskQueue;

    PFACL *_defaultACL;
    BOOL _useCurrentUser;

    PFUser *_lastCurrentUser;
    PFACL *_defaultACLWithCurrentUser;
}

static PFDefaultACLController *defaultController_;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)defaultController {
    if (!defaultController_) {
        defaultController_ = [[self alloc] init];
    }
    return defaultController_;
}

+ (void)clearDefaultController {
    defaultController_ = nil;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _taskQueue = [[PFAsyncTaskQueue alloc] init];

    return self;
}

///--------------------------------------
#pragma mark - ACL
///--------------------------------------

- (BFTask *)getDefaultACLAsync {
    return [_taskQueue enqueue:^id(BFTask *task) {
        if (!_defaultACL || !_useCurrentUser) {
            return _defaultACL;
        }

        PFCurrentUserController *currentUserController = [Parse _currentManager].coreManager.currentUserController;
        return [[currentUserController getCurrentObjectAsync] continueWithBlock:^id(BFTask *task) {
            PFUser *currentUser = task.result;
            if (!currentUser) {
                return _defaultACL;
            }

            if (currentUser != _lastCurrentUser) {
                _defaultACLWithCurrentUser = [_defaultACL createUnsharedCopy];
                [_defaultACLWithCurrentUser setShared:YES];
                [_defaultACLWithCurrentUser setReadAccess:YES forUser:currentUser];
                [_defaultACLWithCurrentUser setWriteAccess:YES forUser:currentUser];
                _lastCurrentUser = currentUser;
            }
            return _defaultACLWithCurrentUser;
        }];
    }];
}

- (BFTask *)setDefaultACLAsync:(PFACL *)acl withCurrentUserAccess:(BOOL)accessForCurrentUser {
    return [_taskQueue enqueue:^id(BFTask *task) {
        _defaultACLWithCurrentUser = nil;
        _lastCurrentUser = nil;

        _defaultACL = [acl createUnsharedCopy];
        [_defaultACL setShared:YES];

        _useCurrentUser = accessForCurrentUser;

        return _defaultACL;
    }];
}

@end
