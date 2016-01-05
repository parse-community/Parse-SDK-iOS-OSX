/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFConstants.h>
#import <Parse/PFFile.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This category lists all methods of `PFFile` class that are synchronous, but have asynchronous counterpart,
 Calling one of these synchronous methods could potentially block the current thread for a large amount of time,
 since it might be fetching from network or saving/loading data from disk.
 */
@interface PFFile (Synchronous)

///--------------------------------------
#pragma mark - Storing Data with Parse
///--------------------------------------

/**
 Saves the file *synchronously*.

 @return Returns whether the save succeeded.
 */
- (BOOL)save PF_SWIFT_UNAVAILABLE;

/**
 Saves the file *synchronously* and sets an error if it occurs.

 @param error Pointer to an `NSError` that will be set if necessary.

 @return Returns whether the save succeeded.
 */
- (BOOL)save:(NSError **)error;

///--------------------------------------
#pragma mark - Getting Data from Parse
///--------------------------------------

/**
 Whether the data is available in memory or needs to be downloaded.
 */
@property (nonatomic, assign, readonly, getter=isDataAvailable) BOOL dataAvailable;

/**
 *Synchronously* gets the data from cache if available or fetches its contents from the network.

 @return The `NSData` object containing file data. Returns `nil` if there was an error in fetching.
 */
- (nullable NSData *)getData PF_SWIFT_UNAVAILABLE;

/**
 *Synchronously* gets the data from cache if available or fetches its contents from the network.
 Sets an error if it occurs.

 @param error Pointer to an `NSError` that will be set if necessary.

 @return The `NSData` object containing file data. Returns `nil` if there was an error in fetching.
 */
- (nullable NSData *)getData:(NSError **)error;

/**
 This method is like `-getData` but avoids ever holding the entire `PFFile` contents in memory at once.

 This can help applications with many large files avoid memory warnings.

 @return A stream containing the data. Returns `nil` if there was an error in fetching.
 */
- (nullable NSInputStream *)getDataStream PF_SWIFT_UNAVAILABLE;

/**
 This method is like `-getData` but avoids ever holding the entire `PFFile` contents in memory at once.

 @param error Pointer to an `NSError` that will be set if necessary.

 @return A stream containing the data. Returns nil if there was an error in
 fetching.
 */
- (nullable NSInputStream *)getDataStream:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
