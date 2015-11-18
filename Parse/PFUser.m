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

#pragma mark Validation

- (BFTask PF_GENERIC(PFVoid) *)_validateDeleteAsync {
    return [[super _validateDeleteAsync] continueWithSuccessBlock:^id(BFTask PF_GENERIC(PFVoid) *task) {
        if (!self.authenticated) {
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorUserCannotBeAlteredWithoutSession
                                                     message:@"User cannot be deleted unless they have been authenticated."];
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
}

- (BFTask PF_GENERIC(PFVoid) *)_validateSaveEventuallyAsync {
    return [[super _validateSaveEventuallyAsync] continueWithSuccessBlock:^id(BFTask PF_GENERIC(PFVoid) *task) {
        if ([self isDirtyForKey:PFUserPasswordRESTKey]) {
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorOperationForbidden
                                                     message:@"Unable to saveEventually a PFUser with dirty password."];
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
}

#pragma mark Else

- (NSString *)displayClassName {
    if ([self isMemberOfClass:[PFUser class]]) {
        return @"PFUser";
    }
    return NSStringFromClass([self class]);
}

// Validates a class name. We override this to only allow the user class name.
+ (void)_assertValidInstanceClassName:(NSString *)className {
    PFParameterAssert([className isEqualToString:[PFUser parseClassName]],
                      @"Cannot initialize a PFUser with a custom class name.");
}

// Checks the properties on the object before saving.
- (void)_checkSaveParametersWithCurrentUser:(PFUser *)currentUser {
    @synchronized([self lock]) {
        PFConsistencyAssert(self.objectId || self.isLazy,
                            @"User cannot be saved unless they are already signed up. Call signUp first.");

        PFConsistencyAssert([self _isAuthenticatedWithCurrentUser:currentUser] ||
                            [self.objectId isEqualToString:currentUser.objectId],
                            @"User cannot be saved unless they have been authenticated via logIn or signUp", nil);
    }
}

// Checks the properties on the object before signUp.
- (BFTask *)_validateSignUpAsync {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id {
        NSError *error = nil;
        @synchronized (self.lock) {
            if (!self.username) {
                error = [PFErrorUtilities errorWithCode:kPFErrorUsernameMissing
                                                message:@"Cannot sign up without a username."];
            } else if (!self.password) {
                error = [PFErrorUtilities errorWithCode:kPFErrorUserPasswordMissing
                                                message:@"Cannot sign up without a password."];
            } else if (![self isDirty:NO] || self.objectId) {
                error = [PFErrorUtilities errorWithCode:kPFErrorUsernameTaken
                                                message:@"Cannot sign up an existing user."];
            }
        }
        if (error) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
}

- (NSMutableDictionary *)_convertToDictionaryForSaving:(PFOperationSet *)changes
                                     withObjectEncoder:(PFEncoder *)encoder {
    @synchronized([self lock]) {
        NSMutableDictionary *serialized = [super _convertToDictionaryForSaving:changes withObjectEncoder:encoder];
        if (self.authData.count > 0) {
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
    @synchronized([self lock]) {
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
    @synchronized([self lock]) {
        NSDictionary *parameters = [self _convertToDictionaryForSaving:changes
                                                     withObjectEncoder:[PFPointerObjectEncoder objectEncoder]];
        return [PFRESTUserCommand serviceLoginUserCommandWithParameters:parameters
                                                       revocableSession:[[self class] _isRevocableSessionEnabled]
                                                           sessionToken:self.sessionToken];
    }
}

- (BFTask *)_handleServiceLoginCommandResult:(PFCommandResult *)result {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id {
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
    @synchronized([self lock]) {
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
    @synchronized([self lock]) {
        for (NSString *key in [self.authData copy]) {
            id linkData = self.authData[key];
            if (!linkData || linkData == [NSNull null]) {
                [self.authData removeObjectForKey:key];
                [self.linkedServiceNames removeObject:key];

                [[[[self class] authenticationController] restoreAuthenticationAsyncWithAuthData:nil
                                                                                     forAuthType:key] waitForResult:nil withMainThreadWarning:NO];
            }
        }
    }
}

/*!
 Copies special PFUser fields from another user.
 */
- (PFObject *)mergeFromObject:(PFUser *)other {
    @synchronized([self lock]) {
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
    @synchronized([self lock]) {
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
                    self.authData[key] = linkData;
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
    @synchronized([self lock]) {
        if (!self.isCurrentUser) {
            return;
        }

        NSDictionary *data = self.authData[authType];
        BFTask *restoreTask = [[[self class] authenticationController] restoreAuthenticationAsyncWithAuthData:data
                                                                                                  forAuthType:authType];
        [restoreTask waitForResult:nil withMainThreadWarning:NO];
        if (restoreTask.faulted || ![restoreTask.result boolValue]) { // TODO: (nlutsenko) Maybe chain this method?
            [self unlinkWithAuthTypeInBackground:authType];
        }
    }
}

- (void)synchronizeAllAuthData {
    @synchronized([self lock]) {
        // Ensures that all auth providers have auth data (e.g. access tokens, etc.) that matches this user.
        if (self.authData) {
            [self.authData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                [self synchronizeAuthDataWithAuthType:key];
            }];
        }
    }
}

- (BFTask *)resolveLazinessAsync:(BFTask *)toAwait {
    @synchronized([self lock]) {
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

            if (result.httpResponse.statusCode == 201) {
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

- (BFTask *)_logOutAsyncWithAuthType:(NSString *)authType {
    return [[[self class] authenticationController] deauthenticateAsyncWithAuthType:authType];
}

+ (instancetype)logInLazyUserWithAuthType:(NSString *)authType authData:(NSDictionary *)authData {
    PFUser *user = [self user];
    @synchronized([user lock]) {
        [user setIsCurrentUser:YES];
        user.isLazy = YES;
        user.authData[authType] = authData;
        [user.linkedServiceNames addObject:authType];
    }
    return user;
}

- (BFTask *)signUpAsync:(BFTask *)toAwait {
    PFUser *currentUser = [[self class] currentUser];
    NSString *token = currentUser.sessionToken;
    @synchronized([self lock]) {
        if (self.objectId) {
            // For anonymous users, there may be an objectId.  Setting the userName
            // will have removed the anonymous link and set the value in the authData
            // object to [NSNull null], so we can just treat it like a save operation.
            if (self.authData[PFAnonymousUserAuthenticationType] == [NSNull null]) {
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

        return [[self _validateSignUpAsync] continueWithSuccessBlock:^id(BFTask *task) {
            if (currentUser && [PFAnonymousUtils isLinkedWithUser:currentUser]) {
                // self doesn't have any outstanding saves, so we can safely merge its operations
                // into the current user.

                PFConsistencyAssert(!isCurrentUser, @"Attempt to merge currentUser with itself.");

                @synchronized ([currentUser lock]) {
                    NSString *oldUsername = [currentUser.username copy];
                    NSString *oldPassword = [currentUser.password copy];
                    NSArray *oldAnonymousData = currentUser.authData[PFAnonymousUserAuthenticationType];

                    // Move the changes to this object over to the currentUser object.
                    PFOperationSet *selfOperations = operationSetQueue[0];
                    [operationSetQueue removeAllObjects];
                    [operationSetQueue addObject:[[PFOperationSet alloc] init]];
                    for (NSString *key in selfOperations) {
                        currentUser[key] = selfOperations[key];
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
    @synchronized([self lock]) {
        if ([PFAnonymousUtils isLinkedWithUser:self]) {
            NSString *authType = PFAnonymousUserAuthenticationType;

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
    @synchronized([self lock]) {
        if (anonymousData && anonymousData != [NSNull null]) {
            NSString *authType = PFAnonymousUserAuthenticationType;
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
    if (self.isCurrentUser) {
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
    @synchronized([self lock]) {
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
                                operationSetQueue:(NSArray *)queue
                          deletingEventuallyCount:(NSUInteger)deletingEventuallyCount {
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
                                operationSetQueue:cleanQueue
                          deletingEventuallyCount:deletingEventuallyCount];
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
    @synchronized(self.lock) {
        return isCurrentUser;
    }
}

- (void)setIsCurrentUser:(BOOL)aBool {
    @synchronized(self.lock) {
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
#pragma mark - Third-party Authentication
///--------------------------------------

+ (void)registerAuthenticationDelegate:(id<PFUserAuthenticationDelegate>)delegate forAuthType:(NSString *)authType {
    [[self authenticationController] registerAuthenticationDelegate:delegate forAuthType:authType];
}

#pragma mark Log In

+ (BFTask PF_GENERIC(PFUser *)*)logInWithAuthTypeInBackground:(NSString *)authType
                                                     authData:(NSDictionary PF_GENERIC(NSString *, NSString *)*)authData {
    PFParameterAssert(authType, @"Can't log in without `authType`.");
    PFParameterAssert(authData, @"Can't log in without `authData`.");
    PFUserAuthenticationController *controller = [self authenticationController];
    PFConsistencyAssert([controller authenticationDelegateForAuthType:authType],
                        @"No registered authentication delegate found for `%@` authentication type. "
                        @"Register a delegate first via PFUser.registerAuthenticationDelegate(delegate, forAuthType:)",
                        authType);
    return [[self authenticationController] logInUserAsyncWithAuthType:authType authData:authData];
}

#pragma mark Link

- (BFTask PF_GENERIC(NSNumber *)*)linkWithAuthTypeInBackground:(NSString *)authType
                                                      authData:(NSDictionary PF_GENERIC(NSString *, NSString *)*)newAuthData {
    PFParameterAssert(authType, @"Can't link without `authType`.");
    PFParameterAssert(newAuthData, @"Can't link without `authData`.");
    PFUserAuthenticationController *controller = [[self class] authenticationController];
    PFConsistencyAssert([controller authenticationDelegateForAuthType:authType],
                        @"No registered authentication delegate found for `%@` authentication type. "
                        @"Register a delegate first via PFUser.registerAuthenticationDelegate(delegate, forAuthType:)",
                        authType);

    @weakify(self);
    return [self.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [toAwait continueWithBlock:^id(BFTask *task) {
            @strongify(self);

            NSDictionary *oldAnonymousData = nil;

            @synchronized (self.lock) {
                self.authData[authType] = newAuthData;
                [self.linkedServiceNames addObject:authType];

                oldAnonymousData = self.authData[PFAnonymousUserAuthenticationType];
                [self stripAnonymity];

                dirty = YES;
            }

            return [[self saveAsync:nil] continueAsyncWithBlock:^id(BFTask *task) {
                if (task.result) {
                    [self synchronizeAuthDataWithAuthType:authType];
                    return task;
                }

                @synchronized (self.lock) {
                    [self.authData removeObjectForKey:authType];
                    [self.linkedServiceNames removeObject:authType];
                    [self restoreAnonymity:oldAnonymousData];
                }
                // Save the user to disk in case of failure, since we want the latest succeeded data persistent.
                PFCurrentUserController *controller = [[self class] currentUserController];
                return [[controller saveCurrentObjectAsync:self] continueWithBlock:^id(BFTask *_) {
                    return task; // Roll-forward the result of a save to network, not local save.
                }];
            }];
        }];
    }];
}

#pragma mark Unlink

- (BFTask *)unlinkWithAuthTypeInBackground:(NSString *)authType {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id {
        @synchronized (self.lock) {
            if (self.authData[authType]) {
                self.authData[authType] = [NSNull null];
                dirty = YES;
                return [self saveInBackground];
            }
        }
        return @YES;
    }];
}

#pragma mark Linked

- (BOOL)isLinkedWithAuthType:(NSString *)authType {
    PFParameterAssert(authType, @"Authentication type can't be `nil`.");
    @synchronized(self.lock) {
        return [self.linkedServiceNames containsObject:authType];
    }
}

#pragma mark Private

+ (void)_unregisterAuthenticationDelegateForAuthType:(NSString *)authType {
    [[[self class] authenticationController] unregisterAuthenticationDelegateForAuthType:authType];
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
#pragma mark - Revocable Sessions
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
    @synchronized([self lock]) {
        if (!authData) {
            authData = [[NSMutableDictionary alloc] init];
        }
    }
    return authData;
}

- (NSMutableSet *)linkedServiceNames {
    @synchronized([self lock]) {
        if (!linkedServiceNames) {
            linkedServiceNames = [[NSMutableSet alloc] init];
        }
    }
    return linkedServiceNames;
}

+ (instancetype)user {
    return [self object];
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
    if (self.isLazy) {
        return [BFTask taskWithResult:@YES];
    }

    return [[super fetchAsync:toAwait] continueAsyncWithSuccessBlock:^id(BFTask *fetchAsyncTask) {
        if (self.isCurrentUser) {
            [self cleanUpAuthData];
            PFCurrentUserController *controller = [[self class] currentUserController];
            return [[controller saveCurrentObjectAsync:self] continueAsyncWithBlock:^id(BFTask *task) {
                return fetchAsyncTask.result;
            }];
        }
        return fetchAsyncTask.result;
    }];
}

- (instancetype)fetch:(NSError **)error {
    if (self.isLazy) {
        return self;
    }
    return [super fetch:error];
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
    PFUser *currentUser = [[self class] currentUser];
    return [self _isAuthenticatedWithCurrentUser:currentUser];
}

- (BOOL)_isAuthenticatedWithCurrentUser:(PFUser *)currentUser {
    @synchronized([self lock]) {
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
    @synchronized([self lock]) {
        if (self.objectId) {
            // For anonymous users, there may be an objectId.  Setting the userName
            // will have removed the anonymous link and set the value in the authData
            // object to [NSNull null], so we can just treat it like a save operation.
            if (authData[PFAnonymousUserAuthenticationType] == [NSNull null]) {
                [self saveInBackgroundWithBlock:block];
                return;
            }
        }
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

@end
