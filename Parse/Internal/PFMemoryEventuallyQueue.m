/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMemoryEventuallyQueue.h"
#import "PFEventuallyQueue_Private.h"

#import <Bolts/BFTask.h>
#import <Bolts/BFExecutor.h>

@interface PFMemoryEventuallyQueue () <PFEventuallyQueueSubclass> {
    dispatch_queue_t _dataAccessQueue;
    BFExecutor *_dataAccessExecutor;

    NSMutableArray<NSString *> *_pendingCommandIdentifiers;
    NSMutableDictionary<NSString *, id<PFNetworkCommand>> *_commandsDictionary;
}

@end

@implementation PFMemoryEventuallyQueue

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)newDefaultMemoryEventuallyQueueWithDataSource:(id<PFCommandRunnerProvider>)dataSource {
    PFMemoryEventuallyQueue *queue = [[self alloc] initWithDataSource:dataSource
                                                     maxAttemptsCount:PFEventuallyQueueDefaultMaxAttemptsCount
                                                        retryInterval:PFEventuallyQueueDefaultTimeoutRetryInterval];
    [queue start];
    return queue;
}

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource
                  maxAttemptsCount:(NSUInteger)attemptsCount
                     retryInterval:(NSTimeInterval)retryInterval {
    self = [super initWithDataSource:dataSource maxAttemptsCount:attemptsCount retryInterval:retryInterval];
    if (!self) return nil;

    _dataAccessQueue = dispatch_queue_create("com.parse.eventuallyQueue.memory", DISPATCH_QUEUE_SERIAL);
    _dataAccessExecutor = [BFExecutor executorWithDispatchQueue:_dataAccessQueue];

    _pendingCommandIdentifiers = [NSMutableArray array];
    _commandsDictionary = [NSMutableDictionary dictionary];

    return self;
}

///--------------------------------------
#pragma mark - Controlling Queue
///--------------------------------------

- (void)removeAllCommands {
    [super removeAllCommands];

    dispatch_sync(_dataAccessQueue, ^{
        [_pendingCommandIdentifiers removeAllObjects];
        [_commandsDictionary removeAllObjects];
    });
}

///--------------------------------------
#pragma mark - PFEventuallyQueueSubclass
///--------------------------------------

- (NSString *)_newIdentifierForCommand:(id<PFNetworkCommand>)command {
    return [NSUUID UUID].UUIDString;
}

- (NSArray<NSString *> *)_pendingCommandIdentifiers {
    __block NSArray *array = nil;
    dispatch_sync(_dataAccessQueue, ^{
        array = [_pendingCommandIdentifiers copy];
    });
    return array;
}

- (id<PFNetworkCommand>)_commandWithIdentifier:(NSString *)identifier error:(NSError **)error {
    __block id<PFNetworkCommand> command = nil;
    dispatch_sync(_dataAccessQueue, ^{
        command = _commandsDictionary[identifier];
    });
    return command;
}

- (BFTask *)_enqueueCommandInBackground:(id<PFNetworkCommand>)command object:(PFObject *)object identifier:(NSString *)identifier {
    return [BFTask taskFromExecutor:_dataAccessExecutor withBlock:^id{
        [_pendingCommandIdentifiers addObject:identifier];
        _commandsDictionary[identifier] = command;
        return nil;
    }];
}

- (BFTask *)_didFinishRunningCommand:(id<PFNetworkCommand>)command withIdentifier:(NSString *)identifier resultTask:(BFTask *)resultTask {
    return [BFTask taskFromExecutor:_dataAccessExecutor withBlock:^id{
        [_pendingCommandIdentifiers removeObject:identifier];
        [_commandsDictionary removeObjectForKey:identifier];
        return [super _didFinishRunningCommand:command withIdentifier:identifier resultTask:resultTask];
    }];
}

- (BFTask *)_waitForOperationSet:(PFOperationSet *)operationSet eventuallyPin:(PFEventuallyPin *)eventuallyPin {
    return [BFTask taskWithResult:nil];
}

@end
