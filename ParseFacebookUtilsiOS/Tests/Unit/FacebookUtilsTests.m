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

#if __has_include(<ParseFacebookUtilsV4/PFFacebookUtils.h>)
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#else
#import "PFFacebookUtils.h"
#endif

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
    [PFFacebookUtilsDevice _setAuthenticationProvider:nil];

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

    XCTAssertThrows([PFFacebookUtilsDevice unlinkUserInBackground:userMock]);

    XCTAssertThrows([PFFacebookUtilsDevice initializeFacebookWithApplicationLaunchOptions:nil]);

    id parseMock = PFStrictClassMock([Parse class]);
    id configurationMock = PFStrictClassMock([ParseClientConfiguration class]);
    OCMStub(ClassMethod([parseMock currentConfiguration])).andReturn(configurationMock);

    XCTAssertNoThrow([PFFacebookUtilsDevice initializeFacebookWithApplicationLaunchOptions:nil]);
    XCTAssertNotNil([PFFacebookUtilsDevice _authenticationProvider]);
    XCTAssertNoThrow([PFFacebookUtilsDevice initializeFacebookWithApplicationLaunchOptions:nil]);

    OCMVerifyAll(userMock);
}

- (void)testLoginManager {
    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);

    OCMStub([mockedAuthProvider loginManager]).andReturn(mockedLoginManager);

    [PFFacebookUtilsDevice _setAuthenticationProvider:mockedAuthProvider];
    XCTAssertEqualObjects(mockedLoginManager, [PFFacebookUtilsDevice facebookLoginManager]);
}

