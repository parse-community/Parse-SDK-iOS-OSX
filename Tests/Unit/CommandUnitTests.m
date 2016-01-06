/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "BFTask+Private.h"
#import "PFHTTPRequest.h"
#import "PFJSONSerialization.h"
#import "PFMockURLProtocol.h"
#import "PFRESTCommand.h"
#import "PFURLSessionCommandRunner.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"
#import "ParseClientConfiguration_Private.h"

@interface CommandUnitTests : PFUnitTestCase

@end

@implementation CommandUnitTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    [Parse _currentManager].commandRunner.initialRetryDelay = 0.001;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testNoRetryOn400StatusCode {
    __block NSUInteger retryCount = 0;
    [PFMockURLProtocol mockRequestsWithResponse:^PFMockURLResponse *(NSURLRequest *request) {
        retryCount++;
        NSDictionary *response = @{ @"error" : @"yarr",
                                    @"code" : @100500 };
        NSString *json = [PFJSONSerialization stringFromJSONObject:response];
        return [PFMockURLResponse responseWithString:json statusCode:400 delay:0.0];
    }];

    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"login"
                                                     httpMethod:PFHTTPRequestMethodPOST
                                                     parameters:nil
                                                   sessionToken:nil];

    NSError *error = nil;
    PFURLSessionCommandRunner *commandRunner = [PFURLSessionCommandRunner commandRunnerWithDataSource:[Parse _currentManager]
                                                                                        applicationId:[Parse getApplicationId]
                                                                                            clientKey:[Parse getClientKey]
                                                                                            serverURL:[NSURL URLWithString:_ParseDefaultServerURLString]];
    [[commandRunner runCommandAsync:command
                        withOptions:PFCommandRunningOptionRetryIfFailed] waitForResult:&error];

    XCTAssertEqualObjects(@"yarr", error.userInfo[@"error"]);
    XCTAssertEqual(100500, error.code);
    XCTAssertEqual(retryCount, 1);

    [PFMockURLProtocol removeAllMocking];
}

- (void)testRetryOn500StatusCode {
    __block NSUInteger retryCount = 0;
    [PFMockURLProtocol mockRequestsWithResponse:^PFMockURLResponse *(NSURLRequest *request) {
        retryCount++;
        NSDictionary *response = @{ @"error" : @"yarr",
                                    @"code" : @100500 };
        NSString *json = [PFJSONSerialization stringFromJSONObject:response];
        return [PFMockURLResponse responseWithString:json statusCode:500 delay:0.0];
    }];

    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"login"
                                                     httpMethod:PFHTTPRequestMethodPOST
                                                     parameters:nil
                                                   sessionToken:nil];

    NSError *error = nil;
    PFURLSessionCommandRunner *commandRunner = [PFURLSessionCommandRunner commandRunnerWithDataSource:[Parse _currentManager]
                                                                                        applicationId:[Parse getApplicationId]
                                                                                            clientKey:[Parse getClientKey]
                                                                                            serverURL:[NSURL URLWithString:_ParseDefaultServerURLString]];
    commandRunner.initialRetryDelay = DBL_MIN;
    [[commandRunner runCommandAsync:command
                        withOptions:PFCommandRunningOptionRetryIfFailed] waitForResult:&error];

    XCTAssertEqualObjects(@"yarr", error.userInfo[@"error"]);
    XCTAssertEqual(100500, error.code);
    XCTAssertEqual(retryCount, 5);

    [PFMockURLProtocol removeAllMocking];
}

- (void)testCacheKeysFromCommand {
    NSMutableDictionary *orderedDict = [NSMutableDictionary dictionary];
    for (int i = 1; i <= 30; ++i) {
        [orderedDict setObject:[NSString stringWithFormat:@"value%d", i]
                        forKey:[NSString stringWithFormat:@"key%d", i]];
    }
    PFRESTCommand *orderedCommand = [PFRESTCommand commandWithHTTPPath:@"foo"
                                                            httpMethod:PFHTTPRequestMethodGET
                                                            parameters:orderedDict
                                                          sessionToken:nil];

    NSMutableDictionary *reversedDict = [NSMutableDictionary dictionary];
    for (int i = 30; i >= 1; --i) {
        [reversedDict setObject:[NSString stringWithFormat:@"value%d", i]
                         forKey:[NSString stringWithFormat:@"key%d", i]];
    }
    PFRESTCommand *reversedCommand = [PFRESTCommand commandWithHTTPPath:@"foo"
                                                             httpMethod:PFHTTPRequestMethodGET
                                                             parameters:reversedDict
                                                           sessionToken:nil];

    XCTAssertEqualObjects(orderedCommand.cacheKey, reversedCommand.cacheKey,
                          @"identifiers should be invariant to dictionary key orders");
}

@end
