/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCurrentUserController.h"

#if __has_include(<Bolts/BFTaskCompletionSource.h>)
#import <Bolts/BFTaskCompletionSource.h>
#else
#import "BFTaskCompletionSource.h"
#endif

#import "BFTask+Private.h"
#import "PFAnonymousUtils_Private.h"
#import "PFAssert.h"
#import "PFAsyncTaskQueue.h"
#import "PFKeychainStore.h"
#import "PFMutableUserState.h"
#import "PFObjectFilePersistenceController.h"
#import "PFObjectPrivate.h"
#import "PFQuery.h"
#import "PFUserConstants.h"
#import "PFUserPrivate.h"

@interface PFCurrentUserController () {
    dispatch_queue_t _dataQueue;
    PFAsyncTaskQueue *_dataTaskQueue;

    PFUser *_currentUser;
    BOOL _currentUserMatchesDisk;
}

@end

@implementation PFCurrentUserController

@synthesize storageType = _storageType;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithStorageType:(PFCurrentObjectStorageType)storageType
                   commonDataSource:(id<PFKeychainStoreProvider>)commonDataSource
                     coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource {
    self = [super init];
    if (!self) return nil;

    _dataQueue = dispatch_queue_create("com.parse.currentUser.controller", DISPATCH_QUEUE_CONCURRENT);
    _dataTaskQueue = [PFAsyncTaskQueue taskQueue];

    _storageType = storageType;
    _commonDataSource = commonDataSource;
    _coreDataSource = coreDataSource;

    return self;
}

+ (instancetype)controllerWithStorageType:(PFCurrentObjectStorageType)dataStorageType
                         commonDataSource:(id<PFKeychainStoreProvider>)commonDataSource
                           coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource {
    return [[self alloc] initWithStorageType:dataStorageType
                            commonDataSource:commonDataSource
                              coreDataSource:coreDataSource];
}

///--------------------------------------
#pragma mark - PFCurrentObjectControlling
///--------------------------------------

- (BFTask *)getCurrentObjectAsync {
    PFCurrentUserLoadingOptions options = 0;
    if (self.automaticUsersEnabled) {
        options |= PFCurrentUserLoadingOptionCreateLazyIfNotAvailable;
    }
    return [self getCurrentUserAsyncWithOptions:options];
}

- (BFTask *)saveCurrentObjectAsync:(PFObject *)object {
    PFUser *user = (PFUser *)object;
    return [_dataTaskQueue enqueue:^id(BFTask *task) {
        return [self _saveCurrentUserAsync:user];
    }];
}

///--------------------------------------
#pragma mark - User
///--------------------------------------

- (BFTask *)getCurrentUserAsyncWithOptions:(PFCurrentUserLoadingOptions)options {
    return [_dataTaskQueue enqueue:^id(BFTask *task) {
        return [self _getCurrentUserAsyncWithOptions:options];
    }];
}

- (BFTask *)_getCurrentUserAsyncWithOptions:(PFCurrentUserLoadingOptions)options {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        __block BOOL matchesDisk = NO;
        __block PFUser *currentUser = nil;
        dispatch_sync(self->_dataQueue, ^{
            matchesDisk = self->_currentUserMatchesDisk;
            currentUser = self->_currentUser;
        });
        if (currentUser) {
            return currentUser;
        }

        if (matchesDisk) {
            if (options & PFCurrentUserLoadingOptionCreateLazyIfNotAvailable) {
                return [self _lazyLogInUser];
            }
            return nil;
        }

        return [[[[self _loadCurrentUserFromDiskAsync] continueWithSuccessBlock:^id(BFTask *task) {
            PFUser *user = task.result;
            // If the object was not yet saved, but is already linked with AnonymousUtils - it means it is lazy.
            // So mark it's state as `lazy` and make it `dirty`
            if (!user.objectId && [PFAnonymousUtils isLinkedWithUser:user]) {
                user._lazy = YES;
                [user _setDirty:YES];
            }
            return user;
        }] continueWithBlock:^id(BFTask *task) {
            dispatch_barrier_sync(self->_dataQueue, ^{
                self->_currentUser = task.result;
                self->_currentUserMatchesDisk = !task.faulted;
            });
            return task;
        }] continueWithBlock:^id(BFTask *task) {
            // If there's no user and automatic user is enabled, do lazy login.
            if (!task.result && (options & PFCurrentUserLoadingOptionCreateLazyIfNotAvailable)) {
                return [self _lazyLogInUser];
            }
            return task;
        }];
    }];
}

