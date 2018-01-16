/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Bolts.BFTask;

@import FBSDKCoreKit.FBSDKAccessToken;
@import FBSDKLoginKit.FBSDKLoginManagerLoginResult;

#import "PFFacebookMobileAuthenticationProvider_Private.h"
#import "PFFacebookTestCase.h"

@interface FacebookAuthenticationProviderTests : PFFacebookTestCase

@end

@implementation FacebookAuthenticationProviderTests

- (void)testAuthType {
    XCTAssertEqualObjects(PFFacebookUserAuthenticationType, @"facebook");
}

- (void)testAuthenticateRead {
    NSDictionary *expectedAuthData = @{ @"id" : @"fbId",
                                        @"access_token" : @"token",
                                        @"expiration_date" : @"1970-01-01T00:22:17.000Z" };

    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);

    OCMStub([mockedLoginManager logInWithReadPermissions:@[ @"read" ]
                                      fromViewController:OCMOCK_ANY
                                                 handler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained FBSDKLoginManagerRequestTokenHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        FBSDKAccessToken *token = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[ @"read" ]
                                                            declinedPermissions:nil
                                                                          appID:@"appId"
                                                                         userID:@"fbId"
                                                                 expirationDate:[NSDate dateWithTimeIntervalSince1970:1337]
                                                                    refreshDate:[NSDate dateWithTimeIntervalSince1970:1337]];
        FBSDKLoginManagerLoginResult *result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:token
                                                                                       isCancelled:NO
                                                                                grantedPermissions:[NSSet setWithObject:@"read"]
                                                                               declinedPermissions:nil];

        handler(result, nil);
    });

    PFFacebookMobileAuthenticationProvider *provider = [[PFFacebookMobileAuthenticationProvider alloc] initWithApplication:[UIApplication sharedApplication] launchOptions:nil];
    provider.loginManager = mockedLoginManager;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[provider authenticateAsyncWithReadPermissions:@[ @"read" ]
                                 publishPermissions:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, expectedAuthData);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testAuthenticatePublish {
    NSDictionary *expectedAuthData = @{ @"id" : @"fbId",
                                        @"access_token" : @"token",
                                        @"expiration_date" : @"1970-01-01T00:22:17.000Z" };

    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);

    OCMStub([mockedLoginManager logInWithPublishPermissions:@[ @"publish" ]
                                         fromViewController:OCMOCK_ANY
                                                    handler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained FBSDKLoginManagerRequestTokenHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        FBSDKAccessToken *token = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[ @"publish" ]
                                                            declinedPermissions:nil
                                                                          appID:@"appId"
                                                                         userID:@"fbId"
                                                                 expirationDate:[NSDate dateWithTimeIntervalSince1970:1337]
                                                                    refreshDate:[NSDate dateWithTimeIntervalSince1970:1337]];
        FBSDKLoginManagerLoginResult *result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:token
                                                                                       isCancelled:NO
                                                                                grantedPermissions:[NSSet setWithObject:@"publish"]
                                                                               declinedPermissions:nil];

        handler(result, nil);
    });

    PFFacebookMobileAuthenticationProvider *provider = [[PFFacebookMobileAuthenticationProvider alloc] initWithApplication:[UIApplication sharedApplication] launchOptions:nil];
    provider.loginManager = mockedLoginManager;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[provider authenticateAsyncWithReadPermissions:nil
                                 publishPermissions:@[ @"publish" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, expectedAuthData);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testAuthenticateBoth {
    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);

    PFFacebookMobileAuthenticationProvider *provider = [[PFFacebookMobileAuthenticationProvider alloc] initWithApplication:[UIApplication sharedApplication] launchOptions:nil];
    provider.loginManager = mockedLoginManager;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[provider authenticateAsyncWithReadPermissions:@[ @"read" ] publishPermissions:@[ @"publish" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testAuthenticateCancel {
    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);

    OCMStub([mockedLoginManager logInWithPublishPermissions:@[ @"publish" ]
                                         fromViewController:OCMOCK_ANY
                                                    handler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained FBSDKLoginManagerRequestTokenHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        FBSDKLoginManagerLoginResult *result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:nil
                                                                                       isCancelled:YES
                                                                                grantedPermissions:nil
                                                                               declinedPermissions:[NSSet setWithObject:@"publish"]];

        handler(result, nil);
    });

    PFFacebookMobileAuthenticationProvider *provider = [[PFFacebookMobileAuthenticationProvider alloc] initWithApplication:[UIApplication sharedApplication] launchOptions:nil];
    provider.loginManager = mockedLoginManager;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[provider authenticateAsyncWithReadPermissions:nil publishPermissions:@[ @"publish" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testAuthenticateError {
    NSError *expectedError = [NSError errorWithDomain:@"FBSDK" code:1337 userInfo:nil];
    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);

    OCMStub([mockedLoginManager logInWithPublishPermissions:@[ @"publish" ]
                                         fromViewController:OCMOCK_ANY
                                                    handler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained FBSDKLoginManagerRequestTokenHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        handler(nil, expectedError);
    });

    PFFacebookMobileAuthenticationProvider *provider = [[PFFacebookMobileAuthenticationProvider alloc] initWithApplication:[UIApplication sharedApplication] launchOptions:nil];
    provider.loginManager = mockedLoginManager;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[provider authenticateAsyncWithReadPermissions:nil publishPermissions:@[ @"publish" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, expectedError);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testAuthenticateInvalidResults {
    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);

    OCMStub([mockedLoginManager logInWithPublishPermissions:@[ @"publish" ]
                                         fromViewController:OCMOCK_ANY
                                                    handler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained FBSDKLoginManagerRequestTokenHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        FBSDKAccessToken *token = [[FBSDKAccessToken alloc] initWithTokenString:nil
                                                                    permissions:@[ @"publish" ]
                                                            declinedPermissions:nil
                                                                          appID:@"appId"
                                                                         userID:nil
                                                                 expirationDate:nil
                                                                    refreshDate:nil];
        FBSDKLoginManagerLoginResult *result = [[FBSDKLoginManagerLoginResult alloc] initWithToken:token
                                                                                       isCancelled:NO
                                                                                grantedPermissions:[NSSet setWithObject:@"publish"]
                                                                               declinedPermissions:nil];

        handler(result, nil);
    });

    PFFacebookMobileAuthenticationProvider *provider = [[PFFacebookMobileAuthenticationProvider alloc] initWithApplication:[UIApplication sharedApplication] launchOptions:nil];
    provider.loginManager = mockedLoginManager;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[provider authenticateAsyncWithReadPermissions:nil publishPermissions:@[ @"publish" ]] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        XCTAssertFalse(task.faulted);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testReauthenticate {
    NSDictionary *authData = @{ @"id" : @"fbId",
                                @"access_token" : @"token",
                                @"expiration_date" : @"1970-01-01T00:22:17.000Z" };

    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);

    PFFacebookMobileAuthenticationProvider *provider = [[PFFacebookMobileAuthenticationProvider alloc] initWithApplication:[UIApplication sharedApplication] launchOptions:nil];
    provider.loginManager = mockedLoginManager;

    XCTAssertTrue([provider restoreAuthenticationWithAuthData:authData]);
}

- (void)testRestoreAuthNil {
    id mockedLoginManager = PFStrictClassMock([FBSDKLoginManager class]);
    OCMExpect([mockedLoginManager logOut]);

    PFFacebookMobileAuthenticationProvider *provider = [[PFFacebookMobileAuthenticationProvider alloc] initWithApplication:[UIApplication sharedApplication] launchOptions:nil];
    provider.loginManager = mockedLoginManager;

    XCTAssertTrue([provider restoreAuthenticationWithAuthData:nil]);

    OCMVerifyAll(mockedLoginManager);
}

@end
