/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
#import "PFAssert.h"
#import "PFUserController.h"

#import "BFTask+Private.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFCurrentUserController.h"
#import "PFErrorUtilities.h"
#import "PFMacros.h"
#import "PFObjectPrivate.h"
#import "PFRESTUserCommand.h"
#import "PFUserPrivate.h"

@implementation PFUserController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                          coreDataSource:(id<PFCurrentUserControllerProvider>)coreDataSource {
    self = [super init];
    if (!self) return nil;

    _commonDataSource = commonDataSource;
    _coreDataSource = coreDataSource;

    return self;
}

+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                                coreDataSource:(id<PFCurrentUserControllerProvider>)coreDataSource {
    return [[self alloc] initWithCommonDataSource:commonDataSource
                                   coreDataSource:coreDataSource];
}

///--------------------------------------
#pragma mark - Log In
///--------------------------------------

- (BFTask *)logInCurrentUserAsyncWithSessionToken:(NSString *)sessionToken {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        NSError *error = nil;
        PFRESTCommand *command = [PFRESTUserCommand getCurrentUserCommandWithSessionToken:sessionToken error:&error];
        PFPreconditionReturnFailedTask(command, error);
        return [self.commonDataSource.commandRunner runCommandAsync:command
                                                        withOptions:PFCommandRunningOptionRetryIfFailed];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        PFCommandResult *result = task.result;
        NSDictionary *dictionary = result.result;

        // We test for a null object, if it isn't, we can use the response to create a PFUser.
        if ([dictionary isKindOfClass:[NSNull class]] || !dictionary) {
            return [BFTask taskWithError:[PFErrorUtilities errorWithCode:kPFErrorObjectNotFound
                                                                 message:@"Invalid Session Token."]];
        }

        PFUser *user = [PFUser _objectFromDictionary:dictionary
                                    defaultClassName:[PFUser parseClassName]
                                        completeData:YES];
        // Serialize the object to disk so we can later access it via currentUser
        PFCurrentUserController *controller = self.coreDataSource.currentUserController;
        return [[controller saveCurrentObjectAsync:user] continueWithBlock:^id(BFTask *task) {
            return user;
        }];
    }];
}

- (BFTask *)logInCurrentUserAsyncWithUsername:(NSString *)username
                                     password:(NSString *)password
                             revocableSession:(BOOL)revocableSession {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSError *error = nil;
        PFRESTCommand *command = [PFRESTUserCommand logInUserCommandWithUsername:username
                                                                        password:password
                                                                revocableSession:revocableSession
                                                                           error:&error];
        PFPreconditionReturnFailedTask(command, error);
        return [self.commonDataSource.commandRunner runCommandAsync:command
                                                        withOptions:PFCommandRunningOptionRetryIfFailed];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        PFCommandResult *result = task.result;
        NSDictionary *dictionary = result.result;

        // We test for a null object, if it isn't, we can use the response to create a PFUser.
        if ([dictionary isKindOfClass:[NSNull class]] || !dictionary) {
            return [BFTask taskWithError:[PFErrorUtilities errorWithCode:kPFErrorObjectNotFound
                                                                 message:@"Invalid login credentials."]];
        }

        PFUser *user = [PFUser _objectFromDictionary:dictionary
                                    defaultClassName:[PFUser parseClassName]
                                        completeData:YES];

        // Serialize the object to disk so we can later access it via currentUser
        PFCurrentUserController *controller = self.coreDataSource.currentUserController;
        return [[controller saveCurrentObjectAsync:user] continueWithBlock:^id(BFTask *task) {
            return user;
        }];
    }];
}

- (BFTask *)logInCurrentUserAsyncWithAuthType:(NSString *)authType
                                     authData:(NSDictionary *)authData
                             revocableSession:(BOOL)revocableSession {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        NSError *error;
        PFRESTCommand *command = [PFRESTUserCommand serviceLoginUserCommandWithAuthenticationType:authType
                                                                               authenticationData:authData
                                                                                 revocableSession:revocableSession
                                                                                            error:&error];
        PFPreconditionReturnFailedTask(command, error);
        return [self.commonDataSource.commandRunner runCommandAsync:command
                                                        withOptions:PFCommandRunningOptionRetryIfFailed];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        PFCommandResult *result = task.result;
        PFUser *user = [PFUser _objectFromDictionary:result.result
                                    defaultClassName:[PFUser parseClassName]
                                        completeData:YES];
        @synchronized ([user lock]) {
            user.authData[authType] = authData;
            [user.linkedServiceNames addObject:authType];
            [user startSave];
            return [user _handleServiceLoginCommandResult:result];
        }
    }];
}

///--------------------------------------
#pragma mark - Reset Password
///--------------------------------------

- (BFTask *)requestPasswordResetAsyncForEmail:(NSString *)email {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        NSError *error = nil;
        PFRESTCommand *command = [PFRESTUserCommand resetPasswordCommandForUserWithEmail:email error:&error];
        PFPreconditionReturnFailedTask(command, error);
        return [self.commonDataSource.commandRunner runCommandAsync:command
                                                        withOptions:PFCommandRunningOptionRetryIfFailed];
    }] continueWithSuccessResult:nil];
}

///--------------------------------------
#pragma mark - Log Out
///--------------------------------------

- (BFTask *)logOutUserAsyncWithSessionToken:(NSString *)sessionToken {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        NSError *error = nil;
        PFRESTCommand *command = [PFRESTUserCommand logOutUserCommandWithSessionToken:sessionToken error:&error];
        PFPreconditionReturnFailedTask(command, error);
        return [self.commonDataSource.commandRunner runCommandAsync:command
                                                        withOptions:PFCommandRunningOptionRetryIfFailed];
    }] continueWithSuccessResult:nil];
}

@end
