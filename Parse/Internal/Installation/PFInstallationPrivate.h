/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFInstallation.h>

@interface PFInstallation (Private)

- (void)_clearDeviceToken;
- (void)_markAllFieldsDirty;

@end

@interface PFInstallation ()

// Private read-write declarations of publicly-readonly fields.
@property (nonatomic, copy, readwrite) NSString *deviceType;
@property (nonatomic, copy, readwrite) NSString *installationId;
@property (nonatomic, copy, readwrite) NSString *timeZone;

@end
