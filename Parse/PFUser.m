/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUser.h"
#import "PFUserPrivate.h"

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFACLPrivate.h"
#import "PFAnonymousAuthenticationProvider.h"
#import "PFAnonymousUtils_Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFCoreManager.h"
#import "PFCurrentUserController.h"
#import "PFDecoder.h"
#import "PFErrorUtilities.h"
#import "PFFileManager.h"
#import "PFKeychainStore.h"
#import "PFMultiProcessFileLockController.h"
#import "PFMutableUserState.h"
#import "PFObject+Subclass.h"
#import "PFObjectConstants.h"
#import "PFObjectFilePersistenceController.h"
#import "PFObjectPrivate.h"
#import "PFOfflineStore.h"
#import "PFOperationSet.h"
#import "PFQueryPrivate.h"
#import "PFRESTUserCommand.h"
#import "PFSessionUtilities.h"
#import "PFTaskQueue.h"
#import "PFUserAuthenticationController.h"
#import "PFUserConstants.h"
#import "PFUserController.h"
#import "PFUserFileCodingLogic.h"
#import "Parse_Private.h"

NSString *const PFUserCurrentUserFileName = @"currentUser";
NSString *const PFUserCurrentUserPinName = @"_currentUser";
NSString *const PFUserCurrentUserKeychainItemName = @"currentUser";

static BOOL _PFUserIsWritablePropertyForKey(NSString *key) {
    return ![PFUserSessionTokenRESTKey isEqualToString:key];
}

static BOOL _PFUserIsRemovablePropertyForKey(NSString *key) {
    return _PFUserIsWritablePropertyForKey(key) && ![PFUserUsernameRESTKey isEqualToString:key];
}

@interface PFUser () <PFObjectPrivateSubclass>

@property (nonatomic, copy) PFUserState *_state;

@end

@implementation PFUser (Private)

static BOOL revocableSessionEnabled_;

- (void)setDefaultValues {
    [super setDefaultValues];
    self.isCurrentUser = NO;
}

- (BOOL)needsDefaultACL {
    return NO;
}

///--------------------------------------
#pragma mark - Current User
///--------------------------------------

// Returns the session token for the current user.
+ (NSString *)currentSessionToken {
    return [[self _getCurrentUserSessionTokenAsync] waitForResult:nil withMainThreadWarning:NO];
}

+ (BFTask *)_getCurrentUserSessionTokenAsync {
    return [[self currentUserController] getCurrentUserSessionTokenAsync];
}

///--------------------------------------
#pragma mark - PFObject
///--------------------------------------

// Check security on delete
- (void)checkDeleteParams {
    if (![self isAuthenticated]) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"User cannot be deleted unless they have been authenticated via logIn or signUp", nil];
    }

    [super checkDeleteParams];
}

- (NSString *)displayClassName {
    return @"PFUser";
}

// Validates a class name. We override this to only allow the user class name.
+ (void)_assertValidInstanceClassName:(NSString *)className {
    PFParameterAssert([className isEqualToString:[PFUser parseClassName]],
                      @"Cannot initialize a PFUser with a custom class name.");
}

// Checks the properties on the object before saving.
- (void)_checkSaveParametersWithCurrentUser:(PFUser *)currentUser {
    @synchronized ([self lock]) {
        if (!self.objectId && !self.isLazy) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"User cannot be saved unless they are already signed up. Call signUp first.", nil];
        }

        if (![self _isAuthenticatedWithCurrentUser:currentUser]
            && ![self.objectId isEqualToString:currentUser.objectId]) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"User cannot be saved unless they have been authenticated via logIn or signUp", nil];
        }
    }
}

// Checks the properties on the object before signUp.
- (void)checkSignUpParams {
    @synchronized ([self lock]) {
        if (self.username == nil) {
            [NSException raise:NSInternalInconsistencyException format:@"Cannot sign up without a username."];
        }

        if (self.password == nil) {
            [NSException raise:NSInternalInconsistencyException format:@"Cannot sign up without a password."];
        }

        if (![self isDirty:NO] || self.objectId) {
            [NSException raise:NSInternalInconsistencyException format:@"Cannot sign up an existing user."];
        }
    }
}

- (NSMutableDictionary *)_convertToDictionaryForSaving:(PFOperationSet *)changes
                                     withObjectEncoder:(PFEncoder *)encoder {
    @synchronized ([self lock]) {
        NSMutableDictionary *serialized = [super _convertToDictionaryForSaving:changes withObjectEncoder:encoder];
        if ([self.authData count] > 0) {
            serialized[PFUserAuthDataRESTKey] = [self.authData copy];
        }
        return serialized;
    }
}

- (BFTask *)handleSaveResultAsync:(NSDictionary *)result {
    return [[super handleSaveResultAsync:result] continueWithSuccessBlock:^id(BFTask *saveTask) {
        if (self.isCurrentUser) {
            [self cleanUpAuthData];
            PFCurrentUserController *controller = [[self class] currentUserController];
            return [[controller saveCurrentObjectAsync:self] continueWithBlock:^id(BFTask *task) {
                return saveTask.result;
            }];
        }
        return saveTask;
    }];
}

