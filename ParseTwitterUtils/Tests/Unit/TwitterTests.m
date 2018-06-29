/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Accounts;
@import Bolts.BFTask;
@import Parse.PFConstants;
@import Social;

#import "PFOAuth1FlowDialog.h"
#import "PFTwitterAlertView.h"
#import "PFTwitterTestCase.h"
#import "PFTwitterTestMacros.h"
#import "PF_Twitter_Private.h"

typedef void (^NSURLSessionDataTaskCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);

@interface TwitterTests : PFTwitterTestCase
@end

@implementation TwitterTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    PF_Twitter *twitter = [[PF_Twitter alloc] init];
    XCTAssertNotNil(twitter);
    XCTAssertNotNil(twitter.accountStore);

    ACAccountStore *store = PFStrictClassMock([ACAccountStore class]);
    NSURLSession *session = PFStrictClassMock([NSURLSession class]);
    id dialogClass = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    twitter = [[PF_Twitter alloc] initWithAccountStore:store urlSession:session dialogClass:dialogClass];
    XCTAssertNotNil(twitter);
    XCTAssertEqual(twitter.accountStore, store);
    XCTAssertEqual(twitter.urlSession, session);
    XCTAssertEqual(twitter.oauthDialogClass, dialogClass);
}

- (void)testProperties {
    PF_Twitter *twitter = [[PF_Twitter alloc] init];

    XCTAssertNil(twitter.consumerKey);
    XCTAssertNil(twitter.consumerKey);
    XCTAssertNil(twitter.consumerSecret);
    XCTAssertNil(twitter.authToken);
    XCTAssertNil(twitter.authTokenSecret);
    XCTAssertNil(twitter.userId);
    XCTAssertNil(twitter.screenName);

    twitter.consumerKey = @"a";
    XCTAssertEqualObjects(twitter.consumerKey, @"a");
    twitter.consumerSecret = @"b";
    XCTAssertEqualObjects(twitter.consumerSecret, @"b");
    twitter.authToken = @"c";
    XCTAssertEqualObjects(twitter.authToken, @"c");
    twitter.authTokenSecret = @"d";
    XCTAssertEqualObjects(twitter.authTokenSecret, @"d");
    twitter.userId = @"e";
    XCTAssertEqualObjects(twitter.userId, @"e");
    twitter.screenName = @"f";
    XCTAssertEqualObjects(twitter.screenName, @"f");
}

- (void)testAuthorizeWithoutRequiredKeys {
    id store = PFStrictClassMock([ACAccountStore class]);
    NSURLSession *session = PFStrictClassMock([NSURLSession class]);
    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:store urlSession:session dialogClass:mockedDialog];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter authorizeInBackground] continueWithBlock:^id(BFTask *task) {
        NSError *error = task.error;
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
        //TODO: (nlutsenko) Add code verification when we have proper code reported.
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testSignRequest {
    id store = PFStrictClassMock([ACAccountStore class]);
    NSURLSession *session = PFStrictClassMock([NSURLSession class]);
    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:store urlSession:session dialogClass:mockedDialog];

    twitter.consumerKey = @"consumer_key";
    twitter.consumerSecret = @"consumer_secret";

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [twitter signRequest:request];

    XCTAssertNotNil([request valueForHTTPHeaderField:@"Authorization"]);
}

- (void)testAuthorizeWithCallbackBlocks {
    id store = PFStrictClassMock([ACAccountStore class]);
    NSURLSession *session = PFStrictClassMock([NSURLSession class]);
    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:store urlSession:session dialogClass:mockedDialog];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [twitter authorizeWithSuccess:^{
        XCTFail(@"Did not expect success!");
    } failure:^(NSError *error) {
        [expectation fulfill];
    } cancel:^{
        XCTFail(@"Did not expect cancellation!");
    }];

    [self waitForTestExpectations];
}

