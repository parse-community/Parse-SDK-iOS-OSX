/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
#import <OCMock/OCMock.h>

#import "PFInstallation.h"
#import "PFApplication.h"
#import "PFUnitTestCase.h"
#import "Parse.h"
#import "Parse_Private.h"
#import "PFCommandRunning.h"
#import "ParseManagerPrivate.h"
#import "PFObjectState.h"
#import "PFObjectPrivate.h"

@interface InstallationUnitTests : PFUnitTestCase

@end

@implementation InstallationUnitTests

- (void)testInstallationObjectIdCannotBeChanged {
    PFInstallation *installation = [PFInstallation currentInstallation];
    PFAssertThrowsInvalidArgumentException(installation.objectId = nil);
    PFAssertThrowsInvalidArgumentException(installation[@"objectId"] = @"abc");
}

- (void)testObjectNotFoundWhenSave {
#if TARGET_OS_IOS
    // enable LDS
    [[Parse _currentManager]loadOfflineStoreWithOptions:0];
    PFOfflineStore *offlineStoreSpy = PFPartialMock([Parse _currentManager].offlineStore);
    [Parse _currentManager].offlineStore = offlineStoreSpy;
    
    // create and save installation
    PFInstallation *installation = [PFInstallation currentInstallation];
    PFObjectState *state = [PFObjectState stateWithParseClassName:[PFInstallation parseClassName] objectId:@"abc" isComplete:YES];
    installation._state = state;
    [installation save];
    
    // mocking installation was deleted on the server
    id commandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    [Parse _currentManager].commandRunner = commandRunner;
    
    BFTask *mockedTask = [BFTask taskWithError:[NSError errorWithDomain:@"Object Not Found" code:kPFErrorObjectNotFound userInfo:nil]];
    
    __block int callCount = 0;
    OCMStub([commandRunner runCommandAsync:[OCMArg any] withOptions:PFCommandRunningOptionRetryIfFailed])
    .andReturn(mockedTask)
    .andDo(^(NSInvocation *invocation) {
        callCount++;
    });
    
    installation.deviceToken = @"11433856eed2f1285fb3aa11136718c1198ed5647875096952c66bf8cb976306";
    [installation save];
    OCMVerifyAll(commandRunner);
    XCTAssertEqual(2, callCount);
    OCMVerify([offlineStoreSpy updateObjectIdForObject:installation oldObjectId:nil newObjectId:@"abc"]);
    OCMVerify([offlineStoreSpy updateObjectIdForObject:installation oldObjectId:@"abc" newObjectId:nil]);
#endif
}

- (void)testInstallationImmutableFieldsCannotBeChanged {
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation.deviceToken = @"11433856eed2f1285fb3aa11136718c1198ed5647875096952c66bf8cb976306";

    PFAssertThrowsInvalidArgumentException(installation[@"deviceType"] = @"android");
    PFAssertThrowsInvalidArgumentException(installation[@"installationId"] = @"a");
    PFAssertThrowsInvalidArgumentException(installation[@"localeIdentifier"] = @"a");
}

- (void)testInstallationImmutableFieldsCannotBeDeleted {
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation.deviceToken = @"11433856eed2f1285fb3aa11136718c1198ed5647875096952c66bf8cb976306";

    PFAssertThrowsInvalidArgumentException([installation removeObjectForKey:@"deviceType"]);
    PFAssertThrowsInvalidArgumentException([installation removeObjectForKey:@"installationId"]);
    PFAssertThrowsInvalidArgumentException([installation removeObjectForKey:@"localeIdentifier"]);
}

- (void)testInstallationHasApplicationBadge {
#if TARGET_OS_IOS
    [PFApplication currentApplication].systemApplication.applicationIconBadgeNumber = 10;
#elif PF_TARGET_OS_OSX
    [[NSApplication sharedApplication] dockTile].badgeLabel = @"10";
#endif
    PFInstallation *installation = [PFInstallation currentInstallation];
    PFAssertEqualInts(installation.badge, 10, @"Installation should have the same badge as application");
}

- (void)testInstallationSetsApplicationBadge {
#if TARGET_OS_IOS
    [PFApplication currentApplication].systemApplication.applicationIconBadgeNumber = 20;
#elif PF_TARGET_OS_OSX
    [[NSApplication sharedApplication] dockTile].badgeLabel = @"20";
#endif
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation.badge = 5;
    PFAssertEqualInts(installation.badge, 5, @"Installation should have the same badge as application");
    PFAssertEqualInts([PFApplication currentApplication].iconBadgeNumber, 5, @"Installation should have the same badge as application");
#if TARGET_OS_IOS
    PFAssertEqualInts([PFApplication currentApplication].systemApplication.applicationIconBadgeNumber, 5, @"Installation should have the same badge as application");
#elif PF_TARGET_OS_OSX
    PFAssertStringContains([[NSApplication sharedApplication] dockTile].badgeLabel, @"5");
#endif
}

@end