///--------------------------------------
#pragma mark - Sign Up
///--------------------------------------

- (PFRESTCommand *)_currentSignUpCommandForChanges:(PFOperationSet *)changes {
    @synchronized ([self lock]) {
        NSDictionary *parameters = [self _convertToDictionaryForSaving:changes
                                                     withObjectEncoder:[PFPointerObjectEncoder objectEncoder]];
        return [PFRESTUserCommand signUpUserCommandWithParameters:parameters
                                                 revocableSession:[[self class] _isRevocableSessionEnabled]
                                                     sessionToken:self.sessionToken];
    }
}

///--------------------------------------
#pragma mark - Service Login
///--------------------------------------

// Constructs the command for user_signup_or_login. This is used for Facebook, Twitter, and other linking services.
- (PFRESTCommand *)_currentServiceLoginCommandForChanges:(PFOperationSet *)changes {
    @synchronized ([self lock]) {
        NSDictionary *parameters = [self _convertToDictionaryForSaving:changes
                                                     withObjectEncoder:[PFPointerObjectEncoder objectEncoder]];
        return [PFRESTUserCommand serviceLoginUserCommandWithParameters:parameters
                                                       revocableSession:[[self class] _isRevocableSessionEnabled]
                                                           sessionToken:self.sessionToken];
    }
}

- (BFTask *)_handleServiceLoginCommandResult:(PFCommandResult *)result {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        NSDictionary *resultDictionary = result.result;
        return [[self handleSaveResultAsync:resultDictionary] continueWithBlock:^id(BFTask *task) {
            BOOL new = (result.httpResponse.statusCode == 201); // 201 means Created
            @synchronized (self.lock) {
                if (self._state.isNew != new) {
                    PFMutableUserState *state = [self._state mutableCopy];
                    state.isNew = new;
                    self._state = state;
                }
                if (resultDictionary) {
                    self.isLazy = NO;

                    // Serialize the object to disk so we can later access it via currentUser
                    PFCurrentUserController *controller = [[self class] currentUserController];
                    return [[controller saveCurrentObjectAsync:self] continueAsyncWithBlock:^id(BFTask *task) {
                        [self.saveDelegate invoke:self error:nil];
                        return self;
                    }];
                }
                return [BFTask taskWithResult:self];
            }
        }];
    }];
}

// Override the save result handling with custom user functionality
- (BFTask *)handleSignUpResultAsync:(BFTask *)task {
    @synchronized ([self lock]) {
        PFCommandResult *commandResult = task.result;
        NSDictionary *result = commandResult.result;
        BFTask *signUpTask = task;

        // Bail-out early, but still make sure that super class handled the result
        if (task.error || task.cancelled || task.exception) {
            return [[super handleSaveResultAsync:nil] continueWithBlock:^id(BFTask *task) {
                return signUpTask;
            }];
        }
        __block BOOL saveResult = NO;
        return [[[super handleSaveResultAsync:result] continueWithBlock:^id(BFTask *task) {
            saveResult = [task.result boolValue];
            if (saveResult) {
                @synchronized (self.lock) {
                    // Save the session information
                    PFMutableUserState *state = [self._state mutableCopy];
                    state.sessionToken = result[PFUserSessionTokenRESTKey];
                    state.isNew = YES;
                    self._state = state;
                    self.isLazy = NO;
                }
            }
            return signUpTask;
        }] continueWithBlock:^id(BFTask *task) {
            PFCurrentUserController *controller = [[self class] currentUserController];
            return [[controller saveCurrentObjectAsync:self] continueWithResult:@(saveResult)];
        }];
    }
}

- (void)cleanUpAuthData {
    @synchronized ([self lock]) {
        for (NSString *key in [self.authData copy]) {
            id linkData = [self.authData objectForKey:key];
            if (!linkData || linkData == [NSNull null]) {
                [self.authData removeObjectForKey:key];
                [self.linkedServiceNames removeObject:key];

                [[[self class] authenticationController] restoreAuthenticationWithAuthData:nil
                                                                   withProviderForAuthType:key];
            }
        }
    }
}

/*!
 Copies special PFUser fields from another user.
 */
- (PFObject *)mergeFromObject:(PFUser *)other {
    @synchronized ([self lock]) {
        [super mergeFromObject:other];

        if (self == other) {
            // If they point to the same instance, then don't merge.
            return self;
        }

        PFMutableUserState *state = [self._state mutableCopy];
        state.sessionToken = other.sessionToken;
        state.isNew = other._state.isNew;
        self._state = state;

        [self.authData removeAllObjects];
        [self.authData addEntriesFromDictionary:other.authData];

        [self.linkedServiceNames removeAllObjects];
        [self.linkedServiceNames unionSet:other.linkedServiceNames];

        return self;
    }
}

/*
 Merges custom fields from JSON associated with a PFUser:
 {
 "session_token": string,
 "is_new": boolean,
 "auth_data": {
 "facebook": {
 "id": string,
 "access_token": string,
 "expiration_date": string (represents date)
 }
 }
 }
 */
