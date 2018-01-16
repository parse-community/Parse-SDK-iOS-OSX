/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.H>

@import Bolts.BFTask;

#import "PFCoreManager.h"
#import "PFCurrentInstallationController.h"
#import "PFMacros.h"
#import "PFMutablePushState.h"
#import "PFMutableQueryState.h"
#import "PFPush.h"
#import "PFPushChannelsController.h"
#import "PFPushController.h"
#import "PFPushManager.h"
#import "PFPushPrivate.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface PushUnitTests : PFUnitTestCase

@property (nonatomic, strong) XCTestExpectation *expectationToFulfuill;
@property (nonatomic, copy) void (^validationBlock)(id);

@end

@implementation PushUnitTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFPushManager *)mockedPushManager {
    PFPushManager *mockedManager = PFStrictClassMock([PFPushManager class]);
    PFPushController *mockedController = PFStrictClassMock([PFPushController class]);
    PFPushChannelsController *mockedChannelsController = PFStrictClassMock([PFPushChannelsController class]);

    OCMStub(mockedManager.channelsController).andReturn(mockedChannelsController);
    OCMStub(mockedManager.pushController).andReturn(mockedController);

    return mockedManager;
}

- (void)validateObjectResults:(id)results error:(NSError *)error {
    XCTAssertNil(error);

    self.validationBlock(results);
    [self.expectationToFulfuill fulfill];
}

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    [Parse _currentManager].pushManager = [self mockedPushManager];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    PFPush *push = [PFPush push];
    XCTAssertNotNil(push);

    push = [[PFPush alloc] init];
    XCTAssertNotNil(push);
}

- (void)testCopy {
    PFPush *push = [PFPush push];
    PFPush *copied = [push copy];
    XCTAssertNotEqual(push, copied);
}

#pragma mark NSObject

- (void)testEqualityAndHash {
    PFPush *pushA = [[PFPush alloc] init];
    PFPush *pushB = [[PFPush alloc] init];
    XCTAssertTrue([pushA isEqual:pushB]);
    XCTAssertEqual([pushA hash], [pushB hash]);

    PFQuery *query = [PFQuery queryWithClassName:@"aClass"];
    [pushA setQuery:query];
    XCTAssertFalse([pushA isEqual:pushB]);

    [pushB setQuery:query];
    XCTAssertTrue([pushA isEqual:pushB]);
    XCTAssertEqual([pushA hash], [pushB hash]);

    pushA = [[PFPush alloc] init];
    pushB = [[PFPush alloc] init];

    NSString *channelName = @"channel";
    [pushA setChannel:channelName];
    XCTAssertFalse([pushA isEqual:pushB]);

    [pushB setChannel:channelName];
    XCTAssertTrue([pushA isEqual:pushB]);
    XCTAssertEqual([pushA hash], [pushB hash]);

    NSString *message = @"Hello, World!";
    [pushA setMessage:message];
    XCTAssertFalse([pushA isEqual:pushB]);

    [pushB setMessage:message];
    XCTAssertTrue([pushA isEqual:pushB]);
    XCTAssertEqual([pushA hash], [pushB hash]);

    NSDate *date = [NSDate date];
    [pushA expireAtDate:date];
    XCTAssertFalse([pushA isEqual:pushB]);

    [pushB expireAtDate:date];
    XCTAssertTrue([pushA isEqual:pushB]);
    XCTAssertEqual([pushA hash], [pushB hash]);

    NSTimeInterval interval = 60;
    [pushA expireAfterTimeInterval:interval];
    XCTAssertFalse([pushA isEqual:pushB]);

    [pushB expireAfterTimeInterval:interval];
    XCTAssertTrue([pushA isEqual:pushB]);
    XCTAssertEqual([pushA hash], [pushB hash]);

    NSDictionary *payload = @{ @"foo" : @"bar" };
    [pushA setData:payload];
    XCTAssertFalse([pushA isEqual:pushB]);

    [pushB setData:payload];
    XCTAssertTrue([pushA isEqual:pushB]);
    XCTAssertEqual([pushA hash], [pushB hash]);
}

