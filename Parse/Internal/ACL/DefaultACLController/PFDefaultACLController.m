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
#import "PFCurrentUserController.h"

@implementation PFDefaultACLController {
    PFAsyncTaskQueue *_taskQueue;

    PFACL *_defaultACL;
    BOOL _useCurrentUser;

    PFUser *_lastCurrentUser;
    PFACL *_defaultACLWithCurrentUser;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFCurrentUserControllerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _taskQueue = [[PFAsyncTaskQueue alloc] init];
    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFCurrentUserControllerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - ACL
///--------------------------------------

- (BFTask<PFACL *> *)getDefaultACLAsync {
    return [_taskQueue enqueue:^id(BFTask *task) {
        if (!_defaultACL || !_useCurrentUser) {
            return _defaultACL;
        }

        PFCurrentUserController *currentUserController = self.dataSource.currentUserController;
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

- (BFTask<PFACL *> *)setDefaultACLAsync:(PFACL *)acl withCurrentUserAccess:(BOOL)accessForCurrentUser {
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