- (void)_mergeFromServerWithResult:(NSDictionary *)result decoder:(PFDecoder *)decoder completeData:(BOOL)completeData {
    @synchronized ([self lock]) {
        // save the session token

        PFMutableUserState *state = [self._state mutableCopy];

        NSString *newSessionToken = result[PFUserSessionTokenRESTKey];
        if (newSessionToken) {
            // Save the session token
            state.sessionToken = newSessionToken;
        }

        self._state = state;

        // Merge the linked service metadata
        NSDictionary *newAuthData = [decoder decodeObject:result[PFUserAuthDataRESTKey]];
        if (newAuthData) {
            [self.authData removeAllObjects];
            [self.linkedServiceNames removeAllObjects];
            [newAuthData enumerateKeysAndObjectsUsingBlock:^(id key, id linkData, BOOL *stop) {
                if (linkData != [NSNull null]) {
                    [self.authData setObject:linkData forKey:key];
                    [self.linkedServiceNames addObject:key];
                    [self synchronizeAuthDataWithAuthType:key];
                } else {
                    [self.authData removeObjectForKey:key];
                    [self.linkedServiceNames removeObject:key];
                    [self synchronizeAuthDataWithAuthType:key];
                }
            }];
        }

        // Strip authData and sessionToken from the data, as those keys are saved in a custom way
        NSMutableDictionary *serverData = [result mutableCopy];
        [serverData removeObjectForKey:PFUserSessionTokenRESTKey];
        [serverData removeObjectForKey:PFUserAuthDataRESTKey];

        // The public fields are handled by the regular mergeFromServer
        [super _mergeFromServerWithResult:serverData decoder:decoder completeData:completeData];
    }
}

- (void)synchronizeAuthDataWithAuthType:(NSString *)authType {
    @synchronized ([self lock]) {
        if (!self.isCurrentUser) {
            return;
        }

        NSDictionary *data = self.authData[authType];
        BOOL authRestored = [[[self class] authenticationController] restoreAuthenticationWithAuthData:data
                                                                               withProviderForAuthType:authType];
        if (!authRestored) {
            [self _unlinkWithAuthTypeInBackground:authType];
        }
    }
}

- (void)synchronizeAllAuthData {
    @synchronized ([self lock]) {
        // Ensures that all auth providers have auth data (e.g. access tokens, etc.) that matches this user.
        if (self.authData) {
            [self.authData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [self synchronizeAuthDataWithAuthType:key];
            }];
        }
    }
}

+ (BFTask *)_logInWithAuthTypeInBackground:(NSString *)authType authData:(NSDictionary *)authData {
    // Handle claiming of user.
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser && [PFAnonymousUtils isLinkedWithUser:currentUser]) {
        if ([currentUser isLazy]) {
            PFUser *user = currentUser;
            BFTask *resolveLaziness = nil;
            NSDictionary *oldAnonymousData = nil;
            @synchronized ([user lock]) {
                oldAnonymousData = user.authData[[PFAnonymousAuthenticationProvider authType]];

                // Replace any anonymity with the new linked authData
                [user stripAnonymity];

                [user.authData setObject:authData forKey:authType];
                [user.linkedServiceNames addObject:authType];

                resolveLaziness = [user resolveLazinessAsync:[BFTask taskWithResult:nil]];
            }

            return [resolveLaziness continueAsyncWithBlock:^id(BFTask *task) {
                if (task.isCancelled || task.exception || task.error) {
                    [user.authData removeObjectForKey:authType];
                    [user.linkedServiceNames removeObject:authType];
                    [user restoreAnonymity:oldAnonymousData];
                    return task;
                }
                return task.result;
            }];
        } else {
            return [[currentUser _linkWithAuthTypeInBackground:authType
                                                      authData:authData] continueAsyncWithBlock:^id(BFTask *task) {
                NSError *error = task.error;
                if (error) {
                    if (error.code == kPFErrorAccountAlreadyLinked) {
                        // An account that's linked to the given authData already exists,
                        // so log in instead of trying to claim.
                        return [[self userController] logInCurrentUserAsyncWithAuthType:authType
                                                                               authData:authData
                                                                       revocableSession:[self _isRevocableSessionEnabled]];
                    } else {
                        return task;
                    }
                }

                return [BFTask taskWithResult:currentUser];
            }];
        }
    }
    return [[self userController] logInCurrentUserAsyncWithAuthType:authType
                                                           authData:authData
                                                   revocableSession:[self _isRevocableSessionEnabled]];
}

