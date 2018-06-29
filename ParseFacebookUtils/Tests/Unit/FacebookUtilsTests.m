/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Parse;

#import <OCMock/OCMock.h>

#import "PFFacebookTestCase.h"
#import "PFFacebookUtils_Private.h"
#import "PFFacebookPrivateUtilities.h"

///--------------------------------------
#pragma mark - FacebookUtilsTests
///--------------------------------------

@interface FacebookUtilsTests : PFFacebookTestCase

@end

@implementation FacebookUtilsTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)tearDown {
    [PFFacebookUtils _setAuthenticationProvider:nil];

    [super tearDown];
}

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (NSDictionary *)sampleAuthData {
    return @{ @"id" : @"fbId",
              @"auth_token" : @"token",
              @"expiration_date" : @"1970-01-01T00:22:17.000Z" };
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testInitialize {
    id userMock = PFStrictClassMock([PFUser class]);
    OCMExpect(ClassMethod([userMock registerAuthenticationDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
        return (obj != nil);
    }] forAuthType:@"facebook"]));

    XCTAssertThrows([PFFacebookUtils unlinkUserInBackground:userMock]);

    XCTAssertThrows([PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:nil]);

    id parseMock = PFStrictClassMock([Parse class]);
    id configurationMock = PFStrictClassMock([ParseClientConfiguration class]);
    OCMStub(ClassMethod([parseMock currentConfiguration])).andReturn(configurationMock);

    XCTAssertNoThrow([PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:nil]);
    XCTAssertNotNil([PFFacebookUtils _authenticationProvider]);
    XCTAssertNoThrow([PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:nil]);

    OCMVerifyAll(userMock);
}

- (void)testLoginManager {
    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);

    OCMStub([mockedAuthProvider loginManager]).andReturn(mockedLoginManager);

    [PFFacebookUtils _setAuthenticationProvider:mockedAuthProvider];
    XCTAssertEqualObjects(mockedLoginManager, [PFFacebookUtils facebookLoginManager]);
}

