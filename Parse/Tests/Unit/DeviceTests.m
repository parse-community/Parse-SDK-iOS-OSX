/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDevice.h"
#import "PFTestCase.h"

@interface DeviceTests : PFTestCase

@end

@implementation DeviceTests

- (void)testCurrentDevice {
    PFDevice *device = [PFDevice currentDevice];
    XCTAssertNotNil(device);
    XCTAssertEqual(device, [PFDevice currentDevice]);
}

- (void)testDetailedModel {
    PFDevice *device = [PFDevice currentDevice];
    XCTAssertNotNil(device.detailedModel);
    XCTAssertNotEqual(device.detailedModel.length, 0);
}

- (void)testOperationSystemFullVersion {
    PFDevice *device = [PFDevice currentDevice];
    XCTAssertNotNil(device.operatingSystemFullVersion);
    XCTAssertNotEqual(device.operatingSystemFullVersion.length, 0);

    XCTAssertNotEqualObjects(device.operatingSystemFullVersion, device.operatingSystemVersion);
    XCTAssertNotEqualObjects(device.operatingSystemFullVersion, device.operatingSystemBuild);
}

- (void)testOperatingSystemVersion {
    PFDevice *device = [PFDevice currentDevice];
    XCTAssertNotNil(device.operatingSystemVersion);
    XCTAssertNotEqual(device.operatingSystemVersion.length, 0);
}

- (void)testOperationSystemBuild {
    PFDevice *device = [PFDevice currentDevice];
    XCTAssertNotNil(device.operatingSystemBuild);
    XCTAssertNotEqual(device.operatingSystemBuild.length, 0);
}

- (void)testJailbroken {
    PFDevice *device = [PFDevice currentDevice];
    XCTAssertNoThrow(device.jailbroken); // No chance we can test this.
}

@end