- (BFTask *)resolveLazinessAsync:(BFTask *)toAwait {
    @synchronized ([self lock]) {
        if (!self.isLazy) {
            return [BFTask taskWithResult:self];
        }
        if (self.linkedServiceNames.count == 0) {
            // If there are no linked services, treat this like a sign-up.
            return [[self signUpAsync:toAwait] continueAsyncWithSuccessBlock:^id(BFTask *task) {
                self.isLazy = NO;
                return self;
            }];
        }

        // Otherwise, treat this as a SignUpOrLogIn
        PFRESTCommand *command = [self _currentServiceLoginCommandForChanges:[self unsavedChanges]];
        [self startSave];

        return [[toAwait continueAsyncWithBlock:^id(BFTask *task) {
            return [[Parse _currentManager].commandRunner runCommandAsync:command withOptions:0];
        }] continueAsyncWithBlock:^id(BFTask *task) {
            PFCommandResult *result = task.result;

            if (task.error || task.cancelled) {
                // If there was an error, we want to roll forward the save changes, but return the original task.
                return [[self _handleServiceLoginCommandResult:result] continueAsyncWithBlock:^id(BFTask *unused) {
                    // Return the original task, instead of the new one (in order to have a proper error)
                    return task;
                }];
            }

            if ([result.httpResponse statusCode] == 201) {
                return [self _handleServiceLoginCommandResult:result];
            } else {
                // Otherwise, treat this as a fresh login, and switch the current user to the new user.
                PFUser *newUser = [[self class] _objectFromDictionary:result.result
                                                     defaultClassName:[self parseClassName]
                                                         completeData:YES];
                @synchronized ([newUser lock]) {
                    [newUser startSave];
                    return [newUser _handleServiceLoginCommandResult:result];
                }
            }
        }];
    }
}

- (BFTask *)_linkWithAuthTypeInBackground:(NSString *)authType authData:(NSDictionary *)newAuthData {
    @weakify(self);
    return [self.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [toAwait continueWithBlock:^id(BFTask *task) {
            @strongify(self);

            NSDictionary *oldAnonymousData = nil;

            @synchronized (self.lock) {
                self.authData[authType] = newAuthData;
                [self.linkedServiceNames addObject:authType];

                oldAnonymousData = self.authData[[PFAnonymousAuthenticationProvider authType]];
                [self stripAnonymity];

                dirty = YES;
            }

            return [[self saveAsync:nil] continueAsyncWithBlock:^id(BFTask *task) {
                if (task.result) {
                    [self synchronizeAuthDataWithAuthType:authType];
                } else {
                    @synchronized (self.lock) {
                        [self.authData removeObjectForKey:authType];
                        [self.linkedServiceNames removeObject:authType];
                        [self restoreAnonymity:oldAnonymousData];
                    }
                }
                return task;
            }];
        }];
    }];
}

- (BFTask *)_logOutAsyncWithAuthType:(NSString *)authType {
    return [[[self class] authenticationController] deauthenticateAsyncWithProviderForAuthType:authType];
}

- (BFTask *)_unlinkWithAuthTypeInBackground:(NSString *)authType {
    BFTask *save = nil;
    @synchronized ([self lock]) {
        if (!self.authData[authType]) {
            save = [BFTask taskWithResult:@YES];
        } else {
            self.authData[authType] = [NSNull null];
            dirty = YES;
            save = [self saveInBackground];
        }
    }
    return save;
}

+ (instancetype)logInLazyUserWithAuthType:(NSString *)authType authData:(NSDictionary *)authData {
    PFUser *user = [PFUser user];
    @synchronized ([user lock]) {
        [user setIsCurrentUser:YES];
        user.isLazy = YES;
        [user.authData setObject:authData forKey:authType];
        [user.linkedServiceNames addObject:authType];
    }
    return user;
}