- (void)testLoginReadPermissions {
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);
    OCMStub([mockedAuthProvider authenticateAsyncWithReadPermissions:@[ @"read" ] publishPermissions:nil]).andReturn([BFTask taskWithResult:@{}]);
    [PFFacebookUtilsDevice _setAuthenticationProvider:mockedAuthProvider];

    id userMock = PFStrictClassMock([PFUser class]);
    OCMStub(ClassMethod([userMock logInWithAuthTypeInBackground:@"facebook" authData:[OCMArg isNotNil]])).andReturn([BFTask taskWithResult:userMock]);

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtilsDevice logInInBackgroundWithReadPermissions:@[ @"read" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, userMock);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpecatation = [self expectationWithDescription:@"block"];
    [PFFacebookUtilsDevice logInInBackgroundWithReadPermissions:@[ @"read" ] block:^(PFUser *resultUser, NSError *error) {
        XCTAssertEqual(resultUser, userMock);
        XCTAssertNil(error);
        [blockExpecatation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testLoginWritePermissions {
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);
    OCMStub([mockedAuthProvider authenticateAsyncWithReadPermissions:nil publishPermissions:@[ @"publish" ]]).andReturn([BFTask taskWithResult:@{}]);
    [PFFacebookUtilsDevice _setAuthenticationProvider:mockedAuthProvider];

    id userMock = PFStrictClassMock([PFUser class]);
    OCMStub(ClassMethod([userMock logInWithAuthTypeInBackground:@"facebook" authData:[OCMArg isNotNil]])).andReturn([BFTask taskWithResult:userMock]);

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtilsDevice logInInBackgroundWithPublishPermissions:@[ @"publish" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, userMock);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpecatation = [self expectationWithDescription:@"block"];
    [PFFacebookUtilsDevice logInInBackgroundWithPublishPermissions:@[ @"publish" ] block:^(PFUser *resultUser, NSError *error) {
        XCTAssertEqual(resultUser, userMock);
        XCTAssertNil(error);
        [blockExpecatation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testLoginWithAccessToken {
    id mockedPrivateUtilities = PFStrictClassMock([PFFacebookUtils class]);
    id mockedAccessToken = PFStrictClassMock([FBSDKAccessToken class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);
    [PFFacebookUtilsDevice _setAuthenticationProvider:mockedAuthProvider];

    // NOTE: (richardross) Until we decouple user login with auth data, we can only mock error cases here.
    OCMStub(ClassMethod([mockedPrivateUtilities userAuthenticationDataFromAccessToken:mockedAccessToken])).andReturn(nil);

    XCTestExpectation *taskExpectation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtilsDevice logInInBackgroundWithAccessToken:mockedAccessToken] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error.domain, PFParseErrorDomain);
        XCTAssertEqual(task.error.code, kPFErrorFacebookInvalidSession);
        [taskExpectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtilsDevice logInInBackgroundWithAccessToken:mockedAccessToken block:^(PFUser *user, NSError *error) {
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
    [PFFacebookUtilsDevice _setAuthenticationProvider:mockedAuthProvider];

    OCMStub([mockedUser linkWithAuthTypeInBackground:@"facebook" authData:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:@YES]);

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtilsDevice linkUserInBackground:mockedUser withReadPermissions:@[ @"read" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtilsDevice linkUserInBackground:mockedUser withReadPermissions:@[ @"read" ] block:^(BOOL result, NSError *error) {
        XCTAssertTrue(result);
        [blockExpectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testLinkWithWritePermissions {
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);

    OCMStub([mockedAuthProvider authenticateAsyncWithReadPermissions:nil publishPermissions:@[ @"publish" ]]).andReturn([BFTask taskWithResult:@{}]);
    [PFFacebookUtilsDevice _setAuthenticationProvider:mockedAuthProvider];
    OCMStub([mockedUser linkWithAuthTypeInBackground:@"facebook" authData:[OCMArg isNotNil]]).andReturn([BFTask taskWithResult:@YES]);

    XCTestExpectation *taskExpecation = [self expectationWithDescription:@"task"];
    [[PFFacebookUtilsDevice linkUserInBackground:mockedUser withPublishPermissions:@[ @"publish" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [taskExpecation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtilsDevice linkUserInBackground:mockedUser withPublishPermissions:@[ @"publish" ] block:^(BOOL result, NSError *error) {
        XCTAssertTrue(result);
        [blockExpectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testLinkWithAccessToken {
    id mockedPrivateUtilities = PFStrictClassMock([PFFacebookUtils class]);
    id mockedAccessToken = PFStrictClassMock([FBSDKAccessToken class]);
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);

    NSDictionary *sampleAuthData = [self sampleAuthData];
    OCMStub(ClassMethod([mockedPrivateUtilities userAuthenticationDataFromAccessToken:mockedAccessToken])).andReturn(sampleAuthData);

    [PFFacebookUtilsDevice _setAuthenticationProvider:mockedAuthProvider];
    [OCMStub([mockedUser linkWithAuthTypeInBackground:@"facebook" authData:sampleAuthData]) andReturn:[BFTask taskWithResult:@YES]];

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"block"];
    [[PFFacebookUtilsDevice linkUserInBackground:mockedUser withAccessToken:mockedAccessToken] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtilsDevice linkUserInBackground:mockedUser withAccessToken:mockedAccessToken block:^(BOOL result, NSError *error) {
        XCTAssertTrue(result);
        [blockExpectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testUnlink {
    id mockedLinkedUser = PFStrictClassMock([PFUser class]);
    id mockedAuthProvider = PFStrictClassMock([PFFacebookMobileAuthenticationProvider class]);

    [PFFacebookUtilsDevice _setAuthenticationProvider:mockedAuthProvider];
    [OCMStub([mockedLinkedUser unlinkWithAuthTypeInBackground:@"facebook"]) andReturn:[BFTask taskWithResult:@YES]];

    XCTestExpectation *taskExpecatation = [self expectationWithDescription:@"block"];
    [[PFFacebookUtilsDevice unlinkUserInBackground:mockedLinkedUser] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [taskExpecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *blockExpectation = [self expectationWithDescription:@"block"];
    [PFFacebookUtilsDevice unlinkUserInBackground:mockedLinkedUser block:^(BOOL result, NSError *error) {
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

    XCTAssertTrue([PFFacebookUtilsDevice isLinkedWithUser:mockedLinkedUser]);
    XCTAssertFalse([PFFacebookUtilsDevice isLinkedWithUser:mockedUnlinkedUser]);
}

@end
