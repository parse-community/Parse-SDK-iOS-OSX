/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class PFFileManager;

@interface PFInstallationIdentifierStore : NSObject

/*!
 Returns a cached installationId or creates a new one, saves it to disk and returns it.

 @returns `NSString` representation of current installationId.
 */
@property (nonatomic, copy, readonly) NSString *installationIdentifier;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFileManager:(PFFileManager *)fileManager NS_DESIGNATED_INITIALIZER;

///--------------------------------------
/// @name Clear
///--------------------------------------

/*!
 Clears installation identifier on disk and in-memory.
 */
- (void)clearInstallationIdentifier;

@end
