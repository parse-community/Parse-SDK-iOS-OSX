/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFInstallation.h"
#import "PFTestCase.h"
#import "Parse.h"

@interface InstallationUnitTests : PFTestCase

@end

@implementation InstallationUnitTests

+ (void)setUp {
    [super setUp];

    [Parse setApplicationId:@"a" clientKey:@"a"];
}

- (void)testInstallationImmutableFieldsCannotBeChanged {
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation.deviceToken = @"11433856eed2f1285fb3aa11136718c1198ed5647875096952c66bf8cb976306";

    PFAssertThrowsInvalidArgumentException(installation[@"deviceType"] = @"android",
                                           @"Should throw an exception for trying to change deviceType.");
    PFAssertThrowsInvalidArgumentException(installation[@"installationId"] = @"a"
                                           @"Should throw an exception for trying to change installationId.");
    PFAssertThrowsInvalidArgumentException(installation[@"localeIdentifier"] = @"a"
                                           @"Should throw an exception for trying to change installationId.");
}

- (void)testInstallationImmutableFieldsCannotBeDeleted {
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation.deviceToken = @"11433856eed2f1285fb3aa11136718c1198ed5647875096952c66bf8cb976306";

    PFAssertThrowsInvalidArgumentException([installation removeObjectForKey:@"deviceType"],
                                           @"Should throw an exception for trying to delete deviceType.");
    PFAssertThrowsInvalidArgumentException([installation removeObjectForKey:@"installationId"],
                                           @"Should throw an exception for trying to delete installationId.");
    PFAssertThrowsInvalidArgumentException([installation removeObjectForKey:@"localeIdentifier"],
                                           @"Should throw an exception for trying to delete installationId.");
}

@end
