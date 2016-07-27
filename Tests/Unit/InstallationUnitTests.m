/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFInstallation.h"
#import "PFUnitTestCase.h"
#import "Parse.h"

@interface InstallationUnitTests : PFUnitTestCase

@end

@implementation InstallationUnitTests

- (void)testInstallationImmutableFieldsCannotBeChanged {
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation.deviceToken = @"11433856eed2f1285fb3aa11136718c1198ed5647875096952c66bf8cb976306";

    PFAssertThrowsInvalidArgumentException(installation[@"deviceType"] = @"android");
    PFAssertThrowsInvalidArgumentException(installation[@"installationId"] = @"a");
    PFAssertThrowsInvalidArgumentException(installation[@"localeIdentifier"] = @"a");
}

- (void)testInstallationImmutableFieldsCannotBeDeleted {
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation.deviceToken = @"11433856eed2f1285fb3aa11136718c1198ed5647875096952c66bf8cb976306";

    PFAssertThrowsInvalidArgumentException([installation removeObjectForKey:@"deviceType"]);
    PFAssertThrowsInvalidArgumentException([installation removeObjectForKey:@"installationId"]);
    PFAssertThrowsInvalidArgumentException([installation removeObjectForKey:@"localeIdentifier"]);
}

@end