- (BFTask *)signUpAsync:(BFTask *)toAwait {
    PFUser *currentUser = [PFUser currentUser];
    NSString *token = currentUser.sessionToken;
    @synchronized ([self lock]) {
        if (self.objectId) {
            // For anonymous users, there may be an objectId.  Setting the userName
            // will have removed the anonymous link and set the value in the authData
            // object to [NSNull null], so we can just treat it like a save operation.
            if (self.authData[[PFAnonymousAuthenticationProvider authType]] == [NSNull null]) {
                return [self saveAsync:toAwait];
            }

            // Otherwise, return an error
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorUsernameTaken
                                                    message:@"Cannot sign up a user that has already signed up."];
            return [BFTask taskWithError:error];
        }

        // If the operationSetQueue is has operation sets in it, then a save or signUp is in progress.
        // If there is a signUp or save already in progress, don't allow another one to start.
        if ([self _hasOutstandingOperations]) {
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorUsernameTaken
                                                    message:@"Cannot sign up a user that is already signing up."];
            return [BFTask taskWithError:error];
        }

        return [BFTask taskFromExecutor:[BFExecutor immediateExecutor] withBlock:^id{
            [self checkSignUpParams];
            if (currentUser && [PFAnonymousUtils isLinkedWithUser:currentUser]) {
                // self doesn't have any outstanding saves, so we can safely merge its operations
                // into the current user.

                PFConsistencyAssert(!isCurrentUser, @"Attempt to merge currentUser with itself.");

                [self checkForChangesToMutableContainers];
                @synchronized ([currentUser lock]) {
                    NSString *oldUsername = [currentUser.username copy];
                    NSString *oldPassword = [currentUser.password copy];
                    NSArray *oldAnonymousData = currentUser.authData[[PFAnonymousAuthenticationProvider authType]];

                    [currentUser checkForChangesToMutableContainers];

                    // Move the changes to this object over to the currentUser object.
                    PFOperationSet *selfOperations = operationSetQueue[0];
                    [operationSetQueue removeAllObjects];
                    [operationSetQueue addObject:[[PFOperationSet alloc] init]];
                    for (NSString *key in selfOperations) {
                        [currentUser setObject:[selfOperations objectForKey:key] forKey:key];
                    }

                    currentUser->dirty = YES;
                    currentUser.password = self.password;
                    currentUser.username = self.username;

                    [self rebuildEstimatedData];
                    [currentUser rebuildEstimatedData];

                    return [[[[currentUser saveInBackground] continueWithBlock:^id(BFTask *task) {
                        if (task.error || task.cancelled || task.exception) {
                            @synchronized ([currentUser lock]) {
                                if (oldUsername) {
                                    currentUser.username = oldUsername;
                                }
                                currentUser.password = oldPassword;
                                [currentUser restoreAnonymity:oldAnonymousData];
                            }

                            @synchronized(self.lock) {
                                [operationSetQueue replaceObjectAtIndex:0 withObject:selfOperations];
                                [self rebuildEstimatedData];
                            }
                        }
                        return task;
                    }] continueWithSuccessBlock:^id(BFTask *task) {
                        if ([Parse _currentManager].offlineStoreLoaded) {
                            return [[Parse _currentManager].offlineStore deleteDataForObjectAsync:currentUser];
                        }
                        return nil;
                    }] continueWithSuccessBlock:^id(BFTask *task) {
                        [self mergeFromObject:currentUser];
                        PFCurrentUserController *controller = [[self class] currentUserController];
                        return [[controller saveCurrentObjectAsync:self] continueWithResult:@YES];
                    }];
                }
            }
            // Use a nil session token for objects saved during a signup.
            BFTask *saveChildren = [self _saveChildrenInBackgroundWithCurrentUser:currentUser sessionToken:token];
            PFOperationSet *changes = [self unsavedChanges];
            [self startSave];

            return [[[toAwait continueWithBlock:^id(BFTask *task) {
                return saveChildren;
            }] continueWithSuccessBlock:^id(BFTask *task) {
                // We need to construct the signup command lazily, because saving the children
                // may change the way the object itself is serialized.
                PFRESTCommand *command = [self _currentSignUpCommandForChanges:changes];
                return [[Parse _currentManager].commandRunner runCommandAsync:command
                                                                  withOptions:PFCommandRunningOptionRetryIfFailed];
            }] continueWithBlock:^id(BFTask *task) {
                return [self handleSignUpResultAsync:task];
            }];
        }];
    }
}

- (void)stripAnonymity {
    @synchronized ([self lock]) {
        if ([PFAnonymousUtils isLinkedWithUser:self]) {
            NSString *authType = [PFAnonymousAuthenticationProvider authType];

            [self.linkedServiceNames removeObject:authType];

            if (self.objectId) {
                self.authData[authType] = [NSNull null];
            } else {
                [self.authData removeObjectForKey:authType];
            }
            dirty = YES;
        }
    }
}

- (void)restoreAnonymity:(id)anonymousData {
    @synchronized ([self lock]) {
        if (anonymousData && anonymousData != [NSNull null]) {
            NSString *authType = [PFAnonymousAuthenticationProvider authType];
            [self.linkedServiceNames addObject:authType];
            self.authData[authType] = anonymousData;
        }
    }
}

///--------------------------------------
#pragma mark - Saving
///--------------------------------------

- (PFRESTCommand *)_constructSaveCommandForChanges:(PFOperationSet *)changes
                                      sessionToken:(NSString *)token
                                     objectEncoder:(PFEncoder *)encoder {
    // If we are curent user - use the latest available session token, as it might have been changed since
    // this command was enqueued.
    if ([self isCurrentUser]) {
        token = self.sessionToken;
    }
    return [super _constructSaveCommandForChanges:changes
                                     sessionToken:token
                                    objectEncoder:encoder];
}

///--------------------------------------
#pragma mark - REST operations
///--------------------------------------

- (void)mergeFromRESTDictionary:(NSDictionary *)object withDecoder:(PFDecoder *)decoder {
    @synchronized ([self lock]) {
        NSMutableDictionary *restDictionary = [object mutableCopy];

        PFMutableUserState *state = [self._state mutableCopy];
        if (object[PFUserSessionTokenRESTKey] != nil) {
            state.sessionToken = object[PFUserSessionTokenRESTKey];
            [restDictionary removeObjectForKey:PFUserSessionTokenRESTKey];
        }

        if (object[PFUserAuthDataRESTKey] != nil) {
            NSDictionary *newAuthData = object[PFUserAuthDataRESTKey];
            [newAuthData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                self.authData[key] = obj;
                if (obj != nil) {
                    [self.linkedServiceNames addObject:key];
                }
                [self synchronizeAuthDataWithAuthType:key];
            }];

            [restDictionary removeObjectForKey:PFUserAuthDataRESTKey];
        }

        self._state = state;

        [super mergeFromRESTDictionary:restDictionary withDecoder:decoder];
    }
}

