/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

#import "PFEventuallyQueue.h"

@class PFCommandCacheTestHelper;
@class PFObject;

/**
 ParseCommandCache manages an on-disk cache of commands to be executed, and a thread with a standard run loop
 that executes the commands.  There should only ever be one instance of this class, because multiple instances
 would be running separate threads trying to read and execute the same commands.
 */
@interface PFCommandCache : PFEventuallyQueue

@property (nonatomic, copy, readonly) NSString *diskCachePath;
@property (nonatomic, assign, readonly) unsigned long long diskCacheSize;

///--------------------------------------
/// @name Init
///--------------------------------------

/**
 Creates the command cache object for all ParseObjects with default configuration.
 This command cache is used to locally store save commands created by the [PFObject saveEventually].
 When a PFCommandCache is instantiated, it will begin running its run loop,
 which will start by processing any commands already stored in the on-disk queue.
 */
+ (instancetype)newDefaultCommandCacheWithCommandRunner:(id<PFCommandRunning>)commandRunner
                                        cacheFolderPath:(NSString *)cacheFolderPath;

- (instancetype)initWithCommandRunner:(id<PFCommandRunning>)commandRunner
                     maxAttemptsCount:(NSUInteger)attemptsCount
                        retryInterval:(NSTimeInterval)retryInterval NS_UNAVAILABLE;

- (instancetype)initWithCommandRunner:(id<PFCommandRunning>)commandRunner
                     maxAttemptsCount:(NSUInteger)attemptsCount
                        retryInterval:(NSTimeInterval)retryInterval
                        diskCachePath:(NSString *)diskCachePath
                        diskCacheSize:(unsigned long long)diskCacheSize NS_DESIGNATED_INITIALIZER;

@end
