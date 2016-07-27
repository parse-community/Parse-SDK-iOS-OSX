/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFCoreManager.h"
#import "PFObjectPrivate.h"
#import "PFSessionController.h"
#import "PFSession_Private.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"
#import "PFObjectSubclassingController.h"

@interface SessionUnitTests : PFUnitTestCase

@end

@implementation SessionUnitTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFSessionController *)sessionControllerMockWithSessionResult:(PFSession *)session error:(NSError *)error {
    BFTask *task = nil;
    if (error) {
        task = [BFTask taskWithError:error];
    } else {
        task = [BFTask taskWithResult:session];
    }

    id controllerMock = PFClassMock([PFSessionController class]);
    OCMStub([controllerMock getCurrentSessionAsyncWithSessionToken:OCMOCK_ANY]).andReturn(task);
    return controllerMock;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructorsClassNameValidation {
    PFAssertThrowsInvalidArgumentException([[PFSession alloc] initWithClassName:@"yarrclass"],
                                           @"Should throw an exception for invalid classname");
}

- (void)testSessionImmutableFieldsCannotBeChanged {
    PFSession *session = [PFSession object];
    session[@"yolo"] = @"El Capitan!"; // Test for regular mutability
    PFAssertThrowsInvalidArgumentException(session[@"sessionToken"] = @"a");
    PFAssertThrowsInvalidArgumentException(session[@"restricted"] = @"a");
    PFAssertThrowsInvalidArgumentException(session[@"createdWith"] = @"a");
    PFAssertThrowsInvalidArgumentException(session[@"installationId"] = @"a");
    PFAssertThrowsInvalidArgumentException(session[@"user"] = @"a");
    PFAssertThrowsInvalidArgumentException(session[@"expiresAt"] = @"a");
}

- (void)testSessionImmutableFieldsCannotBeDeleted {
    PFSession *session = [PFSession object];

    [session removeObjectForKey:@"yolo"];// Test for regular mutability

    PFAssertThrowsInvalidArgumentException([session removeObjectForKey:@"sessionToken"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectForKey:@"restricted"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectForKey:@"createdWith"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectForKey:@"installationId"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectForKey:@"user"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectForKey:@"expiresAt"]);

    [session removeObjectsInArray:@[ @"El Capitan" ] forKey:@"yolo"]; // Test for regular mutability

    PFAssertThrowsInvalidArgumentException([session removeObjectsInArray:@[@"1"] forKey:@"sessionToken"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectsInArray:@[@"1"] forKey:@"restricted"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectsInArray:@[@"1"] forKey:@"createdWith"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectsInArray:@[@"1"] forKey:@"installationId"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectsInArray:@[@"1"] forKey:@"user"]);
    PFAssertThrowsInvalidArgumentException([session removeObjectsInArray:@[@"1"] forKey:@"expiresAt"]);
}

- (void)testDefaultACLNotSetOnSession {
    [PFACL setDefaultACL:[PFACL ACL] withAccessForCurrentUser:NO];
    XCTAssertNil([PFSession object].ACL);
}

- (void)testSessionControllerFromSession {
    [Parse _currentManager].coreManager.sessionController = [self sessionControllerMockWithSessionResult:nil error:nil];
    XCTAssertEqual([Parse _currentManager].coreManager.sessionController, [PFSession sessionController]);
}

- (void)testGetCurrentSessionViaTask {
    PFSession *session = [PFSession object];
    [Parse _currentManager].coreManager.sessionController = [self sessionControllerMockWithSessionResult:session
                                                                                                   error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFSession getCurrentSessionInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, session);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testGetCurrentSessionViaBlock {
    PFSession *session = [PFSession object];
    [Parse _currentManager].coreManager.sessionController = [self sessionControllerMockWithSessionResult:session
                                                                                                   error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFSession getCurrentSessionInBackgroundWithBlock:^(PFSession *object, NSError *error) {
        XCTAssertEqual(object, session);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testGetCurrentSessionErrorViaTask {
    NSError *error = [NSError errorWithDomain:@"Test" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.sessionController = [self sessionControllerMockWithSessionResult:nil
                                                                                                   error:error];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFSession getCurrentSessionInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.error, error);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testGetCurrentSessionErrorViaBlock {
    NSError *error = [NSError errorWithDomain:@"Test" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.sessionController = [self sessionControllerMockWithSessionResult:nil
                                                                                                   error:error];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFSession getCurrentSessionInBackgroundWithBlock:^(PFSession *session, NSError *blockError) {
        XCTAssertNil(session);
        XCTAssertEqual(error, blockError);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

@end