- (NSDictionary *)RESTDictionaryWithObjectEncoder:(PFEncoder *)objectEncoder
                                operationSetUUIDs:(NSArray **)operationSetUUIDs
                                            state:(PFObjectState *)state
                                operationSetQueue:(NSArray *)queue {
    @synchronized (self.lock) {
        NSMutableArray *cleanQueue = [queue mutableCopy];
        [queue enumerateObjectsUsingBlock:^(PFOperationSet *operationSet, NSUInteger idx, BOOL *stop) {
            // Remove operations for `password` field, to not let it persist to LDS.
            if (operationSet[PFUserPasswordRESTKey]) {
                operationSet = [operationSet copy];
                [operationSet removeObjectForKey:PFUserPasswordRESTKey];

                cleanQueue[idx] = operationSet;
            }
        }];
        return [super RESTDictionaryWithObjectEncoder:objectEncoder
                                    operationSetUUIDs:operationSetUUIDs
                                                state:state
                                    operationSetQueue:cleanQueue];
    }
}

///--------------------------------------
#pragma mark - Revocable Session
///--------------------------------------

+ (dispatch_queue_t)_revocableSessionSynchronizationQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.parse.user.revocableSession", DISPATCH_QUEUE_CONCURRENT);
    });
    return queue;
}

+ (BOOL)_isRevocableSessionEnabled {
    __block BOOL value = NO;
    dispatch_sync([self _revocableSessionSynchronizationQueue], ^{
        value = revocableSessionEnabled_;
    });
    return value;
}

+ (void)_setRevocableSessionEnabled:(BOOL)enabled {
    dispatch_barrier_sync([self _revocableSessionSynchronizationQueue], ^{
        revocableSessionEnabled_ = enabled;
    });
}

+ (BFTask *)_upgradeToRevocableSessionInBackground {
    PFCurrentUserController *controller = [[self class] currentUserController];
    return [[controller getCurrentUserAsyncWithOptions:0] continueWithSuccessBlock:^id(BFTask *task) {
        PFUser *currentUser = task.result;
        NSString *sessionToken = currentUser.sessionToken;

        // Bail-out early if session token is already revocable.
        if ([PFSessionUtilities isSessionTokenRevocable:sessionToken]) {
            return [BFTask taskWithResult:currentUser];
        }
        return [currentUser _upgradeToRevocableSessionInBackground];
    }];
}

- (BFTask *)_upgradeToRevocableSessionInBackground {
    @weakify(self);
    return [self.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
            @strongify(self);

            NSString *token = nil;
            @synchronized(self.lock) {
                token = self.sessionToken;
            }

            // Check session token here as well, to make sure we didn't upgrade the token in between.
            if ([PFSessionUtilities isSessionTokenRevocable:token]) {
                return [BFTask taskWithResult:self];
            }

            PFRESTCommand *command = [PFRESTUserCommand upgradeToRevocableSessionCommandWithSessionToken:token];
            return [[[Parse _currentManager].commandRunner runCommandAsync:command
                                                               withOptions:0] continueWithSuccessBlock:^id(BFTask *task) {
                NSDictionary *dictionary = [task.result result];
                PFSession *session = [PFSession _objectFromDictionary:dictionary
                                                     defaultClassName:[PFSession parseClassName]
                                                         completeData:YES];
                @synchronized(self.lock) {
                    PFMutableUserState *state = [self._state mutableCopy];
                    state.sessionToken = session.sessionToken;
                    self._state = state;
                }
                PFCurrentUserController *controller = [[self class] currentUserController];
                return [controller saveCurrentObjectAsync:self];
            }];
        }];
    }];
}

///--------------------------------------
#pragma mark - Data Source
///--------------------------------------

+ (PFObjectFileCodingLogic *)objectFileCodingLogic {
    return [PFUserFileCodingLogic codingLogic];
}

+ (PFUserAuthenticationController *)authenticationController {
    return [Parse _currentManager].coreManager.userAuthenticationController;
}

+ (PFUserController *)userController {
    return [Parse _currentManager].coreManager.userController;
}

@end

@implementation PFUser

@dynamic _state;

// PFUser:
@dynamic username;
@dynamic email;
@dynamic password;

// PFUser (Private):
@dynamic authData;
@dynamic linkedServiceNames;
@dynamic isLazy;

+ (NSString *)parseClassName {
    return @"_User";
}

+ (instancetype)currentUser {
    PFCurrentUserController *controller = [[self class] currentUserController];
    return [[controller getCurrentObjectAsync] waitForResult:nil withMainThreadWarning:NO];
}

- (BOOL)isCurrentUser {
    @synchronized (self.lock) {
        return isCurrentUser;
    }
}

- (void)setIsCurrentUser:(BOOL)aBool {
    @synchronized (self.lock) {
        isCurrentUser = aBool;
    }
}

///--------------------------------------
#pragma mark - Log In
///--------------------------------------

+ (instancetype)logInWithUsername:(NSString *)username password:(NSString *)password {
    return [self logInWithUsername:username password:password error:nil];
}