- (void)testHash {
    PFPush *pushA = [[PFPush alloc] init];
    PFPush *pushB = [[PFPush alloc] init];
    XCTAssertEqual([pushA hash], [pushB hash]);

    PFQuery *query = [PFQuery queryWithClassName:@"aClass"];
    [pushA setQuery:query];
    [pushB setQuery:query];
    XCTAssertEqual([pushA hash], [pushB hash]);

    pushA = [[PFPush alloc] init];
    pushB = [[PFPush alloc] init];

    NSString *channelName = @"channel";
    [pushA setChannel:channelName];
    [pushB setChannel:channelName];
    XCTAssertEqual([pushA hash], [pushB hash]);

    NSString *message = @"Hello, World!";
    [pushA setMessage:message];
    [pushB setMessage:message];
    XCTAssertEqual([pushA hash], [pushB hash]);

    NSDate *date = [NSDate date];
    [pushA expireAtDate:date];
    [pushB expireAtDate:date];
    XCTAssertEqual([pushA hash], [pushB hash]);

    NSTimeInterval interval = 60;
    [pushA expireAfterTimeInterval:interval];
    [pushB expireAfterTimeInterval:interval];
    XCTAssertEqual([pushA hash], [pushB hash]);

    NSDictionary *payload = @{ @"foo" : @"bar" };
    [pushA setData:payload];
    [pushB setData:payload];
    XCTAssertEqual([pushA hash], [pushB hash]);
}