- (BFTask *)_saveCurrentUserAsync:(PFUser *)user {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        __block PFUser *currentUser = nil;
        dispatch_sync(self->_dataQueue, ^{
            currentUser = self->_currentUser;
        });

        BFTask *task = [BFTask taskWithResult:nil];
        // Check for objectId equality to not logout in case we are saving another instance of the same user.
        if (currentUser != nil && currentUser != user && ![user.objectId isEqualToString:currentUser.objectId]) {
            task = [task continueWithBlock:^id(BFTask *task) {
                return [currentUser _logOutAsync];
            }];
        }
        return [[task continueWithBlock:^id(BFTask *task) {
            @synchronized (user.lock) {
                user._current = YES;
                [user synchronizeAllAuthData];
            }
            return [self _saveCurrentUserToDiskAsync:user];
        }] continueWithBlock:^id(BFTask *task) {
            dispatch_barrier_sync(self->_dataQueue, ^{
                self->_currentUser = user;
                self->_currentUserMatchesDisk = !task.faulted && !task.cancelled;
            });
            return user;
        }];
    }];
}

- (BFTask *)logOutCurrentUserAsync {
    return [_dataTaskQueue enqueue:^id(BFTask *task) {
        return [[self _getCurrentUserAsyncWithOptions:0] continueWithBlock:^id(BFTask *task) {
            BFTask *userLogoutTask = nil;

            PFUser *user = task.result;
            if (user) {
                userLogoutTask = [user _logOutAsync];
            } else {
                userLogoutTask = [BFTask taskWithResult:nil];
            }

            BFTask *fileTask = [self.coreDataSource.objectFilePersistenceController removePersistentObjectAsyncForKey:PFUserCurrentUserFileName];
            BFTask *unpinTask = nil;

            if (self.storageType == PFCurrentObjectStorageTypeOfflineStore) {
                unpinTask = [PFObject unpinAllObjectsInBackgroundWithName:PFUserCurrentUserPinName];
            } else {
                unpinTask = [BFTask taskWithResult:nil];
            }

            [self _deleteSensitiveUserDataFromKeychainWithItemName:PFUserCurrentUserFileName];

            BFTask *logoutTask = [[BFTask taskForCompletionOfAllTasks:@[ fileTask, unpinTask ]] continueWithBlock:^id(BFTask *task) {
                dispatch_barrier_sync(self->_dataQueue, ^{
                    self->_currentUser = nil;
                    self->_currentUserMatchesDisk = YES;
                });
                return nil;
            }];
            return [BFTask taskForCompletionOfAllTasks:@[ userLogoutTask, logoutTask ]];
        }];
    }];
}

///--------------------------------------
#pragma mark - Data Storage
///--------------------------------------

- (BFTask *)_loadCurrentUserFromDiskAsync {
    BFTask *task = nil;
    if (self.storageType == PFCurrentObjectStorageTypeOfflineStore) {
        // Try loading from OfflineStore
        PFQuery *query = [[[PFQuery queryWithClassName:[PFUser parseClassName]]
                           fromPinWithName:PFUserCurrentUserPinName]
                          // We need to ignoreACLs here because right now we don't have currentUser.
                          ignoreACLs];

        // Silence the warning if we are loading from LDS
        task = [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task) {
            NSArray *results = task.result;
            if (results.count == 1) {
                return results.firstObject;
            } else if (results.count != 0) {
                return [[PFObject unpinAllObjectsInBackgroundWithName:PFUserCurrentUserPinName] continueWithSuccessResult:nil];
            }

            // Backward compatibility if we previously have non-LDS currentUser.
            return [PFObject _migrateObjectInBackgroundFromFile:PFUserCurrentUserFileName toPin:PFUserCurrentUserPinName usingMigrationBlock:^id(BFTask *task) {
                PFUser *user = task.result;
                // Only migrate session token to Keychain if it was loaded from Data File.
                if (user.sessionToken) {
                    return [self _saveSensitiveUserDataAsync:user
                                      toKeychainItemWithName:PFUserCurrentUserKeychainItemName];
                }
                return nil;
            }];
        }];
    } else {
        PFObjectFilePersistenceController *controller = self.coreDataSource.objectFilePersistenceController;
        task = [controller loadPersistentObjectAsyncForKey:PFUserCurrentUserFileName];
    }
    return [task continueWithSuccessBlock:^id(BFTask *task) {
        PFUser *user = task.result;
        user._current = YES;
        return [[self _loadSensitiveUserDataAsync:user
                         fromKeychainItemWithName:PFUserCurrentUserKeychainItemName] continueWithSuccessResult:user];
    }];
}

