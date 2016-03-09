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
#import "PFCommandRunningConstants.h"
#import "PFCommandURLRequestConstructor.h"
#import "PFHTTPRequest.h"
#import "PFInstallationIdentifierStore.h"
#import "PFRESTCommand.h"
#import "PFTestCase.h"
#import "Parse_Private.h"

@interface CommandURLRequestConstructorTests : PFTestCase

@end

@implementation CommandURLRequestConstructorTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id)mockedInstallationidentifierStoreProviderWithInstallationIdentifier:(NSString *)identifier {
    id providerMock = PFStrictProtocolMock(@protocol(PFInstallationIdentifierStoreProvider));
    id storeMock = PFStrictClassMock([PFInstallationIdentifierStore class]);
    OCMStub([providerMock installationIdentifierStore]).andReturn(storeMock);
    OCMStub([storeMock getInstallationIdentifierAsync]).andReturn([BFTask taskWithResult:identifier]);
    return providerMock;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id providerMock = [self mockedInstallationidentifierStoreProviderWithInstallationIdentifier:nil];
    NSURL *url = [NSURL URLWithString:@"https://parse.com/123"];

    PFCommandURLRequestConstructor *constructor = [PFCommandURLRequestConstructor constructorWithDataSource:providerMock serverURL:url];
    XCTAssertNotNil(constructor);
    XCTAssertEqual((id)constructor.dataSource, providerMock);
    XCTAssertEqual(constructor.serverURL, url);
}

- (void)testDataURLRequest {
    id providerMock = [self mockedInstallationidentifierStoreProviderWithInstallationIdentifier:@"installationId"];
    NSURL *url = [NSURL URLWithString:@"https://parse.com/123"];
    PFCommandURLRequestConstructor *constructor = [PFCommandURLRequestConstructor constructorWithDataSource:providerMock serverURL:url];

    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"yolo"
                                                     httpMethod:PFHTTPRequestMethodPOST
                                                     parameters:@{ @"a" : @"b" }
                                                   sessionToken:@"yarr"];
    command.additionalRequestHeaders = @{ @"CustomHeader" : @"CustomValue" };

    NSURLRequest *request = [[constructor getDataURLRequestAsyncForCommand:command] waitForResult:nil];
    XCTAssertTrue([[request.URL absoluteString] containsString:@"/123/yolo"]);
    XCTAssertEqualObjects(request.allHTTPHeaderFields, (@{ PFCommandHeaderNameInstallationId : @"installationId",
                                                           PFCommandHeaderNameSessionToken : @"yarr",
                                                           PFHTTPRequestHeaderNameContentType : @"application/json; charset=utf-8",
                                                           @"CustomHeader" : @"CustomValue" }));
    XCTAssertEqualObjects(request.HTTPMethod, @"POST");
    XCTAssertNotNil(request.HTTPBody);
}

- (void)testDataURLRequestMethodOverride {
    id providerMock = [self mockedInstallationidentifierStoreProviderWithInstallationIdentifier:@"installationId"];
    NSURL *url = [NSURL URLWithString:@"https://parse.com/123"];
    PFCommandURLRequestConstructor *constructor = [PFCommandURLRequestConstructor constructorWithDataSource:providerMock serverURL:url];

    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"yolo"
                                                     httpMethod:PFHTTPRequestMethodGET
                                                     parameters:@{ @"a" : @"b" }
                                                   sessionToken:@"yarr"];
    NSURLRequest *request = [[constructor getDataURLRequestAsyncForCommand:command] waitForResult:nil];
    XCTAssertEqualObjects(request.HTTPMethod, @"POST");

    command = [PFRESTCommand commandWithHTTPPath:@"yolo"
                                      httpMethod:PFHTTPRequestMethodHEAD
                                      parameters:@{ @"a" : @"b" }
                                    sessionToken:@"yarr"];
    request = [[constructor getDataURLRequestAsyncForCommand:command] waitForResult:nil];
    XCTAssertEqualObjects(request.HTTPMethod, @"POST");

    command = [PFRESTCommand commandWithHTTPPath:@"yolo"
                                      httpMethod:PFHTTPRequestMethodGET
                                      parameters:@{ @"a" : @"b" }
                                    sessionToken:@"yarr"];
    request = [[constructor getDataURLRequestAsyncForCommand:command] waitForResult:nil];
    XCTAssertEqualObjects(request.HTTPMethod, @"POST");

    command = [PFRESTCommand commandWithHTTPPath:@"yolo"
                                      httpMethod:PFHTTPRequestMethodGET
                                      parameters:nil
                                    sessionToken:@"yarr"];
    request = [[constructor getDataURLRequestAsyncForCommand:command] waitForResult:nil];
    XCTAssertEqualObjects(request.HTTPMethod, @"GET");
}

- (void)testDataURLRequestBodyEncoding {
    id providerMock = [self mockedInstallationidentifierStoreProviderWithInstallationIdentifier:@"installationId"];
    NSURL *url = [NSURL URLWithString:@"https://parse.com/123"];
    PFCommandURLRequestConstructor *constructor = [PFCommandURLRequestConstructor constructorWithDataSource:providerMock serverURL:url];

    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"yolo"
                                                     httpMethod:PFHTTPRequestMethodPOST
                                                     parameters:@{ @"a" : @100500 }
                                                   sessionToken:@"yarr"];
    NSURLRequest *request = [[constructor getDataURLRequestAsyncForCommand:command] waitForResult:nil];
    id json = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    XCTAssertNotNil(json);
    XCTAssertEqualObjects(json, @{ @"a" : @100500 });
}

- (void)testFileUploadURLRequest {
    id providerMock = [self mockedInstallationidentifierStoreProviderWithInstallationIdentifier:@"installationId"];
    NSURL *url = [NSURL URLWithString:@"https://parse.com/123"];
    PFCommandURLRequestConstructor *constructor = [PFCommandURLRequestConstructor constructorWithDataSource:providerMock serverURL:url];

    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"yolo"
                                                     httpMethod:PFHTTPRequestMethodPOST
                                                     parameters:@{ @"a" : @100500 }
                                                   sessionToken:@"yarr"];
    NSURLRequest *request = [[constructor getFileUploadURLRequestAsyncForCommand:command
                                                                 withContentType:@"boom"
                                                           contentSourceFilePath:@"/dev/null"] waitForResult:nil];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.allHTTPHeaderFields[PFHTTPRequestHeaderNameContentType], @"boom");
}

- (void)testDefaultURLRequestHeaders {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSDictionary *headers = [PFCommandURLRequestConstructor defaultURLRequestHeadersForApplicationId:@"a"
                                                                                           clientKey:@"b"
                                                                                              bundle:bundle];
    XCTAssertNotNil(headers);
    XCTAssertEqualObjects(headers[PFCommandHeaderNameApplicationId], @"a");
    XCTAssertEqualObjects(headers[PFCommandHeaderNameClientKey], @"b");
    XCTAssertNotNil(headers[PFCommandHeaderNameClientVersion]);
    XCTAssertNotNil(headers[PFCommandHeaderNameOSVersion]);
    XCTAssertNotNil(headers[PFCommandHeaderNameAppBuildVersion]);
    XCTAssertNotNil(headers[PFCommandHeaderNameAppDisplayVersion]);
}

@end
