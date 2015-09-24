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

@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFEventuallyPin;
@class PFEventuallyQueueTestHelper;
@class PFObject;
@protocol PFCommandRunning;

extern NSUInteger const PFEventuallyQueueDefaultMaxAttemptsCount;
extern NSTimeInterval const PFEventuallyQueueDefaultTimeoutRetryInterval;

@interface PFEventuallyQueue : NSObject

@property (nonatomic, strong, readonly) id<PFCommandRunning> commandRunner;

@property (nonatomic, assign, readonly) NSUInteger maxAttemptsCount;
@property (nonatomic, assign, readonly) NSTimeInterval retryInterval;

@property (nonatomic, assign, readonly) NSUInteger commandCount;

/*!
 Controls whether the queue should monitor network reachability and pause itself when there is no connection.
 Default: `YES`.
 */
@property (atomic, assign, readonly) BOOL monitorsReachability PF_WATCH_UNAVAILABLE;
@property (nonatomic, assign, readonly, getter=isConnected) BOOL connected;

// Gets notifications of various events happening in the command cache, so that tests can be synchronized.
@property (nonatomic, strong, readonly) PFEventuallyQueueTestHelper *testHelper;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCommandRunner:(id<PFCommandRunning>)commandRunner
                     maxAttemptsCount:(NSUInteger)attemptsCount
                        retryInterval:(NSTimeInterval)retryInterval NS_DESIGNATED_INITIALIZER;

///--------------------------------------
/// @name Running Commands
///--------------------------------------

- (BFTask *)enqueueCommandInBackground:(id<PFNetworkCommand>)command;
- (BFTask *)enqueueCommandInBackground:(id<PFNetworkCommand>)command withObject:(PFObject *)object;

///--------------------------------------
/// @name Controlling Queue
///--------------------------------------

- (void)start NS_REQUIRES_SUPER;
- (void)resume NS_REQUIRES_SUPER;
- (void)pause NS_REQUIRES_SUPER;

- (void)removeAllCommands NS_REQUIRES_SUPER;

@end

typedef enum {
    PFEventuallyQueueEventCommandEnqueued, // A command was placed into the queue.
    PFEventuallyQueueEventCommandNotEnqueued, // A command could not be placed into the queue.

    PFEventuallyQueueEventCommandSucceded, // A command has successfully running on the server.
    PFEventuallyQueueEventCommandFailed, // A command has failed on the server.

    PFEventuallyQueueEventObjectUpdated, // An object's data was updated after a command completed.
    PFEventuallyQueueEventObjectRemoved, // An object was removed because it was deleted before creation.

    PFEventuallyQueueEventCount // The total number of items in this enum.
} PFEventuallyQueueTestHelperEvent;

@interface PFEventuallyQueueTestHelper : NSObject {
    dispatch_semaphore_t events[PFEventuallyQueueEventCount];
}

- (void)clear;
- (void)notify:(PFEventuallyQueueTestHelperEvent)event;
- (BOOL)waitFor:(PFEventuallyQueueTestHelperEvent)event;

@end
