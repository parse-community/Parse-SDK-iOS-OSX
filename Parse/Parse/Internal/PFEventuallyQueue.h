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

#import "PFMacros.h"
#import "PFNetworkCommand.h"

@class BFTask<__covariant BFGenericType>;
@class PFEventuallyPin;
@class PFObject;
@protocol PFCommandRunnerProvider;

extern NSUInteger const PFEventuallyQueueDefaultMaxAttemptsCount;
extern NSTimeInterval const PFEventuallyQueueDefaultTimeoutRetryInterval;

@interface PFEventuallyQueue : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider> dataSource;

@property (nonatomic, assign, readonly) NSUInteger maxAttemptsCount;
@property (nonatomic, assign, readonly) NSTimeInterval retryInterval;

@property (nonatomic, assign, readonly) NSUInteger commandCount;

/**
 Controls whether the queue should monitor network reachability and pause itself when there is no connection.
 Default: `YES`.
 */
@property (atomic, assign, readonly) BOOL monitorsReachability PF_WATCH_UNAVAILABLE;
@property (nonatomic, assign, readonly, getter=isConnected) BOOL connected;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource
                  maxAttemptsCount:(NSUInteger)attemptsCount
                     retryInterval:(NSTimeInterval)retryInterval NS_DESIGNATED_INITIALIZER;

///--------------------------------------
#pragma mark - Running Commands
///--------------------------------------

- (BFTask *)enqueueCommandInBackground:(id<PFNetworkCommand>)command;
- (BFTask *)enqueueCommandInBackground:(id<PFNetworkCommand>)command withObject:(PFObject *)object;

///--------------------------------------
#pragma mark - Controlling Queue
///--------------------------------------

- (void)start NS_REQUIRES_SUPER;
- (void)resume NS_REQUIRES_SUPER;
- (void)pause NS_REQUIRES_SUPER;
- (void)terminate NS_REQUIRES_SUPER;
- (void)removeAllCommands NS_REQUIRES_SUPER;

@end
