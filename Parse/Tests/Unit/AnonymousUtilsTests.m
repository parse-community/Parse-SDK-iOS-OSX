/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "BFTask+Private.h"
#import "PFAnonymousUtils_Private.h"
#import "PFCoreManager.h"
#import "PFUnitTestCase.h"
#import "PFUserAuthenticationController.h"
#import "Parse_Private.h"
#import "PFAnonymousAuthenticationProvider.h"

@protocol AnonymousUtilsObserver <NSObject>

- (void)callbackWithUser:(PFUser *)user error:(NSError *)error;

@end

@interface AnonymousUtilsTests : PFUnitTestCase

@end

@implementation AnonymousUtilsTests

- (void)setUp {
    [super setUp];

    // Put this into setUp to make sure our state is fully clean.
    [PFAnonymousUtils _clearAuthenticationProvider];
}

- (void)tearDown {
    // Clear the manager first - to make sure we don't have any mocks set.
    [Parse _clearCurrentManager];
    [PFAnonymousUtils _clearAuthenticationProvider];

    [super tearDown];
}

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFUserAuthenticationController *)mockedUserAuthenticationController {
    id controller = PFStrictClassMock([PFUserAuthenticationController class]);
    [Parse _currentManager].coreManager.userAuthenticationController = controller;
    return controller;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testInitialize {
    id authController = [self mockedUserAuthenticationController];
    OCMExpect([authController registerAuthenticationDelegate:[OCMArg isNotNil] forAuthType:@"anonymous"]);

    PFAnonymousAuthenticationProvider *provider = [PFAnonymousUtils _authenticationProvider];
    XCTAssertNotNil(provider);
    XCTAssertEqual(provider, [PFAnonymousUtils _authenticationProvider]);

    provider = [PFAnonymousUtils _authenticationProvider];
    XCTAssertNotNil(provider);
    XCTAssertEqual(provider, [PFAnonymousUtils _authenticationProvider]);

    OCMVerifyAll(authController);
}

- (void)testLogInViaTask {
    id authController = [self mockedUserAuthenticationController];
    OCMStub([authController authenticationDelegateForAuthType:@"anonymous"]).andReturn([[PFAnonymousAuthenticationProvider alloc] init]);
    OCMExpect([authController registerAuthenticationDelegate:[OCMArg isNotNil] forAuthType:@"anonymous"]);

    PFUser *user = [PFUser user];
    OCMExpect([authController logInUserAsyncWithAuthType:@"anonymous" authData:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:user]);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFAnonymousUtils logInInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, user);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(authController);
}

- (void)testLogInViaBlock {
    id authController = [self mockedUserAuthenticationController];
    OCMStub([authController authenticationDelegateForAuthType:@"anonymous"]).andReturn([[PFAnonymousAuthenticationProvider alloc] init]);
    OCMExpect([authController registerAuthenticationDelegate:[OCMArg isNotNil] forAuthType:@"anonymous"]);

    PFUser *user = [PFUser user];
    OCMExpect([authController logInUserAsyncWithAuthType:@"anonymous" authData:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:user]);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFAnonymousUtils logInWithBlock:^(PFUser *resultUser, NSError *error) {
        XCTAssertEqual(resultUser, user);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(authController);
}

- (void)testLogInViaTargetSelector {
    id authController = [self mockedUserAuthenticationController];
    OCMStub([authController authenticationDelegateForAuthType:@"anonymous"]).andReturn([[PFAnonymousAuthenticationProvider alloc] init]);
    OCMExpect([authController registerAuthenticationDelegate:[OCMArg isNotNil] forAuthType:@"anonymous"]);

    PFUser *user = [PFUser user];
    OCMExpect([authController logInUserAsyncWithAuthType:@"anonymous" authData:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:user]);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    id observer = PFStrictProtocolMock(@protocol(AnonymousUtilsObserver));
    OCMExpect([observer callbackWithUser:user error:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFAnonymousUtils logInWithTarget:observer selector:@selector(callbackWithUser:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
    OCMVerifyAll(authController);
}

@end
