/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Bolts.BFTask;

#import "PFTwitterAuthenticationProvider.h"
#import "PFTwitterTestCase.h"
#import "PF_Twitter.h"

@interface TwitterAuthenticationProviderTests : PFTwitterTestCase

@end

@implementation TwitterAuthenticationProviderTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PF_Twitter *)mockedTwitter {
    PF_Twitter *twitter = PFStrictClassMock([PF_Twitter class]);

    OCMStub(twitter.consumerKey).andReturn(@"yarr");
    OCMStub(twitter.consumerSecret).andReturn(@"yolo");

    return twitter;
}

- (void)assertValidAuthenticationData:(NSDictionary *)authData forTwitter:(PF_Twitter *)twitter {
    XCTAssertEqualObjects(authData[@"id"], @"a");
    XCTAssertEqualObjects(authData[@"screen_name"], @"b");
    XCTAssertEqualObjects(authData[@"auth_token"], @"c");
    XCTAssertEqualObjects(authData[@"auth_token_secret"], @"d");
    XCTAssertEqualObjects(authData[@"consumer_key"], twitter.consumerKey);
    XCTAssertEqualObjects(authData[@"consumer_secret"], twitter.consumerSecret);
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    PF_Twitter *twitter = [self mockedTwitter];
    PFTwitterAuthenticationProvider *provider = [[PFTwitterAuthenticationProvider alloc] initWithTwitter:twitter];
    XCTAssertNotNil(provider);
    XCTAssertEqual(provider.twitter, twitter);

    provider = [PFTwitterAuthenticationProvider providerWithTwitter:twitter];
    XCTAssertNotNil(provider);
    XCTAssertEqual(provider.twitter, twitter);

    PFAssertThrowsInconsistencyException([PFTwitterAuthenticationProvider new]);
}

- (void)testAuthData {
    PF_Twitter *twitter = [self mockedTwitter];
    PFTwitterAuthenticationProvider *provider = [[PFTwitterAuthenticationProvider alloc] initWithTwitter:twitter];

    NSDictionary *authData = [provider authDataWithTwitterId:@"a"
                                                  screenName:@"b"
                                                   authToken:@"c"
                                                      secret:@"d"];
    [self assertValidAuthenticationData:authData forTwitter:twitter];
}

- (void)testAuthType {
    XCTAssertEqualObjects(PFTwitterUserAuthenticationType, @"twitter");
}

- (void)testAuthenticateAsync {
    PF_Twitter *twitter = [self mockedTwitter];

    OCMStub(twitter.userId).andReturn(@"a");
    OCMStub(twitter.screenName).andReturn(@"b");
    OCMStub(twitter.authToken).andReturn(@"c");
    OCMStub(twitter.authTokenSecret).andReturn(@"d");

    BFTask *task = [BFTask taskWithResult:nil];
    OCMStub([twitter authorizeInBackground]).andReturn(task);

    PFTwitterAuthenticationProvider *provider = [PFTwitterAuthenticationProvider providerWithTwitter:twitter];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[provider authenticateAsync] continueWithBlock:^id(BFTask *t) {
        NSDictionary *authData = t.result;
        XCTAssertNotNil(authData);
        [self assertValidAuthenticationData:authData forTwitter:twitter];

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testRestoreAuthentication {
    PF_Twitter *twitter = [self mockedTwitter];
    OCMExpect(twitter.userId = @"a");
    OCMExpect(twitter.screenName = @"b");
    OCMExpect(twitter.authToken = @"c");
    OCMExpect(twitter.authTokenSecret = @"d");

    PFTwitterAuthenticationProvider *provider = [PFTwitterAuthenticationProvider providerWithTwitter:twitter];

    NSDictionary *authData = @{ @"id" : @"a",
                                @"screen_name" : @"b",
                                @"auth_token" : @"c",
                                @"auth_token_secret" : @"d" };
    XCTAssertTrue([provider restoreAuthenticationWithAuthData:authData]);

    OCMVerifyAll((id)twitter);
}

- (void)testRestoreAuthenticationBadData {
    PF_Twitter *twitter = [self mockedTwitter];
    PFTwitterAuthenticationProvider *provider = [PFTwitterAuthenticationProvider providerWithTwitter:twitter];

    NSDictionary *authData = @{ @"bad" : @"data" };
    XCTAssertFalse([provider restoreAuthenticationWithAuthData:authData]);
}

- (void)testRestoreAuthenticationWithNoData {
    PF_Twitter *twitter = [self mockedTwitter];
    OCMExpect(twitter.userId = nil);
    OCMExpect(twitter.authToken = nil);
    OCMExpect(twitter.authTokenSecret = nil);
    OCMExpect(twitter.screenName = nil);

    PFTwitterAuthenticationProvider *provider = [PFTwitterAuthenticationProvider providerWithTwitter:twitter];
    XCTAssertTrue([provider restoreAuthenticationWithAuthData:nil]);

    OCMVerifyAll((id)twitter);
}

@end
