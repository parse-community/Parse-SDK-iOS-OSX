/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFPush.h"
#import "PFPushUtilities.h"
#import "PFUnitTestCase.h"

@interface PushMobileTests : PFUnitTestCase

@end

@implementation PushMobileTests

- (void)testHandlePushStringAlert {
    id mockedUtils = PFStrictProtocolMock(@protocol(PFPushInternalUtils));
    OCMExpect([mockedUtils showAlertViewWithTitle:[OCMArg isNil] message:@"hello"]);

    // NOTE: Async parse preload step may call this selector.
    // Don't epxect it because it doesn't ALWAYs get to this point before returning from the method.
    OCMStub([mockedUtils getDeviceTokenFromKeychain]).andReturn(nil);

    [PFPush setPushInternalUtilClass:mockedUtils];
    [PFPush handlePush:@{ @"aps" : @{@"alert" : @"hello"} }];

    OCMVerifyAll(mockedUtils);

    [PFPush setPushInternalUtilClass:nil];
}

- (void)testHandlePushDictionaryAlert {
    id mockedUtils = PFStrictProtocolMock(@protocol(PFPushInternalUtils));
    OCMExpect([mockedUtils showAlertViewWithTitle:[OCMArg isNil] message:@"hello bob 1"]);

    // NOTE: Async parse preload step may call this selector.
    // Don't epxect it because it doesn't ALWAYs get to this point before returning from the method.
    OCMStub([mockedUtils getDeviceTokenFromKeychain]).andReturn(nil);

    [PFPush setPushInternalUtilClass:mockedUtils];

    [PFPush handlePush:@{ @"aps" : @{@"alert" : @{@"loc-key" : @"hello %@ %@", @"loc-args" : @[ @"bob", @"1" ]}} }];

    [PFPush setPushInternalUtilClass:nil];

    OCMVerifyAll(mockedUtils);
}

- (void)testHandlePushWithNullSound {
    id mockedUtils = PFStrictProtocolMock(@protocol(PFPushInternalUtils));
    OCMExpect([mockedUtils showAlertViewWithTitle:[OCMArg isNil] message:@"hello"]);

    // NOTE: Async parse preload step may call this selector.
    // Don't epxect it because it doesn't ALWAYs get to this point before returning from the method.
    OCMStub([mockedUtils getDeviceTokenFromKeychain]).andReturn(nil);

    [PFPush setPushInternalUtilClass:mockedUtils];
    [PFPush handlePush:@{ @"aps" : @{@"alert" : @"hello", @"sound": [NSNull null]} }];

    OCMVerifyAll(mockedUtils);

    [PFPush setPushInternalUtilClass:nil];
}

- (void)testHandlePushWithDefaultSound {
    id mockedUtils = PFStrictProtocolMock(@protocol(PFPushInternalUtils));
    OCMExpect([mockedUtils showAlertViewWithTitle:[OCMArg isNil] message:@"hello"]);
    OCMExpect([mockedUtils playVibrate]);

    // NOTE: Async parse preload step may call this selector.
    // Don't epxect it because it doesn't ALWAYs get to this point before returning from the method.
    OCMStub([mockedUtils getDeviceTokenFromKeychain]).andReturn(nil);

    [PFPush setPushInternalUtilClass:mockedUtils];
    [PFPush handlePush:@{ @"aps" : @{@"alert" : @"hello", @"sound": @"default"} }];

    OCMVerifyAll(mockedUtils);

    [PFPush setPushInternalUtilClass:nil];
}

- (void)testHandlePushWithCustomSound {
    id mockedUtils = PFStrictProtocolMock(@protocol(PFPushInternalUtils));
    OCMExpect([mockedUtils playAudioWithName:@"yolo"]);

    // NOTE: Async parse preload step may call this selector.
    // Don't epxect it because it doesn't ALWAYs get to this point before returning from the method.
    OCMStub([mockedUtils getDeviceTokenFromKeychain]).andReturn(nil);

    [PFPush setPushInternalUtilClass:mockedUtils];
    [PFPush handlePush:@{ @"aps" : @{@"sound": @"yolo"} }];

    OCMVerifyAll(mockedUtils);

    [PFPush setPushInternalUtilClass:nil];
}

@end