- (void)testAuthorizeWithLocalAccountErrorAndNetworkError {
    id mockedStore = PFStrictClassMock([ACAccountStore class]);
    id mockedURLSession = PFStrictClassMock([NSURLSession class]);
    id mockedOperationQueue = PFStrictClassMock([NSOperationQueue class]);
    id mockedComposeViewController = PFStrictClassMock([SLComposeViewController class]);

    NSError *expectedError = [NSError errorWithDomain:PFParseErrorDomain code:1337 userInfo:nil];

    OCMStub(ClassMethod([mockedComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])).andReturn(YES);
    OCMStub([mockedStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]).andReturn(nil);

    OCMStub([mockedStore requestAccessToAccountsWithType:nil
                                                 options:nil
                                              completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained ACAccountStoreRequestAccessCompletionHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        handler(NO, expectedError);
    });

    [OCMExpect([mockedURLSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"request_token"];
    }] completionHandler:[OCMArg isNotNil]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSURLSessionDataTaskCompletionHandler completionHandler = nil;
        [invocation getArgument:&completionHandler atIndex:3];

        completionHandler(nil, nil, expectedError);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];

    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:mockedStore
                                                        urlSession:mockedURLSession
                                                       dialogClass:mockedDialog];

    twitter.consumerKey = @"consumer_key";
    twitter.consumerSecret = @"consumer_secret";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter authorizeInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, expectedError);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
    OCMVerifyAll(mockedOperationQueue);
}

- (void)testAuthorizeWithoutLocalAccountAndNetworkError {
    id mockedStore = PFStrictClassMock([ACAccountStore class]);
    id mockedURLSession = PFStrictClassMock([NSURLSession class]);
    id mockedOperationQueue = PFStrictClassMock([NSOperationQueue class]);

    NSError *expectedError = [NSError errorWithDomain:PFParseErrorDomain code:1337 userInfo:nil];

    [OCMExpect([mockedURLSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"request_token"];
    }] completionHandler:[OCMArg isNotNil]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSURLSessionDataTaskCompletionHandler completionHandler = nil;
        [invocation getArgument:&completionHandler atIndex:3];

        completionHandler(nil, nil, expectedError);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];

    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:mockedStore
                                                        urlSession:mockedURLSession
                                                       dialogClass:mockedDialog];

    twitter.consumerKey = @"consumer_key";
    twitter.consumerSecret = @"consumer_secret";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter authorizeInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, expectedError);
        XCTAssertNil(task.result);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
    OCMVerifyAll(mockedOperationQueue);
}

