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
        if (!self->_defaultACL || !self->_useCurrentUser) {
            return self->_defaultACL;
        }

        PFCurrentUserController *currentUserController = self.dataSource.currentUserController;
        return [[currentUserController getCurrentObjectAsync] continueWithBlock:^id(BFTask *task) {
            PFUser *currentUser = task.result;
            if (!currentUser) {
                return self->_defaultACL;
            }

            if (currentUser != self->_lastCurrentUser) {
                self->_defaultACLWithCurrentUser = [self->_defaultACL createUnsharedCopy];
                [self->_defaultACLWithCurrentUser setShared:YES];
                [self->_defaultACLWithCurrentUser setReadAccess:YES forUser:currentUser];
                [self->_defaultACLWithCurrentUser setWriteAccess:YES forUser:currentUser];
                self->_lastCurrentUser = currentUser;
            }
            return self->_defaultACLWithCurrentUser;
        }];
    }];
}

- (BFTask<PFACL *> *)setDefaultACLAsync:(PFACL *)acl withCurrentUserAccess:(BOOL)accessForCurrentUser {
    return [_taskQueue enqueue:^id(BFTask *task) {
        self->_defaultACLWithCurrentUser = nil;
        self->_lastCurrentUser = nil;

        self->_defaultACL = [acl createUnsharedCopy];
        [self->_defaultACL setShared:YES];

        self->_useCurrentUser = accessForCurrentUser;

        return self->_defaultACL;
    }];
}

@end