+ (instancetype)logInWithUsername:(NSString *)username password:(NSString *)password error:(NSError **)error {
    return [[self logInWithUsernameInBackground:username password:password] waitForResult:error];
}

+ (BFTask *)logInWithUsernameInBackground:(NSString *)username password:(NSString *)password {
    return [[self userController] logInCurrentUserAsyncWithUsername:username
                                                           password:password
                                                   revocableSession:[self _isRevocableSessionEnabled]];
}

+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
                                block:(PFUserResultBlock)block {
    [[self logInWithUsernameInBackground:username password:password] thenCallBackOnMainThreadAsync:block];
}

+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
                               target:(id)target
                             selector:(SEL)selector {
    [self logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:user object:error];
    }];
}

///--------------------------------------
#pragma mark - Become
///--------------------------------------

+ (instancetype)become:(NSString *)sessionToken {
    return [self become:sessionToken error:nil];
}

+ (instancetype)become:(NSString *)sessionToken error:(NSError **)error {
    return [[self becomeInBackground:sessionToken] waitForResult:error];
}

+ (BFTask *)becomeInBackground:(NSString *)sessionToken {
    PFParameterAssert(sessionToken, @"Session Token must be provided for login.");
    return [[self userController] logInCurrentUserAsyncWithSessionToken:sessionToken];
}

+ (void)becomeInBackground:(NSString *)sessionToken block:(PFUserResultBlock)block {
    [[self becomeInBackground:sessionToken] thenCallBackOnMainThreadAsync:block];
}

+ (void)becomeInBackground:(NSString *)sessionToken target:(id)target selector:(SEL)selector {
    [self becomeInBackground:sessionToken block:^(PFUser *user, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:user object:error];
    }];
}

///--------------------------------------
#pragma mark - Revocable SEssions
///--------------------------------------

+ (BFTask *)enableRevocableSessionInBackground {
    if ([self _isRevocableSessionEnabled]) {
        return [BFTask taskWithResult:nil];
    }
    [self _setRevocableSessionEnabled:YES];
    return [self _upgradeToRevocableSessionInBackground];
}

+ (void)enableRevocableSessionInBackgroundWithBlock:(PFUserSessionUpgradeResultBlock)block {
    [[self enableRevocableSessionInBackground] continueWithBlock:^id(BFTask *task) {
        block(task.error);
        return nil;
    }];
}

///--------------------------------------
#pragma mark - Request Password Reset
///--------------------------------------

+ (BOOL)requestPasswordResetForEmail:(NSString *)email {
    return [self requestPasswordResetForEmail:email error:nil];
}

+ (BOOL)requestPasswordResetForEmail:(NSString *)email error:(NSError **)error {
    return [[[self requestPasswordResetForEmailInBackground:email] waitForResult:error] boolValue];
}