- (void)testAuthorizeWithLocalAccountAndNetworkError {
    id mockedStore = PFStrictClassMock([ACAccountStore class]);
    id mockedURLSession = PFStrictClassMock([NSURLSession class]);
    id mockedComposeViewController = PFStrictClassMock([SLComposeViewController class]);

    OCMStub(ClassMethod([mockedComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])).andReturn(YES);
    OCMStub([mockedStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]).andReturn(nil);

    OCMStub([mockedStore requestAccessToAccountsWithType:nil
                                                 options:nil
                                              completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained ACAccountStoreRequestAccessCompletionHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        handler(YES, nil);
    });

    id mockedAccount = PFStrictClassMock([ACAccount class]);

    NSArray *twitterAccounts = @[ mockedAccount ];
    OCMStub([mockedStore accountsWithAccountType:nil]).andReturn(twitterAccounts);

    NSError *expectedError = [NSError errorWithDomain:PFParseErrorDomain code:1337 userInfo:nil];

    __block NSURLSessionDataTaskCompletionHandler completionHandler = nil;
    [OCMStub([mockedURLSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"request_token"];
    }] completionHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
        completionHandler = obj;
        return (obj != nil);
    }]]).andDo(^(NSInvocation *invocation) {
        completionHandler(nil, nil, expectedError);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];

    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:mockedStore
                                                        urlSession:mockedURLSession
                                                       dialogClass:mockedDialog];

    twitter.consumerKey = @"consumer_key";
    twitter.consumerSecret = @"consumer_secret";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter authorizeInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, expectedError);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testAuthorizeWithSingleLocalAccountAndNetworkSuccess {
    id mockedStore = PFStrictClassMock([ACAccountStore class]);
    id mockedURLSession = PFStrictClassMock([NSURLSession class]);
    id mockedComposeViewController = PFStrictClassMock([SLComposeViewController class]);
    id mockedSLRequest = PFStrictClassMock([SLRequest class]);

    OCMStub(ClassMethod([mockedComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])).andReturn(YES);
    OCMStub([mockedStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]).andReturn(nil);

    OCMStub([mockedStore requestAccessToAccountsWithType:nil
                                                 options:nil
                                              completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained ACAccountStoreRequestAccessCompletionHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        handler(YES, nil);
    });

    id mockedAccount = PFStrictClassMock([ACAccount class]);
    OCMStub([mockedAccount accountType]).andReturn(nil);

    NSArray *twitterAccounts = @[ mockedAccount ];
    OCMStub([mockedStore accountsWithAccountType:nil]).andReturn(twitterAccounts);

    [OCMExpect([mockedURLSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"request_token"];
    }] completionHandler:[OCMArg isNotNil]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSURLSessionDataTaskCompletionHandler completionHandler = nil;
        [invocation getArgument:&completionHandler atIndex:3];

        NSString *successString = @"oauth_token=request_token&oauth_token_secret=request_secret";
        completionHandler([successString dataUsingEncoding:NSUTF8StringEncoding], nil, nil);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];

    __weak typeof(mockedSLRequest) weakSLRequest = mockedSLRequest;
    OCMStub(ClassMethod([[mockedSLRequest ignoringNonObjectArgs] requestForServiceType:SLServiceTypeTwitter
                                                                         requestMethod:0
                                                                                   URL:OCMOCK_ANY
                                                                            parameters:OCMOCK_ANY]))
    .andDo(^(NSInvocation *invocation) {
        __strong typeof(mockedSLRequest) slRequest = weakSLRequest;
        [invocation setReturnValue:&slRequest];
    });

    OCMStub([mockedSLRequest setAccount:OCMOCK_ANY]);
    OCMStub([mockedSLRequest performRequestWithHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained SLRequestHandler requestHandler = nil;
        [invocation getArgument:&requestHandler atIndex:2];

        NSString *successString = @"oauth_token=access_token&oauth_token_secret=access_secret&user_id=test_user&"
        @"screen_name=test_name";
        requestHandler([successString dataUsingEncoding:NSUTF8StringEncoding], nil, nil);
    });

    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:mockedStore
                                                        urlSession:mockedURLSession
                                                       dialogClass:mockedDialog];

    twitter.consumerKey = @"consumer_key";
    twitter.consumerSecret = @"consumer_secret";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter authorizeInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        XCTAssertNil(task.result);

        XCTAssertEqualObjects(@"access_token", twitter.authToken);
        XCTAssertEqualObjects(@"access_secret", twitter.authTokenSecret);
        XCTAssertEqualObjects(@"test_user", twitter.userId);
        XCTAssertEqualObjects(@"test_name", twitter.screenName);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testAuthorizeWithMultipleLocalAccountsAndNetworkSuccess {
    id mockedStore = PFStrictClassMock([ACAccountStore class]);
    id mockedSession = PFStrictClassMock([NSURLSession class]);
    id mockedComposeViewController = PFStrictClassMock([SLComposeViewController class]);
    id mockedSLRequest = PFStrictClassMock([SLRequest class]);
    id mockedAlertView = PFStrictClassMock([PFTwitterAlertView class]);

    OCMStub(ClassMethod([mockedComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])).andReturn(YES);
    OCMStub([mockedStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]).andReturn(nil);

    OCMStub([mockedStore requestAccessToAccountsWithType:nil
                                                 options:nil
                                              completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained ACAccountStoreRequestAccessCompletionHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        handler(YES, nil);
    });

    id mockedAccount = PFStrictClassMock([ACAccount class]);
    OCMStub([mockedAccount accountType]).andReturn(nil);
    OCMStub([mockedAccount valueForKey:@"accountDescription"]).andReturn(@"An Account");

    NSArray *twitterAccounts = @[ mockedAccount, mockedAccount ];
    OCMStub([mockedStore accountsWithAccountType:nil]).andReturn(twitterAccounts);

    [OCMExpect([mockedSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"request_token"];
    }] completionHandler:[OCMArg isNotNil]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSURLSessionDataTaskCompletionHandler completionHandler = nil;
        [invocation getArgument:&completionHandler atIndex:3];


        NSString *successString = @"oauth_token=request_token&oauth_token_secret=request_secret";
        completionHandler([successString dataUsingEncoding:NSUTF8StringEncoding], nil, nil);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];

    __weak typeof(mockedSLRequest) weakSLRequest = mockedSLRequest;
    OCMStub(ClassMethod([[mockedSLRequest ignoringNonObjectArgs] requestForServiceType:SLServiceTypeTwitter
                                                                         requestMethod:0
                                                                                   URL:OCMOCK_ANY
                                                                            parameters:OCMOCK_ANY]))
    .andDo(^(NSInvocation *invocation) {
        __strong typeof(mockedSLRequest) slRequest = weakSLRequest;
        [invocation setReturnValue:&slRequest];
    });

    OCMStub([mockedSLRequest setAccount:OCMOCK_ANY]);
    OCMStub([mockedSLRequest performRequestWithHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained SLRequestHandler requestHandler = nil;
        [invocation getArgument:&requestHandler atIndex:2];

        NSString *successString = @"oauth_token=access_token&oauth_token_secret=access_secret&user_id=test_user&"
        @"screen_name=test_name";
        requestHandler([successString dataUsingEncoding:NSUTF8StringEncoding], nil, nil);
    });

    OCMStub(ClassMethod([mockedAlertView showAlertWithTitle:OCMOCK_ANY
                                                    message:nil
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj count] == 2;
    }]
                                                 completion:OCMOCK_ANY])).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained PFTwitterAlertViewCompletion completionHandler = nil;
        [invocation getArgument:&completionHandler atIndex:6];

        completionHandler(0);
    });

    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:mockedStore
                                                        urlSession:mockedSession
                                                       dialogClass:mockedDialog];

    twitter.consumerKey = @"consumer_key";
    twitter.consumerSecret = @"consumer_secret";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter authorizeInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        XCTAssertNil(task.result);

        XCTAssertEqualObjects(@"access_token", twitter.authToken);
        XCTAssertEqualObjects(@"access_secret", twitter.authTokenSecret);
        XCTAssertEqualObjects(@"test_user", twitter.userId);
        XCTAssertEqualObjects(@"test_name", twitter.screenName);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testAuthorizeWithZeroLocalAccountsAndNetworkSuccess {
    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    id mockedStore = PFStrictClassMock([ACAccountStore class]);
    id mockedURLSession = PFStrictClassMock([NSURLSession class]);
    id mockedComposeViewController = PFStrictClassMock([SLComposeViewController class]);
    id mockedSLRequest = PFStrictClassMock([SLRequest class]);

    OCMStub(ClassMethod([mockedComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])).andReturn(YES);
    OCMStub([mockedStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]).andReturn(nil);

    OCMStub([mockedStore requestAccessToAccountsWithType:nil
                                                 options:nil
                                              completion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained ACAccountStoreRequestAccessCompletionHandler handler = nil;
        [invocation getArgument:&handler atIndex:4];

        handler(YES, nil);
    });

    id mockedAccount = PFStrictClassMock([ACAccount class]);
    OCMStub([mockedAccount accountType]).andReturn(nil);

    NSArray *twitterAccounts = @[];
    OCMStub([mockedStore accountsWithAccountType:nil]).andReturn(twitterAccounts);

    __weak typeof(mockedSLRequest) weakSLRequest = mockedSLRequest;
    OCMStub(ClassMethod([[mockedSLRequest ignoringNonObjectArgs] requestForServiceType:SLServiceTypeTwitter
                                                                         requestMethod:0
                                                                                   URL:OCMOCK_ANY
                                                                            parameters:OCMOCK_ANY]))
    .andDo(^(NSInvocation *invocation) {
        __strong typeof(mockedSLRequest) slRequest = weakSLRequest;
        [invocation setReturnValue:&slRequest];
    });

    [OCMExpect([mockedURLSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"request_token"];
    }] completionHandler:[OCMArg isNotNil]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSURLSessionDataTaskCompletionHandler completionHandler = nil;
        [invocation getArgument:&completionHandler atIndex:3];


        NSString *successString = @"oauth_token=request_token&oauth_token_secret=request_secret";
        completionHandler([successString dataUsingEncoding:NSUTF8StringEncoding], nil, nil);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];
    [OCMExpect([mockedURLSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"access_token"];
    }] completionHandler:[OCMArg isNotNil]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSURLSessionDataTaskCompletionHandler completionHandler = nil;
        [invocation getArgument:&completionHandler atIndex:3];


        NSString *successString = @"oauth_token=access_token&oauth_token_secret=access_secret&user_id=test_user&"
        @"screen_name=test_name";
        completionHandler([successString dataUsingEncoding:NSUTF8StringEncoding], nil, nil);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];

    OCMExpect([mockedDialog dialogWithURL:OCMOCK_ANY queryParameters:OCMOCK_ANY]).andReturnWeak(mockedDialog);
    OCMExpect([mockedDialog setRedirectURLPrefix:@"http://twitter-oauth.callback"]);

    __block PFOAuth1FlowDialogCompletion completionHandler = nil;
    OCMExpect([mockedDialog setCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained PFOAuth1FlowDialogCompletion newHandler = nil;
        [invocation getArgument:&newHandler atIndex:2];

        completionHandler = [newHandler copy];
    });

    OCMExpect([[mockedDialog ignoringNonObjectArgs] showAnimated:NO]).andDo(^(NSInvocation *invocation) {
        completionHandler(
                          YES,
                          [NSURL URLWithString:@"http://twitter-oauth.callback/?oauth_token=sucess_token&oauth_token_secret=success_secret"],
                          nil
                          );
    });

    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:mockedStore
                                                        urlSession:mockedURLSession
                                                       dialogClass:mockedDialog];

    twitter.consumerKey = @"consumer_key";
    twitter.consumerSecret = @"consumer_secret";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter authorizeInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        XCTAssertNil(task.result);

        XCTAssertEqualObjects(@"access_token", twitter.authToken);
        XCTAssertEqualObjects(@"access_secret", twitter.authTokenSecret);
        XCTAssertEqualObjects(@"test_user", twitter.userId);
        XCTAssertEqualObjects(@"test_name", twitter.screenName);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];

    OCMVerifyAll(mockedDialog);
    OCMVerifyAll(mockedURLSession);
}

