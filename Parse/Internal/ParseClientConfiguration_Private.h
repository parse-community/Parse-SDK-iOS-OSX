/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ParseClientConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const _ParseDefaultServerURLString;

@interface ParseClientConfiguration ()

@property (nullable, nonatomic, copy, readwrite) NSString *applicationId;
@property (nullable, nonatomic, copy, readwrite) NSString *clientKey;

@property (nonatomic, copy, readwrite) NSString *server;

@property (nonatomic, assign, readwrite, getter=isLocalDatastoreEnabled) BOOL localDatastoreEnabled;

@property (nullable, nonatomic, copy, readwrite) NSString *applicationGroupIdentifier;
@property (nullable, nonatomic, copy, readwrite) NSString *containingApplicationBundleIdentifier;

@property (nonatomic, assign, readwrite) NSUInteger networkRetryAttempts;

+ (instancetype)emptyConfiguration;
- (instancetype)initEmpty NS_DESIGNATED_INITIALIZER;

- (void)_resetDataSharingIdentifiers;

@end

// We must implement the protocol here otherwise clang issues warnings about non-matching property declarations.
// For some reason if the property declarations are on a separate category, it doesn't care.
@interface ParseClientConfiguration (Private) <ParseMutableClientConfiguration>
@end

NS_ASSUME_NONNULL_END