- (void)testSendPush {
    NSString *channelName = @"channel";
    NSString *message = @"Hello, World!";

    PFPushController *mockedPushController = [Parse _currentManager].pushManager.pushController;

    PFPush *thePush = [PFPush push];
    PFMutablePushState *expectedPushState = [[PFMutablePushState alloc] init];

    [thePush setMessage:message];
    [expectedPushState setPayloadWithMessage:message];

    BFTask *mockedResult = [BFTask taskWithResult:@YES];
    OCMStub([mockedPushController sendPushNotificationAsyncWithState:[OCMArg isEqual:expectedPushState]
                                                        sessionToken:nil]).andReturn(mockedResult);

    XCTAssertTrue([thePush sendPush:NULL]);

    [thePush setChannel:channelName];
    [expectedPushState setChannels:PF_SET(channelName)];

    XCTAssertTrue([thePush sendPush:NULL]);

    [thePush setChannels:@[ channelName ]];

    XCTAssertTrue([thePush sendPush:NULL]);

    PFQuery *query = [PFQuery queryWithClassName:@"aClass"];
    PFQueryState *queryState = [[PFMutableQueryState alloc] initWithParseClassName:@"aClass"];

    thePush = [PFPush push];
    [thePush setMessage:message];
    [thePush setQuery:query];

    [expectedPushState setChannels:nil];
    [expectedPushState setQueryState:queryState];

    XCTAssertTrue([thePush sendPush:NULL]);

    NSDate *expiryDate = [NSDate dateWithTimeIntervalSinceNow:60 * 10];
    [thePush expireAtDate:expiryDate];
    [expectedPushState setExpirationDate:expiryDate];

    XCTAssertTrue([thePush sendPush:NULL]);

    [thePush expireAfterTimeInterval:60 * 10];
    [expectedPushState setExpirationDate:nil];
    [expectedPushState setExpirationTimeInterval:@(60 * 10)];

    XCTAssertTrue([thePush sendPush:NULL]);

    [thePush clearExpiration];
    [expectedPushState setExpirationTimeInterval:nil];

    XCTAssertTrue([thePush sendPush:NULL]);

    XCTestExpectation *backgroundBlockExpectation = [self expectationWithDescription:@"backgroundBlock"];
    XCTestExpectation *backgroundTargetSelectorExpectation = [self expectationWithDescription:@"backgroundTargetSel"];

    [[[thePush sendPushInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        XCTAssertTrue([task.result boolValue]);

        return task;
    }] waitUntilFinished];
    [thePush sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);

        [backgroundBlockExpectation fulfill];
    }];

    @weakify(self);
    self.validationBlock = ^(id success) {
        @strongify(self);
        XCTAssertTrue([success boolValue]);
    };

    self.expectationToFulfuill = backgroundTargetSelectorExpectation;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [thePush sendPushInBackgroundWithTarget:self selector:@selector(validateObjectResults:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testStaticChannelPush {
    NSString *channelName = @"channel";
    NSString *message = @"Hello, World!";

    PFPushController *mockedPushController = [Parse _currentManager].pushManager.pushController;

    PFMutablePushState *expectedPushState = [[PFMutablePushState alloc] init];
    [expectedPushState setPayloadWithMessage:message];
    [expectedPushState setChannels:PF_SET(channelName)];

    BFTask *mockedResult = [BFTask taskWithResult:@YES];
    OCMStub([mockedPushController sendPushNotificationAsyncWithState:expectedPushState
                                                        sessionToken:nil]).andReturn(mockedResult);

    XCTestExpectation *toChannelBlockExpectation = [self expectationWithDescription:@"toChannelBlock"];
    XCTestExpectation *toChannelTargetSelectorExpectation = [self expectationWithDescription:@"toChannelTargetSel"];

    [PFPush sendPushMessageToChannel:channelName withMessage:message error:NULL];
    [[[PFPush sendPushMessageToChannelInBackground:channelName
                                       withMessage:message] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        XCTAssertTrue([task.result boolValue]);

        return task;
    }] waitUntilFinished];
    [PFPush sendPushMessageToChannelInBackground:channelName
                                     withMessage:message
                                           block:^(BOOL succeeded, NSError *error) {
                                               XCTAssertTrue(succeeded);
                                               XCTAssertNil(error);

                                               [toChannelBlockExpectation fulfill];
                                           }];

    @weakify(self);
    self.validationBlock = ^(id success) {
        @strongify(self);
        XCTAssertTrue([success boolValue]);
    };

    self.expectationToFulfuill = toChannelTargetSelectorExpectation;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFPush sendPushMessageToChannelInBackground:channelName
                                     withMessage:message
                                          target:self
                                        selector:@selector(validateObjectResults:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testStaticChannelPushData {
    NSString *channelName = @"channel";
    NSDictionary *payload = @{ @"alert" : @"MyMessage",
                               @"customKey" : @"customValue" };

    PFPushController *mockedPushController = [Parse _currentManager].pushManager.pushController;

    PFMutablePushState *expectedPushState = [[PFMutablePushState alloc] init];
    [expectedPushState setChannels:PF_SET(channelName)];
    [expectedPushState setPayload:payload];

    BFTask *mockedResult = [BFTask taskWithResult:@YES];
    OCMStub([mockedPushController sendPushNotificationAsyncWithState:expectedPushState
                                                        sessionToken:nil]).andReturn(mockedResult);

    XCTestExpectation *toChannelBlockExpectation = [self expectationWithDescription:@"toChannelBlock"];
    XCTestExpectation *toChannelTargetSelectorExpectation = [self expectationWithDescription:@"toChannelTargetSel"];

    [PFPush sendPushDataToChannel:channelName withData:payload error:NULL];
    [PFPush sendPushDataToChannelInBackground:channelName withData:payload block:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);

        [toChannelBlockExpectation fulfill];
    }];

    @weakify(self);
    self.validationBlock = ^(id success) {
        @strongify(self);
        XCTAssertTrue([success boolValue]);
    };

    self.expectationToFulfuill = toChannelTargetSelectorExpectation;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFPush sendPushDataToChannelInBackground:channelName
                                     withData:payload
                                       target:self
                                     selector:@selector(validateObjectResults:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testStaticQueryPush {
    PFQuery *query = [PFQuery queryWithClassName:@"SomeClass"];
    NSString *message = @"Hello, World!";

    PFPushController *mockedPushController = [Parse _currentManager].pushManager.pushController;

    PFMutablePushState *expectedPushState = [[PFMutablePushState alloc] init];
    [expectedPushState setPayloadWithMessage:message];
    [expectedPushState setQueryState:[[PFMutableQueryState alloc] initWithParseClassName:@"SomeClass"]];

    BFTask *mockedResult = [BFTask taskWithResult:@YES];
    OCMStub([mockedPushController sendPushNotificationAsyncWithState:expectedPushState
                                                        sessionToken:nil]).andReturn(mockedResult);

    XCTestExpectation *toQueryBlockExpectation = [self expectationWithDescription:@"toQueryBlock"];

    [PFPush sendPushMessageToQuery:query withMessage:message error:NULL];
    [[[PFPush sendPushMessageToQueryInBackground:query
                                     withMessage:message] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        XCTAssertTrue([task.result boolValue]);

        return task;
    }] waitUntilFinished];
    [PFPush sendPushMessageToQueryInBackground:query
                                   withMessage:message
                                         block:^(BOOL succeeded, NSError *error) {
                                             XCTAssertTrue(succeeded);
                                             XCTAssertNil(error);

                                             [toQueryBlockExpectation fulfill];
                                         }];

    [self waitForTestExpectations];
}

- (void)testStaticQueryPushData {
    PFQuery *query = [PFQuery queryWithClassName:@"SomeClass"];
    NSDictionary *payload = @{ @"alert" : @"MyMessage",
                               @"customKey" : @"customValue" };

    PFPushController *mockedPushController = [Parse _currentManager].pushManager.pushController;

    PFMutablePushState *expectedPushState = [[PFMutablePushState alloc] init];
    [expectedPushState setPayload:payload];
    [expectedPushState setQueryState:[[PFMutableQueryState alloc] initWithParseClassName:@"SomeClass"]];

    BFTask *mockedResult = [BFTask taskWithResult:@YES];
    OCMStub([mockedPushController sendPushNotificationAsyncWithState:expectedPushState
                                                        sessionToken:nil]).andReturn(mockedResult);

    XCTestExpectation *toQueryBlockExpectation = [self expectationWithDescription:@"toQueryBlock"];

    [PFPush sendPushDataToQuery:query withData:payload error:NULL];
    [[[PFPush sendPushDataToQueryInBackground:query withData:payload] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        XCTAssertTrue([task.result boolValue]);

        return task;
    }] waitUntilFinished];
    [PFPush sendPushDataToQueryInBackground:query
                                   withData:payload
                                      block:^(BOOL succeeded, NSError *error) {
                                          XCTAssertTrue(succeeded);
                                          XCTAssertNil(error);

                                          [toQueryBlockExpectation fulfill];
                                      }];

    [self waitForTestExpectations];
}

- (void)testGetSubscribedChannels {
    NSString *channel = @"channel";
    NSSet *channelsSet = PF_SET(channel);

    PFPushChannelsController *mockedChannelsController = [Parse _currentManager].pushManager.channelsController;

    BFTask *mockedResult = [BFTask taskWithResult:channelsSet];
    OCMStub([mockedChannelsController getSubscribedChannelsAsync]).andReturn(mockedResult);

    XCTestExpectation *subscribeBlockExpectation = [self expectationWithDescription:@"subscribeBlock"];
    XCTestExpectation *subscribeTargetSelectorExpectation = [self expectationWithDescription:@"subscribeTargetSel"];

    XCTAssertEqualObjects(channelsSet, [PFPush getSubscribedChannels:NULL]);
    [[[PFPush getSubscribedChannelsInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(channelsSet, task.result);

        return task;
    }] waitUntilFinished];
    [PFPush getSubscribedChannelsInBackgroundWithBlock:^(NSSet *channels, NSError *error) {
        XCTAssertEqualObjects(channelsSet, channels);

        [subscribeBlockExpectation fulfill];
    }];

    @weakify(self);
    self.validationBlock = ^(id result) {
        @strongify(self);
        XCTAssertEqualObjects(channelsSet, result);
    };

    self.expectationToFulfuill = subscribeTargetSelectorExpectation;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFPush getSubscribedChannelsInBackgroundWithTarget:self selector:@selector(validateObjectResults:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testSubscribeToChannels {
    NSString *channel = @"channel";

    PFPushChannelsController *mockedChannelsController = [Parse _currentManager].pushManager.channelsController;

    BFTask *mockedResult = [BFTask taskWithResult:@YES];
    OCMStub([mockedChannelsController subscribeToChannelAsyncWithName:channel]).andReturn(mockedResult);

    XCTestExpectation *subscribeBlockExpectation = [self expectationWithDescription:@"subscribeBlock"];
    XCTestExpectation *subscribeTargetSelectorExpectation = [self expectationWithDescription:@"subscribeTargetSel"];

    [PFPush subscribeToChannel:channel error:NULL];
    [[[PFPush subscribeToChannelInBackground:channel] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        XCTAssertTrue([task.result boolValue]);

        return task;
    }] waitUntilFinished];
    [PFPush subscribeToChannelInBackground:channel block:^(BOOL succeeded, NSError *_Nullable error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);

        [subscribeBlockExpectation fulfill];
    }];

    @weakify(self);
    self.validationBlock = ^(id success) {
        @strongify(self);
        XCTAssertTrue([success boolValue]);
    };

    self.expectationToFulfuill = subscribeTargetSelectorExpectation;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFPush subscribeToChannelInBackground:channel
                                    target:self
                                  selector:@selector(validateObjectResults:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testUnsubscribeFromChannels {
    NSString *channel = @"channel";

    PFPushChannelsController *mockedChannelsController = [Parse _currentManager].pushManager.channelsController;

    BFTask *mockedResult = [BFTask taskWithResult:@YES];
    OCMStub([mockedChannelsController unsubscribeFromChannelAsyncWithName:channel]).andReturn(mockedResult);

    XCTestExpectation *unsubscribeBlockExpectation = [self expectationWithDescription:@"unsubscribeBlock"];
    XCTestExpectation *unsubscribeTargetSelectorExpectation = [self expectationWithDescription:@"unsubscribeTargetSel"];

    [PFPush unsubscribeFromChannel:channel error:NULL];
    [[[PFPush unsubscribeFromChannelInBackground:channel] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        XCTAssertTrue([task.result boolValue]);

        return task;
    }] waitUntilFinished];
    [PFPush unsubscribeFromChannelInBackground:channel block:^(BOOL succeeded, NSError *_Nullable error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);

        [unsubscribeBlockExpectation fulfill];
    }];

    @weakify(self);
    self.validationBlock = ^(id success) {
        @strongify(self);
        XCTAssertTrue([success boolValue]);
    };

    self.expectationToFulfuill = unsubscribeTargetSelectorExpectation;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFPush unsubscribeFromChannelInBackground:channel
                                        target:self
                                      selector:@selector(validateObjectResults:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testDeviceToken {
    PFInstallation *installation = [[PFInstallation alloc] init];
    BFTask *installationTask = [BFTask taskWithResult:installation];

    PFCurrentInstallationController *mockedInstallationController = PFStrictClassMock([PFCurrentInstallationController class]);
    OCMStub([mockedInstallationController getCurrentObjectAsync]).andReturn(installationTask);

    [Parse _currentManager].coreManager.currentInstallationController = mockedInstallationController;

    XCTAssertNil(installation.deviceToken);

    [PFPush storeDeviceToken:@"token"];
    XCTAssertEqualObjects(installation.deviceToken, @"token");

    [[PFPush pushInternalUtilClass] clearDeviceToken];
    XCTAssertNil(installation.deviceToken);

    NSData *dataToken = [NSData dataWithBytes:(const char[]) { 0xFF, 0x7F, 0x00 } length:3];
    NSString *expectedString = @"ff7f00";

    [PFPush storeDeviceToken:dataToken];
    XCTAssertEqualObjects(installation.deviceToken, expectedString);

    [[PFPush pushInternalUtilClass] clearDeviceToken];
    XCTAssertNil(installation.deviceToken);
}

- (void)testDeprecatedMethods {
    PFPush *push = [PFPush push];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

    [push setPushToIOS:YES];
    [push setPushToAndroid:YES];

#pragma clang diagnostic pop
}

- (void)testSetQueryAndChannelFails {
    PFQuery *query = [PFInstallation query];
    NSArray *channels = @[ @"foo", @"bar" ];

    PFPush *push = [[PFPush alloc] init];
    [push setQuery:query];
    PFAssertThrowsInvalidArgumentException([push setChannel:@"foo"]);

    push = [[PFPush alloc] init];
    [push setQuery:query];
    PFAssertThrowsInvalidArgumentException([push setChannels:channels]);

    push = [[PFPush alloc] init];
    [push setChannels:channels];
    PFAssertThrowsInvalidArgumentException([push setQuery:query]);

    push = [[PFPush alloc] init];
    [push setChannel:@"foo"];
    PFAssertThrowsInvalidArgumentException([push setQuery:query]);
}

- (void)testPushWithLimitQueryFails {
    PFQuery *query = [PFInstallation query];
    query.limit = 10;

    PFPush *push = [[PFPush alloc] init];
    [push setQuery:query];
    [push setMessage:@"hello this is a test"];
    PFAssertThrowsInvalidArgumentException([push sendPush:nil]);
}

- (void)testPushWithOrderQueryFails {
    PFQuery *query = [PFInstallation query];
    [query orderByAscending:@"deviceToken"];

    PFPush *push = [[PFPush alloc] init];
    [push setQuery:query];
    [push setMessage:@"hello this is a test"];
    PFAssertThrowsInvalidArgumentException([push sendPush:nil]);
}

- (void)testPushWithSkipQueryFails {
    PFQuery *query = [PFInstallation query];
    [query whereKey:@"deviceType" equalTo:@"ios"];
    query.skip = 10;

    PFPush *push = [[PFPush alloc] init];
    [push setQuery:query];
    [push setMessage:@"hello this is a test"];
    PFAssertThrowsInvalidArgumentException([push sendPush:nil]);
}

@end