- (void)testAuthorizeWithoutLocalAccountAndNetworkSuccess {
    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    id mockedStore = PFStrictClassMock([ACAccountStore class]);
    id mockedURLSession = PFStrictClassMock([NSURLSession class]);

    [OCMExpect([mockedURLSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"request_token"];
    }] completionHandler:[OCMArg isNotNil]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSURLSessionDataTaskCompletionHandler completionHandler = nil;
        [invocation getArgument:&completionHandler atIndex:3];


        NSString *successString = @"oauth_token=request_token&oauth_token_secret=request_secret";
        completionHandler([successString dataUsingEncoding:NSUTF8StringEncoding], nil, nil);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];
    [OCMExpect([mockedURLSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"access_token"];
    }] completionHandler:[OCMArg isNotNil]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSURLSessionDataTaskCompletionHandler completionHandler = nil;
        [invocation getArgument:&completionHandler atIndex:3];


        NSString *successString = @"oauth_token=access_token&oauth_token_secret=access_secret&user_id=test_user&"
        @"screen_name=test_name";
        completionHandler([successString dataUsingEncoding:NSUTF8StringEncoding], nil, nil);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];

    OCMExpect([mockedDialog dialogWithURL:OCMOCK_ANY queryParameters:OCMOCK_ANY]).andReturnWeak(mockedDialog);
    OCMExpect([mockedDialog setRedirectURLPrefix:@"http://twitter-oauth.callback"]);

    __block PFOAuth1FlowDialogCompletion completionHandler = nil;
    OCMExpect([mockedDialog setCompletion:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained PFOAuth1FlowDialogCompletion newHandler = nil;
        [invocation getArgument:&newHandler atIndex:2];

        completionHandler = [newHandler copy];
    });

    OCMExpect([[mockedDialog ignoringNonObjectArgs] showAnimated:NO]).andDo(^(NSInvocation *invocation) {
        completionHandler(
                          YES,
                          [NSURL URLWithString:@"http://twitter-oauth.callback/?oauth_token=sucess_token&oauth_token_secret=success_secret"],
                          nil
                          );
    });

    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:mockedStore
                                                        urlSession:mockedURLSession
                                                       dialogClass:mockedDialog];

    twitter.consumerKey = @"consumer_key";
    twitter.consumerSecret = @"consumer_secret";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter authorizeInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        XCTAssertNil(task.result);

        XCTAssertEqualObjects(@"access_token", twitter.authToken);
        XCTAssertEqualObjects(@"access_secret", twitter.authTokenSecret);
        XCTAssertEqualObjects(@"test_user", twitter.userId);
        XCTAssertEqualObjects(@"test_name", twitter.screenName);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];

    OCMVerifyAll(mockedDialog);
    OCMVerifyAll(mockedURLSession);
}