+ (BFTask *)requestPasswordResetForEmailInBackground:(NSString *)email {
    PFParameterAssert(email, @"Email should be provided to request password reset.");
    return [[[self userController] requestPasswordResetAsyncForEmail:email] continueWithSuccessResult:@YES];
}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email block:(PFBooleanResultBlock)block {
    [[self requestPasswordResetForEmailInBackground:email] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email target:(id)target selector:(SEL)selector {
    [self requestPasswordResetForEmailInBackground:email block:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

///--------------------------------------
#pragma mark - Logging out
///--------------------------------------

+ (void)logOut {
    [[self logOutInBackground] waitForResult:nil withMainThreadWarning:NO];
}

+ (BFTask *)logOutInBackground {
    PFCurrentUserController *controller = [[self class] currentUserController];
    return [controller logOutCurrentUserAsync];
}

+ (void)logOutInBackgroundWithBlock:(PFUserLogoutResultBlock)block {
    [[self logOutInBackground] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        block(task.error);
        return nil;
    }];
}

- (BFTask *)_logOutAsync {
    //TODO: (nlutsenko) Maybe add this to `taskQueue`?

    NSString *token = nil;
    NSMutableArray *tasks = [NSMutableArray array];
    @synchronized(self.lock) {
        [self.authData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            BFTask *task = [self _logOutAsyncWithAuthType:key];
            [tasks addObject:task];
        }];

        self.isCurrentUser = NO;

        token = [self.sessionToken copy];

        PFMutableUserState *state = [self._state mutableCopy];
        state.sessionToken = nil;
        self._state = state;
    }

    BFTask *task = [BFTask taskForCompletionOfAllTasks:tasks];

    if ([PFSessionUtilities isSessionTokenRevocable:token]) {
        return [task continueWithExecutor:[BFExecutor defaultExecutor] withBlock:^id(BFTask *task) {
            return [[[self class] userController] logOutUserAsyncWithSessionToken:token];
        }];
    }
    return task;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setObject:(id)object forKey:(NSString *)key {
    PFParameterAssert(_PFUserIsWritablePropertyForKey(key),
                      @"Can't remove the '%@' field of a PFUser.", key);
    if ([key isEqualToString:PFUserUsernameRESTKey]) {
        [self stripAnonymity];
    }
    [super setObject:object forKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    PFParameterAssert(_PFUserIsRemovablePropertyForKey(key),
                      @"Can't remove the '%@' field of a PFUser.", key);
    [super removeObjectForKey:key];
}

- (NSMutableDictionary *)authData {
    @synchronized ([self lock]) {
        if (!authData) {
            authData = [[NSMutableDictionary alloc] init];
        }
    }
    return authData;
}

- (NSMutableSet *)linkedServiceNames {
    @synchronized ([self lock]) {
        if (!linkedServiceNames) {
            linkedServiceNames = [[NSMutableSet alloc] init];
        }
    }
    return linkedServiceNames;
}

+ (instancetype)user {
    return (PFUser *)[PFUser object];
}

- (BFTask *)saveAsync:(BFTask *)toAwait {
    if (!toAwait) {
        toAwait = [BFTask taskWithResult:nil];
    }

    // This breaks a rare deadlock scenario where on one thread, user.lock is acquired before taskQueue.lock sometimes,
    // but not always. Using continueAsyncWithBlock unlocks from the taskQueue, and solves the proplem.
    return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
        @synchronized ([self lock]) {
            if (self.isLazy) {
                return [[self resolveLazinessAsync:toAwait] continueAsyncWithSuccessBlock:^id(BFTask *task) {
                    return @(!!task.result);
                }];
            }
        }

        return [super saveAsync:toAwait];
    }];
}

- (BFTask *)fetchAsync:(BFTask *)toAwait {
    if ([self isLazy]) {
        return [BFTask taskWithResult:@YES];
    }

    return [[super fetchAsync:toAwait] continueAsyncWithSuccessBlock:^id(BFTask *fetchAsyncTask) {
        if ([self isCurrentUser]) {
            [self cleanUpAuthData];
            PFCurrentUserController *controller = [[self class] currentUserController];
            return [[controller saveCurrentObjectAsync:self] continueAsyncWithBlock:^id(BFTask *task) {
                return fetchAsyncTask.result;
            }];
        }
        return fetchAsyncTask.result;
    }];
}

- (void)fetch:(NSError **)error {
    if (self.isLazy) {
        return;
    }
    [super fetch:error];
}

- (void)fetchInBackgroundWithBlock:(PFObjectResultBlock)block {
    if (self.isLazy) {
        if (block) {
            block(self, nil);
            return;
        }
    }
    [super fetchInBackgroundWithBlock:^(PFObject *result, NSError *error) {
        if (block) {
            block(result, error);
        }
    }];
}

- (BOOL)signUp {
    return [self signUp:nil];
}

- (BOOL)signUp:(NSError **)error {
    return [[[self signUpInBackground] waitForResult:error] boolValue];
}

- (BFTask *)signUpInBackground {
    return [self.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [self signUpAsync:toAwait];
    }];
}

- (void)signUpInBackgroundWithTarget:(id)target selector:(SEL)selector {
    [self signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

- (BOOL)isAuthenticated {
    PFUser *currentUser = [PFUser currentUser];
    return [self _isAuthenticatedWithCurrentUser:currentUser];
}

- (BOOL)_isAuthenticatedWithCurrentUser:(PFUser *)currentUser {
    @synchronized ([self lock]) {
        BOOL authenticated = self.isLazy || self.sessionToken;
        if (!authenticated && currentUser != nil) {
            authenticated = [self.objectId isEqualToString:currentUser.objectId];
        } else {
            authenticated = self.isCurrentUser;
        }
        return authenticated;
    }
}

- (BOOL)isNew {
    return self._state.isNew;
}

- (NSString *)sessionToken {
    return self._state.sessionToken;
}

- (void)signUpInBackgroundWithBlock:(PFBooleanResultBlock)block {
    @synchronized ([self lock]) {
        if (self.objectId) {
            // For anonymous users, there may be an objectId.  Setting the userName
            // will have removed the anonymous link and set the value in the authData
            // object to [NSNull null], so we can just treat it like a save operation.
            if (authData[[PFAnonymousAuthenticationProvider authType]] == [NSNull null]) {
                [self saveInBackgroundWithBlock:block];
                return;
            }
        }
        [self checkSignUpParams];
        [[self signUpInBackground] thenCallBackOnMainThreadWithBoolValueAsync:block];
    }
}

+ (void)enableAutomaticUser {
    [Parse _currentManager].coreManager.currentUserController.automaticUsersEnabled = YES;
}

///--------------------------------------
#pragma mark - PFObjectPrivateSubclass
///--------------------------------------

#pragma mark State

+ (PFObjectState *)_newObjectStateWithParseClassName:(NSString *)className
                                            objectId:(NSString *)objectId
                                          isComplete:(BOOL)complete {
    return [PFUserState stateWithParseClassName:className objectId:objectId isComplete:complete];
}

#pragma mark Validation

- (BFTask *)_validateSaveEventuallyAsync {
    if ([self isDirtyForKey:PFUserPasswordRESTKey]) {
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorOperationForbidden
                                                message:@"Unable to saveEventually a PFUser with dirty password."];
        return [BFTask taskWithError:error];
    }
    return [BFTask taskWithResult:nil];
}

@end