- (void)testLoginReadPermissions {
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);
    OCMStub([mockedAuthProvider authenticateAsyncWithReadPermissions:@[ @"read" ] publishPermissions:nil]).andReturn([BFTask taskWithResult:@{}]);
    [PFFacebookUtils _setAuthenticationProvider:mockedAuthProvider];

    id userMock = PFStrictClassMock([PFUser class]);
    OCMStub(ClassMethod([userMock logInWithAuthTypeInBackground:@"facebook" authData:[OCMArg isNotNil]])).andReturn([BFTask taskWithResult:userMock]);

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtils logInInBackgroundWithReadPermissions:@[ @"read" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, userMock);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpecatation = [self expectationWithDescription:@"block"];
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[ @"read" ] block:^(PFUser *resultUser, NSError *error) {
        XCTAssertEqual(resultUser, userMock);
        XCTAssertNil(error);
        [blockExpecatation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testLoginWritePermissions {
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);
    OCMStub([mockedAuthProvider authenticateAsyncWithReadPermissions:nil publishPermissions:@[ @"publish" ]]).andReturn([BFTask taskWithResult:@{}]);
    [PFFacebookUtils _setAuthenticationProvider:mockedAuthProvider];

    id userMock = PFStrictClassMock([PFUser class]);
    OCMStub(ClassMethod([userMock logInWithAuthTypeInBackground:@"facebook" authData:[OCMArg isNotNil]])).andReturn([BFTask taskWithResult:userMock]);

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtils logInInBackgroundWithPublishPermissions:@[ @"publish" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, userMock);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpecatation = [self expectationWithDescription:@"block"];
    [PFFacebookUtils logInInBackgroundWithPublishPermissions:@[ @"publish" ] block:^(PFUser *resultUser, NSError *error) {
        XCTAssertEqual(resultUser, userMock);
        XCTAssertNil(error);
        [blockExpecatation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testLoginWithAccessToken {
    id mockedPrivateUtilities = PFStrictClassMock([PFFacebookPrivateUtilities class]);
    id mockedAccessToken = PFStrictClassMock([FBSDKAccessToken class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);
    [PFFacebookUtils _setAuthenticationProvider:mockedAuthProvider];

    // NOTE: (richardross) Until we decouple user login with auth data, we can only mock error cases here.
    OCMStub(ClassMethod([mockedPrivateUtilities userAuthenticationDataFromAccessToken:mockedAccessToken])).andReturn(nil);

    XCTestExpectation *taskExpectation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtils logInInBackgroundWithAccessToken:mockedAccessToken] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error.domain, PFParseErrorDomain);
        XCTAssertEqual(task.error.code, kPFErrorFacebookInvalidSession);
        [taskExpectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtils logInInBackgroundWithAccessToken:mockedAccessToken block:^(PFUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
        XCTAssertEqual(error.code, kPFErrorFacebookInvalidSession);
        [blockExpectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testLinkWithReadPermissions {
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);

    OCMStub([mockedAuthProvider authenticateAsyncWithReadPermissions:@[ @"read" ] publishPermissions:nil]).andReturn([BFTask taskWithResult:@{}]);
    [PFFacebookUtils _setAuthenticationProvider:mockedAuthProvider];

    OCMStub([mockedUser linkWithAuthTypeInBackground:@"facebook" authData:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:@YES]);

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtils linkUserInBackground:mockedUser withReadPermissions:@[ @"read" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtils linkUserInBackground:mockedUser withReadPermissions:@[ @"read" ] block:^(BOOL result, NSError *error) {
        XCTAssertTrue(result);
        [blockExpectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testLinkWithWritePermissions {
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);

    OCMStub([mockedAuthProvider authenticateAsyncWithReadPermissions:nil publishPermissions:@[ @"publish" ]]).andReturn([BFTask taskWithResult:@{}]);
    [PFFacebookUtils _setAuthenticationProvider:mockedAuthProvider];
    OCMStub([mockedUser linkWithAuthTypeInBackground:@"facebook" authData:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:@YES]);

    XCTestExpectation *taskExpecation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtils linkUserInBackground:mockedUser withPublishPermissions:@[ @"publish" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [taskExpecation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtils linkUserInBackground:mockedUser withPublishPermissions:@[ @"publish" ] block:^(BOOL result, NSError *error) {
        XCTAssertTrue(result);
        [blockExpectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testLinkWithAccessToken {
    id mockedPrivateUtilities = PFStrictClassMock([PFFacebookPrivateUtilities class]);
    id mockedAccessToken = PFStrictClassMock([FBSDKAccessToken class]);
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);

    NSDictionary *sampleAuthData = [self sampleAuthData];
    OCMStub(ClassMethod([mockedPrivateUtilities userAuthenticationDataFromAccessToken:mockedAccessToken])).andReturn(sampleAuthData);

    [PFFacebookUtils _setAuthenticationProvider:mockedAuthProvider];
    [OCMStub([mockedUser linkWithAuthTypeInBackground:@"facebook" authData:sampleAuthData]) andReturn:[BFTask taskWithResult:@YES]];

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"block"];
    [[PFFacebookUtils linkUserInBackground:mockedUser withAccessToken:mockedAccessToken] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtils linkUserInBackground:mockedUser withAccessToken:mockedAccessToken block:^(BOOL result, NSError *error) {
        XCTAssertTrue(result);
        [blockExpectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testUnlink {
    id mockedLinkedUser = PFStrictClassMock([PFUser class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);

    [PFFacebookUtils _setAuthenticationProvider:mockedAuthProvider];
    [OCMStub([mockedLinkedUser unlinkWithAuthTypeInBackground:@"facebook"]) andReturn:[BFTask taskWithResult:@YES]];

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"block"];
    [[PFFacebookUtils unlinkUserInBackground:mockedLinkedUser] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtils unlinkUserInBackground:mockedLinkedUser block:^(BOOL result, NSError *error) {
        XCTAssertTrue(result);
        [blockExpectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testIsLinked {
    id mockedLinkedUser = PFStrictClassMock([PFUser class]);
    id mockedUnlinkedUser = PFStrictClassMock([PFUser class]);

    OCMStub([mockedLinkedUser isLinkedWithAuthType:@"facebook"]).andReturn(YES);
    OCMStub([mockedUnlinkedUser isLinkedWithAuthType:@"facebook"]).andReturn(NO);

    XCTAssertTrue([PFFacebookUtils isLinkedWithUser:mockedLinkedUser]);
    XCTAssertFalse([PFFacebookUtils isLinkedWithUser:mockedUnlinkedUser]);
}

@end
