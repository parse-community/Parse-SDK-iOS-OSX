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

@interface DefaultACLControllerTests : PFTestCase

@property (nonatomic, strong, readonly) id<PFCurrentUserControllerProvider> mockedDataSource;

@end

@implementation DefaultACLControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFCurrentUserControllerProvider>)mockedDataSource {
    return PFStrictProtocolMock(@protocol(PFCurrentUserControllerProvider));
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id dataSource = self.mockedDataSource;
    PFDefaultACLController *controller = [PFDefaultACLController controllerWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);
}

- (void)testSetDefaultACL {
    id mockedACL = PFStrictClassMock([PFACL class]);

    OCMExpect([mockedACL createUnsharedCopy]).andReturnWeak(mockedACL);
    OCMExpect([mockedACL setShared:YES]);

    PFDefaultACLController *aclController = [PFDefaultACLController controllerWithDataSource:self.mockedDataSource];

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
    id dataSource = self.mockedDataSource;
    OCMStub([dataSource currentUserController]).andReturn(mockedCurrentUserController);

    OCMExpect([mockedACL createUnsharedCopy]).andReturnWeak(mockedACL);
    OCMExpect([mockedACL setShared:YES]);

    [OCMStub([mockedCurrentUserController getCurrentObjectAsync]) andReturn:[BFTask taskWithResult:nil]];

    PFDefaultACLController *aclController = [PFDefaultACLController controllerWithDataSource:dataSource];

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
    id dataSource = self.mockedDataSource;
    OCMStub([dataSource currentUserController]).andReturn(mockedCurrentUserController);

    OCMExpect([mockedACL createUnsharedCopy]).andReturnWeak(mockedACL);
    OCMExpect([mockedACL setShared:YES]);

    PFUser *user = PFStrictClassMock([PFUser class]);
    [OCMStub(user.objectId) andReturn:[NSUUID UUID].UUIDString];
    [OCMStub([mockedCurrentUserController getCurrentObjectAsync]) andReturn:[BFTask taskWithResult:user]];

    PFDefaultACLController *aclController = [PFDefaultACLController controllerWithDataSource:dataSource];

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
