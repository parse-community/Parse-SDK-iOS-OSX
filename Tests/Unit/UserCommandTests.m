/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFHTTPRequest.h"
#import "PFRESTUserCommand.h"
#import "PFTestCase.h"

@interface UserCommandTests : PFTestCase

@end

@implementation UserCommandTests

- (void)testLogInCommand {
    PFRESTUserCommand *command = [PFRESTUserCommand logInUserCommandWithUsername:@"a"
                                                                        password:@"b"
                                                                revocableSession:YES];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"login");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
    XCTAssertNotNil(command.parameters);
    XCTAssertNotNil(command.parameters[@"username"]);
    XCTAssertNotNil(command.parameters[@"password"]);
    XCTAssertEqual(command.additionalRequestHeaders.count, 1);
    XCTAssertTrue(command.revocableSessionEnabled);
    XCTAssertNil(command.sessionToken);

    command = [PFRESTUserCommand logInUserCommandWithUsername:@"a"
                                                     password:@"b"
                                             revocableSession:NO];
    XCTAssertNotNil(command);
    XCTAssertEqual(command.additionalRequestHeaders.count, 0);
    XCTAssertFalse(command.revocableSessionEnabled);
}

- (void)testServiceLoginCommandWithAuthTypeData {
    PFRESTUserCommand *command = [PFRESTUserCommand serviceLoginUserCommandWithAuthenticationType:@"a"
                                                                               authenticationData:@{ @"b" : @"c" }
                                                                                 revocableSession:YES];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"users");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters);
    XCTAssertNotNil(command.parameters[@"authData"]);
    XCTAssertEqualObjects(command.parameters[@"authData"], @{ @"a" : @{@"b" : @"c"} });
    XCTAssertEqual(command.additionalRequestHeaders.count, 1);
    XCTAssertTrue(command.revocableSessionEnabled);
    XCTAssertNil(command.sessionToken);

    command = [PFRESTUserCommand serviceLoginUserCommandWithAuthenticationType:@"a"
                                                            authenticationData:@{ @"b" : @"c" }
                                                              revocableSession:NO];
    XCTAssertNotNil(command);
    XCTAssertEqual(command.additionalRequestHeaders.count, 0);
    XCTAssertFalse(command.revocableSessionEnabled);
}

- (void)testServiceLoginCommandWithParameters {
    PFRESTUserCommand *command = [PFRESTUserCommand serviceLoginUserCommandWithParameters:@{ @"authData" : @{@"b" : @"c"} }
                                                                         revocableSession:YES
                                                                             sessionToken:@"Yarr"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"users");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters);
    XCTAssertNotNil(command.parameters[@"authData"]);
    XCTAssertEqualObjects(command.parameters[@"authData"], @{ @"b" : @"c" });
    XCTAssertEqual(command.additionalRequestHeaders.count, 1);
    XCTAssertTrue(command.revocableSessionEnabled);
    XCTAssertEqualObjects(command.sessionToken, @"Yarr");

    command = [PFRESTUserCommand serviceLoginUserCommandWithParameters:@{ @"authData" : @{@"b" : @"c"} }
                                                      revocableSession:NO
                                                          sessionToken:@"Yarr!"];
    XCTAssertNotNil(command);
    XCTAssertEqual(command.additionalRequestHeaders.count, 0);
    XCTAssertFalse(command.revocableSessionEnabled);
}

- (void)testSignUpCommand {
    PFRESTUserCommand *command = [PFRESTUserCommand signUpUserCommandWithParameters:@{ @"k" : @"v" }
                                                                   revocableSession:YES
                                                                       sessionToken:@"Boom"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"users");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters[@"k"]);
    XCTAssertEqual(command.additionalRequestHeaders.count, 1);
    XCTAssertTrue(command.revocableSessionEnabled);
    XCTAssertEqualObjects(command.sessionToken, @"Boom");

    command = [PFRESTUserCommand signUpUserCommandWithParameters:@{ @"k" : @"v" }
                                                revocableSession:NO
                                                    sessionToken:@"Boom"];
    XCTAssertNotNil(command);
    XCTAssertEqual(command.additionalRequestHeaders.count, 0);
    XCTAssertFalse(command.revocableSessionEnabled);
}

- (void)testGetCurrentUserCommand {
    PFRESTUserCommand *command = [PFRESTUserCommand getCurrentUserCommandWithSessionToken:@"yolo"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"users/me");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
    XCTAssertNil(command.parameters);
    XCTAssertEqualObjects(command.sessionToken, @"yolo");
}

- (void)testUpgradeToRevocableSessionCommand {
    PFRESTUserCommand *command = [PFRESTUserCommand upgradeToRevocableSessionCommandWithSessionToken:@"yolo"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"upgradeToRevocableSession");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNil(command.parameters);
    XCTAssertEqualObjects(command.sessionToken, @"yolo");
}

- (void)testLogOutUserCommand {
    PFRESTUserCommand *command = [PFRESTUserCommand logOutUserCommandWithSessionToken:@"yolo"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"logout");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNil(command.parameters);
    XCTAssertEqualObjects(command.sessionToken, @"yolo");
}

- (void)testResetPasswordCommand {
    PFRESTUserCommand *command = [PFRESTUserCommand resetPasswordCommandForUserWithEmail:@"nlutsenko@me.com"];
    XCTAssertNotNil(command);
    XCTAssertEqualObjects(command.httpPath, @"requestPasswordReset");
    XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
    XCTAssertNotNil(command.parameters[@"email"]);
    XCTAssertNil(command.sessionToken);
}

@end