- (void)testDeauthorizeLoggedOutAccount {
    id store = PFStrictClassMock([ACAccountStore class]);
    NSURLSession *session = PFStrictClassMock([NSURLSession class]);
    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:store urlSession:session dialogClass:mockedDialog];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter authorizeInBackground] continueWithBlock:^id(BFTask *task) {
        NSError *error = task.error;
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
        XCTAssertEqual(error.code, 1);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testDeauthorizeLoggedInAccount {
    id mockedStore = PFStrictClassMock([ACAccountStore class]);
    id mockedURLSession = PFStrictClassMock([NSURLSession class]);

    id mockedDialog = PFStrictProtocolMock(@protocol(PFOAuth1FlowDialogInterface));
    PF_Twitter *twitter = [[PF_Twitter alloc] initWithAccountStore:mockedStore urlSession:mockedURLSession dialogClass:mockedDialog];
    twitter.consumerKey = @"consumer_key";
    twitter.consumerSecret = @"consumer_secret";
    twitter.authToken = @"auth_token";
    twitter.authTokenSecret = @"auth_token_secret";
    twitter.userId = @"user_id";
    twitter.screenName = @"screen_name";

    __block NSURLSessionDataTaskCompletionHandler completionHandler = nil;
    [OCMStub([mockedURLSession dataTaskWithRequest:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSURLRequest *request = obj;
        return [request.URL.lastPathComponent isEqualToString:@"invalidate_token"];
    }] completionHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
        completionHandler = obj;
        return (obj != nil);
    }]]).andDo(^(NSInvocation *invocation) {
        completionHandler([NSData data], nil, nil);
    }) andReturn:[OCMockObject niceMockForClass:[NSURLSessionDataTask class]]];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[twitter deauthorizeInBackground] continueWithBlock:^id(BFTask *task) {
        NSError *error = task.error;
        XCTAssertNil(error);
        XCTAssertNotNil(task.result);

        XCTAssertNil(twitter.authToken);
        XCTAssertNil(twitter.authTokenSecret);
        XCTAssertNil(twitter.userId);
        XCTAssertNil(twitter.screenName);

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

@end