- (BFTask *)_saveCurrentUserToDiskAsync:(PFUser *)user {
    if (self.storageType == PFCurrentObjectStorageTypeOfflineStore) {
        return [[[PFObject unpinAllObjectsInBackgroundWithName:PFUserCurrentUserPinName] continueWithSuccessBlock:^id(BFTask *task) {
            return [self _saveSensitiveUserDataAsync:user toKeychainItemWithName:PFUserCurrentUserKeychainItemName];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            // We don't want to include children of `currentUser` automatically.
            return [user _pinInBackgroundWithName:PFUserCurrentUserPinName includeChildren:NO];
        }];
    }

    return [[self _saveSensitiveUserDataAsync:user
                       toKeychainItemWithName:PFUserCurrentUserKeychainItemName] continueWithBlock:^id(BFTask *task) {
        PFObjectFilePersistenceController *controller = self.coreDataSource.objectFilePersistenceController;
        return [controller persistObjectAsync:user forKey:PFUserCurrentUserFileName];
    }];
}

///--------------------------------------
#pragma mark - Sensitive Data
///--------------------------------------

- (BFTask *)_loadSensitiveUserDataAsync:(PFUser *)user fromKeychainItemWithName:(NSString *)itemName {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSDictionary *userData = self.commonDataSource.keychainStore[itemName];
        @synchronized (user.lock) {
            if (userData) {
                PFMutableUserState *state = [user._state mutableCopy];

                NSString *sessionToken = userData[PFUserSessionTokenRESTKey] ?: userData[@"session_token"];
                if (sessionToken) {
                    state.sessionToken = sessionToken;
                }

                user._state = state;

                NSDictionary *newAuthData = userData[PFUserAuthDataRESTKey] ?: userData[@"auth_data"];
                [newAuthData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    user.authData[key] = obj;
                    if (obj != nil) {
                        [user.linkedServiceNames addObject:key];
                    }
                    [user synchronizeAuthDataWithAuthType:key];
                }];
            }
        }
        return nil;
    }];
}

- (BFTask *)_saveSensitiveUserDataAsync:(PFUser *)user toKeychainItemWithName:(NSString *)itemName {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSMutableDictionary *userData = [NSMutableDictionary dictionaryWithCapacity:2];
        @synchronized (user.lock) {
            if (user.sessionToken) {
                userData[PFUserSessionTokenRESTKey] = [user.sessionToken copy];
            }
            if (user.authData.count) {
                userData[PFUserAuthDataRESTKey] = [user.authData copy];
            }
        }
        self.commonDataSource.keychainStore[itemName] = userData;

        return nil;
    }];
}

- (void)_deleteSensitiveUserDataFromKeychainWithItemName:(NSString *)itemName {
    [self.commonDataSource.keychainStore removeObjectForKey:itemName];
}

///--------------------------------------
#pragma mark - Session Token
///--------------------------------------

- (BFTask *)getCurrentUserSessionTokenAsync {
    return [[self getCurrentUserAsyncWithOptions:0] continueWithSuccessBlock:^id(BFTask *task) {
        PFUser *user = task.result;
        return user.sessionToken;
    }];
}

///--------------------------------------
#pragma mark - Lazy Login
///--------------------------------------

- (BFTask *)_lazyLogInUser {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        PFUser *user = [PFAnonymousUtils _lazyLogIn];

        // When LDS is enabled, we will immediately save the anon user to LDS. When LDS is disabled, we
        // will create the anon user, but will lazily save it to Parse on an object save that has this
        // user in its ACL.
        // The main differences here would be that non-LDS may have different anon users in different
        // sessions until an object is saved and LDS will persist the same anon user. This shouldn't be a
        // big deal...
        if (self.storageType == PFCurrentObjectStorageTypeOfflineStore) {
            return [[self _saveCurrentUserAsync:user] continueWithSuccessResult:user];
        }

        dispatch_barrier_sync(self->_dataQueue, ^{
            self->_currentUser = user;
            self->_currentUserMatchesDisk = YES;
        });
        return user;
    }];
}

@end
