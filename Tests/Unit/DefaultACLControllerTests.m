/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

@import Bolts.BFTask;

#import "PFACLPrivate.h"
#import "PFCoreManager.h"
#import "PFCurrentUserController.h"
#import "PFDefaultACLController.h"
#import "PFMacros.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface DefaultACLControllerTests : PFUnitTestCase

@end

@implementation DefaultACLControllerTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)tearDown {
    [PFDefaultACLController clearDefaultController];

    [super tearDown];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    XCTAssertNotNil([[PFDefaultACLController alloc] init]);
}

- (void)testSingleton {
    PFDefaultACLController *oldController = [PFDefaultACLController defaultController];
    XCTAssertNotNil(oldController);

    [PFDefaultACLController clearDefaultController];
    PFDefaultACLController *newController = [PFDefaultACLController defaultController];
    XCTAssertNotNil(newController);

    XCTAssertNotEqual(oldController, newController);
}

- (void)testSetDefaultACL {
    id mockedACL = PFStrictClassMock([PFACL class]);

    OCMExpect([mockedACL createUnsharedCopy]).andReturnWeak(mockedACL);
    OCMExpect([mockedACL setShared:YES]);

    PFDefaultACLController *aclController = [[PFDefaultACLController alloc] init];

    XCTestExpectation *expecatation = [self currentSelectorTestExpectation];
    [[aclController setDefaultACLAsync:mockedACL withCurrentUserAccess:NO] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, mockedACL);

        return [[aclController getDefaultACLAsync] continueWithBlock:^id(BFTask *task) {
            XCTAssertEqual(task.result, mockedACL);
            [expecatation fulfill];
            return nil;
        }];
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedACL);
}

- (void)testSetDefaultACLWithUserAccessWithoutCurrentUser {
    id mockedACL = PFStrictClassMock([PFACL class]);
    id mockedCurrentUserController = PFStrictClassMock([PFCurrentUserController class]);

    [Parse _currentManager].coreManager.currentUserController = mockedCurrentUserController;

    OCMExpect([mockedACL createUnsharedCopy]).andReturnWeak(mockedACL);
    OCMExpect([mockedACL setShared:YES]);

    [OCMStub([mockedCurrentUserController getCurrentObjectAsync]) andReturn:[BFTask taskWithResult:nil]];

    PFDefaultACLController *aclController = [[PFDefaultACLController alloc] init];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[[aclController setDefaultACLAsync:mockedACL withCurrentUserAccess:YES] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, mockedACL);

        // Test case of nil current user, no modifications to the ACL should be made.
        return [aclController getDefaultACLAsync];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, mockedACL);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedACL);
}

- (void)testSetDefaultACLWithUserAccessWithCurrentUser {
    id mockedACL = PFStrictClassMock([PFACL class]);
    id mockedCurrentUserController = PFStrictClassMock([PFCurrentUserController class]);

    [Parse _currentManager].coreManager.currentUserController = mockedCurrentUserController;

    OCMExpect([mockedACL createUnsharedCopy]).andReturnWeak(mockedACL);
    OCMExpect([mockedACL setShared:YES]);

    PFUser *user = [PFUser user];
    [OCMStub([mockedCurrentUserController getCurrentObjectAsync]) andReturn:[BFTask taskWithResult:user]];

    PFDefaultACLController *aclController = [[PFDefaultACLController alloc] init];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[[[aclController setDefaultACLAsync:mockedACL withCurrentUserAccess:YES] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, mockedACL);

        OCMExpect([mockedACL createUnsharedCopy]).andReturnWeak(mockedACL);
        OCMExpect([mockedACL setShared:YES]);
        OCMExpect([mockedACL setReadAccess:YES forUser:user]);
        OCMExpect([mockedACL setWriteAccess:YES forUser:user]);

        return [aclController getDefaultACLAsync];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, mockedACL);

        // Ensure that the ACL wasn't changed between fetches.
        return [aclController getDefaultACLAsync];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, mockedACL);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedACL);
}

@end
