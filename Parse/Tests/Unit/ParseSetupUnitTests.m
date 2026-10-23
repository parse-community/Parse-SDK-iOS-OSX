/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <SystemConfiguration/SystemConfiguration.h>

#import "BFTask+Private.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFCommandURLRequestConstructor.h"
#import "PFEventuallyQueue_Private.h"
#import "PFHTTPRequest.h"
#import "PFObjectPrivate.h"
#import "PFReachability.h"
#import "PFRESTCommand.h"
#import "PFTaskQueue.h"
#import "PFTestCase.h"
#import "PFURLSessionCommandRunner_Private.h"
#import "ParseManagerPrivate.h"
#import "Parse_Private.h"

static dispatch_time_t PFTimeFromNow(NSTimeInterval seconds) {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC));
}

@interface PFReachability (ParseSetupUnitTests)

- (void)setFlags:(SCNetworkReachabilityFlags)flags;

@end

@interface ParseSetupUnitTestsReachabilityListener : NSObject <PFReachabilityListener>

@property (nonatomic, strong, readonly) dispatch_semaphore_t notified;

- (instancetype)initWithState:(PFReachabilityState)state;

@end

@implementation ParseSetupUnitTestsReachabilityListener {
    PFReachabilityState _state;
}

- (instancetype)initWithState:(PFReachabilityState)state {
    self = [super init];
    if (!self) return nil;

    _state = state;
    _notified = dispatch_semaphore_create(0);

    return self;
}

- (void)reachability:(PFReachability *)reachability didChangeReachabilityState:(PFReachabilityState)state {
    if (state == _state) {
        dispatch_semaphore_signal(_notified);
    }
}

@end

@interface ParseSetupUnitTests : PFTestCase

@end

@implementation ParseSetupUnitTests {
    BOOL _notReachable;
}

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)tearDown {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];
    if (_notReachable) {
        // Restore connectivity once the pending commands are removed, so that eventually queues of other managers don't run them
        [self simulateReachable:YES];
    }

    [super tearDown];
}

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (void)initializeParse {
    [self warmUpApplication];
    XCTestExpectation *expectation = [self expectationForNotification:PFParseInitializeDidCompleteNotification
                                                                object:nil
                                                               handler:nil];
    [Parse setApplicationId:@"a" clientKey:@"b"];
    [self waitForExpectations:@[ expectation ] timeout:30];
}

- (void)mockCommandRunnerFailingWithTemporaryErrorAndDo:(void (^)(void))block {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorNotConnectedToInternet
                                     userInfo:@{ @"temporary" : @YES }];
    id commandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    OCMStub([commandRunner runCommandAsync:[OCMArg any] withOptions:0])
    .andReturn([BFTask taskWithError:error])
    .andDo(^(NSInvocation *invocation) {
        block();
    });
    [Parse _currentManager].commandRunner = commandRunner;
}

- (void)enqueueCommandInQueue:(PFEventuallyQueue *)queue {
    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"classes/Yolo"
                                                     httpMethod:PFHTTPRequestMethodPOST
                                                     parameters:@{}
                                                   sessionToken:nil
                                                          error:nil];
    [queue enqueueCommandInBackground:command];
}

- (dispatch_group_t)clearEventuallyQueueInBackground {
    ParseManager *manager = [Parse _currentManager];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [manager clearEventuallyQueue];
    });
    return group;
}

- (id)mockCommandRunnerRecordingCommands:(NSMutableArray<PFRESTCommand *> *)commands andDo:(void (^)(void))block {
    PFCommandResult *result = [PFCommandResult commandResultWithResult:@{ @"objectId" : @"yolo" }
                                                          resultString:nil
                                                          httpResponse:nil];
    // Not strict, as setting the server sets the server URL of the command runner
    id commandRunner = PFProtocolMock(@protocol(PFCommandRunning));
    OCMStub([commandRunner runCommandAsync:[OCMArg any] withOptions:0])
    .andReturn([BFTask taskWithResult:result])
    .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained PFRESTCommand *command = nil;
        [invocation getArgument:&command atIndex:2];
        @synchronized (commands) {
            [commands addObject:command];
        }
        if (block) {
            block();
        }
    });
    return commandRunner;
}

- (void)simulateReachable:(BOOL)reachable {
    // Listeners are notified one after another in the order they were added, so all eventually queues
    // have handled the change once this listener is notified
    PFReachabilityState state = (reachable ? PFReachabilityStateReachableViaWiFi : PFReachabilityStateNotReachable);
    ParseSetupUnitTestsReachabilityListener *listener = [[ParseSetupUnitTestsReachabilityListener alloc] initWithState:state];
    PFReachability *reachability = [PFReachability sharedParseReachability];
    [reachability addListener:listener];
    [reachability setFlags:(reachable ? kSCNetworkReachabilityFlagsReachable : 0)];
    XCTAssertEqual(dispatch_semaphore_wait(listener.notified, PFTimeFromNow(10)), 0L);
    [reachability removeListener:listener];
    _notReachable = !reachable;
}

- (void)waitForReachability {
    // The reachability notifies listeners in a block that it dispatches while it changes the host
    dispatch_queue_t queue = [[PFReachability sharedParseReachability] valueForKey:@"_synchronizationQueue"];
    dispatch_barrier_sync(queue, ^{});
    dispatch_barrier_sync(queue, ^{});
}

- (void)monitorReachabilityOfServer:(NSString *)server {
    [[PFReachability sharedParseReachability] monitorHostOfURL:[NSURL URLWithString:server]];
    [self waitForReachability];
}

- (BOOL)waitForCondition:(BOOL (^)(void))condition {
    NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:10];
    while (!condition()) {
        if (timeout.timeIntervalSinceNow <= 0) {
            return NO;
        }
        [NSThread sleepForTimeInterval:0.01];
    }
    return YES;
}

- (void)waitForCommandsEnqueuedInQueue:(PFEventuallyQueue *)queue {
    // The queue enqueues commands one after another, each until it keeps track of the command
    PFTaskQueue *enqueueTaskQueue = [queue valueForKey:@"_commandEnqueueTaskQueue"];
    [[enqueueTaskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return toAwait;
    }] waitUntilFinished];
}

- (BFTask *)saveEventuallyObject:(PFObject *)object inQueue:(PFEventuallyQueue *)queue {
    BFTask *enqueueTask = [object _enqueueSaveEventuallyWithChildren:YES];
    [enqueueTask waitUntilFinished];

    // The queue enqueues the command, and the object hands over the changes to save, in the background
    [self waitForCommandsEnqueuedInQueue:queue];
    [[object.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return toAwait;
    }] waitUntilFinished];

    XCTAssertEqual(queue.commandCount, 1);
    return enqueueTask.result;
}

- (void)assertSetServerSendsCommandOnceEnqueuedBeforeSetServer:(BOOL)enqueuedBeforeSetServer {
    [self initializeParse];
    // Monitor a loopback address, whose reachability doesn't change, so that setting the server to the same host keeps queues offline
    [self monitorReachabilityOfServer:@"https://127.0.0.1/parse"];
    // Keep the eventually queues of other managers offline, as they would also run the pending command
    [self simulateReachable:NO];
    ParseManager *manager = [Parse _currentManager];
    PFEventuallyQueue *queue = manager.eventuallyQueue;
    NSMutableArray<PFRESTCommand *> *previousCommands = [NSMutableArray array];
    manager.commandRunner = [self mockCommandRunnerRecordingCommands:previousCommands andDo:nil];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    object[@"yarr"] = @"yolo";
    BFTask *saveTask = nil;
    if (enqueuedBeforeSetServer) {
        saveTask = [self saveEventuallyObject:object inQueue:queue];
    }

    [Parse setServer:@"https://127.0.0.1/other"];
    PFEventuallyQueue *currentQueue = [Parse _currentManager].eventuallyQueue;
    NSMutableArray<PFRESTCommand *> *commands = [NSMutableArray array];
    XCTestExpectation *commandSent = [self expectationWithDescription:@"Command sent"];
    commandSent.assertForOverFulfill = NO;
    [Parse _currentManager].commandRunner = [self mockCommandRunnerRecordingCommands:commands andDo:^{
        // Keep the command pending until a run of another eventually queue finished, so that it can't miss the command
        if (currentQueue != queue) {
            [queue waitForRunningCommands];
        }
        [commandSent fulfill];
    }];
    if (!enqueuedBeforeSetServer) {
        saveTask = [self saveEventuallyObject:object inQueue:currentQueue];
    }

    // Connectivity returns while the command is pending
    queue.connected = YES;
    currentQueue.connected = YES;

    [self waitForExpectations:@[ commandSent ] timeout:10];
    [queue waitForRunningCommands];
    [currentQueue waitForRunningCommands];
    XCTAssertTrue([self waitForCondition:^BOOL{
        return saveTask.completed;
    }]);

    // Only the eventually queue of the current manager sent the command, with its changes
    XCTAssertEqual([Parse _currentManager], manager);
    XCTAssertEqual(currentQueue, queue);
    XCTAssertEqual(previousCommands.count, 0);
    XCTAssertEqual(commands.count, 1);
    XCTAssertEqualObjects(commands.firstObject.httpPath, @"classes/Yolo");
    XCTAssertEqualObjects(commands.firstObject.parameters[@"yarr"], @"yolo");
    XCTAssertEqual(currentQueue.commandCount, 0);
    XCTAssertNil(saveTask.error);
    XCTAssertEqualObjects(object.objectId, @"yolo");
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testClearEventuallyQueueWaitsForRunningCommands {
    [Parse enableLocalDatastore];
    [self initializeParse];

    PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
    [queue pause];
    queue.connected = YES;

    // Block the next run of commands until it is released
    dispatch_semaphore_t runStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t runReleased = dispatch_semaphore_create(0);
    id queueMock = PFPartialMock(queue);
    OCMStub([queueMock _pendingCommandIdentifiers]).andReturn(@[]).andDo(^(NSInvocation *invocation) {
        dispatch_semaphore_signal(runStarted);
        dispatch_semaphore_wait(runReleased, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(runReleased);
    });
    [queue resume];
    XCTAssertEqual(dispatch_semaphore_wait(runStarted, PFTimeFromNow(10)), 0L);

    // Running commands may still access the local datastore, so clearing must wait for them
    dispatch_group_t clearing = [self clearEventuallyQueueInBackground];
    XCTAssertNotEqual(dispatch_group_wait(clearing, PFTimeFromNow(0.5)), 0L);

    dispatch_semaphore_signal(runReleased);
    XCTAssertEqual(dispatch_group_wait(clearing, PFTimeFromNow(10)), 0L);
}

- (void)testClearEventuallyQueueDoesNotRetryRunningCommand {
    [self initializeParse];

    PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
    [queue pause];
    queue.connected = YES;

    // Block the command until it is released, then fail it with an error that is retried
    dispatch_semaphore_t commandStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t commandReleased = dispatch_semaphore_create(0);
    [self mockCommandRunnerFailingWithTemporaryErrorAndDo:^{
        dispatch_semaphore_signal(commandStarted);
        dispatch_semaphore_wait(commandReleased, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(commandReleased);
    }];
    [queue resume];
    [self enqueueCommandInQueue:queue];
    XCTAssertEqual(dispatch_semaphore_wait(commandStarted, PFTimeFromNow(10)), 0L);

    dispatch_group_t clearing = [self clearEventuallyQueueInBackground];
    XCTAssertNotEqual(dispatch_group_wait(clearing, PFTimeFromNow(0.5)), 0L);

    // The command fails after clearing paused the queue, so the queue must not wait to retry it
    dispatch_semaphore_signal(commandReleased);
    XCTAssertEqual(dispatch_group_wait(clearing, PFTimeFromNow(10)), 0L);
}

- (void)testClearEventuallyQueueStopsWaitingToRetryCommand {
    [self initializeParse];

    PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
    [queue pause];
    queue.connected = YES;
    [self mockCommandRunnerFailingWithTemporaryErrorAndDo:^{}];

    // The run of commands reads the retry interval once it waits to retry a command
    dispatch_semaphore_t waitingToRetry = dispatch_semaphore_create(0);
    id queueMock = PFPartialMock(queue);
    OCMStub([queueMock retryInterval]).andDo(^(NSInvocation *invocation) {
        dispatch_semaphore_signal(waitingToRetry);
    }).andForwardToRealObject();
    [queue resume];
    [self enqueueCommandInQueue:queue];
    XCTAssertEqual(dispatch_semaphore_wait(waitingToRetry, PFTimeFromNow(10)), 0L);

    dispatch_group_t clearing = [self clearEventuallyQueueInBackground];
    XCTAssertEqual(dispatch_group_wait(clearing, PFTimeFromNow(10)), 0L);
}

- (void)testSetServerChangesServerOfCurrentManager {
    [self initializeParse];
    ParseManager *manager = [Parse _currentManager];
    PFEventuallyQueue *queue = manager.eventuallyQueue;
    PFURLSessionCommandRunner *commandRunner = (PFURLSessionCommandRunner *)manager.commandRunner;

    [Parse setServer:@"https://example.com/parse"];
    [Parse setServer:@"https://example.org/parse"];

    // Parse isn't re-initialized, so that only one eventually queue runs the pending commands
    XCTAssertEqual([Parse _currentManager], manager);
    XCTAssertEqual([Parse _currentManager].eventuallyQueue, queue);
    XCTAssertEqual((id)[Parse _currentManager].commandRunner, (id)commandRunner);
    XCTAssertEqualObjects([Parse server], @"https://example.org/parse");
    XCTAssertEqualObjects([Parse currentConfiguration].server, @"https://example.org/parse");
    XCTAssertEqualObjects(commandRunner.serverURL, [NSURL URLWithString:@"https://example.org/parse"]);

    // Requests that the command runner creates from now on go to the new server
    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"classes/Yolo"
                                                     httpMethod:PFHTTPRequestMethodPOST
                                                     parameters:@{}
                                                   sessionToken:nil
                                                          error:nil];
    NSURLRequest *request = [[commandRunner.requestConstructor getDataURLRequestAsyncForCommand:command] waitForResult:nil];
    XCTAssertEqualObjects(request.URL.absoluteString, @"https://example.org/parse/classes/Yolo");

    // An invalid server URL doesn't change the server
    PFAssertThrowsInvalidArgumentException([Parse setServer:@"yolo"]);
    XCTAssertEqualObjects([Parse server], @"https://example.org/parse");
    XCTAssertEqualObjects(commandRunner.serverURL, [NSURL URLWithString:@"https://example.org/parse"]);
}

- (void)testSetServerMonitorsReachabilityOfNewHost {
    [self initializeParse];
    // Start from a loopback address, whose reachability doesn't change, as previous tests may have set another host
    [self monitorReachabilityOfServer:@"https://127.0.0.1/parse"];
    PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
    queue.connected = NO;

    // Setting a server on the same host keeps monitoring the host
    [Parse setServer:@"https://127.0.0.1/other"];
    [self waitForReachability];
    XCTAssertFalse(queue.connected);

    // Setting a server on another host monitors the new host, which is reachable without network
    ParseSetupUnitTestsReachabilityListener *listener = [[ParseSetupUnitTestsReachabilityListener alloc] initWithState:PFReachabilityStateReachableViaWiFi];
    [[PFReachability sharedParseReachability] addListener:listener];
    [Parse setServer:@"https://127.0.0.2/parse"];
    XCTAssertEqual(dispatch_semaphore_wait(listener.notified, PFTimeFromNow(10)), 0L);
    [[PFReachability sharedParseReachability] removeListener:listener];
    XCTAssertTrue(queue.connected);
}

- (void)testSetServerSendsPendingCommandOnce {
    [self assertSetServerSendsCommandOnceEnqueuedBeforeSetServer:NO];
}

- (void)testSetServerSendsPendingCommandOnceWithLocalDatastore {
    [Parse enableLocalDatastore];
    [self assertSetServerSendsCommandOnceEnqueuedBeforeSetServer:NO];
}

- (void)testSetServerSendsCommandEnqueuedBeforeSetServerOnce {
    [self assertSetServerSendsCommandOnceEnqueuedBeforeSetServer:YES];
}

- (void)testSetServerSendsCommandEnqueuedBeforeSetServerOnceWithLocalDatastore {
    [Parse enableLocalDatastore];
    [self assertSetServerSendsCommandOnceEnqueuedBeforeSetServer:YES];
}

- (void)testSetServerRetriesCommandWaitingToBeRetried {
    [self initializeParse];
    // Monitor a loopback address, whose reachability doesn't change, so that setting the server to the same host keeps queues offline
    [self monitorReachabilityOfServer:@"https://127.0.0.1/parse"];
    // Keep the eventually queues of other managers offline, so that only this queue runs commands
    [self simulateReachable:NO];
    PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
    [queue pause];
    queue.connected = YES;
    [self mockCommandRunnerFailingWithTemporaryErrorAndDo:^{}];

    // The run of commands reads the retry interval once it waits to retry a command
    dispatch_semaphore_t waitingToRetry = dispatch_semaphore_create(0);
    id queueMock = PFPartialMock(queue);
    OCMStub([queueMock retryInterval]).andDo(^(NSInvocation *invocation) {
        dispatch_semaphore_signal(waitingToRetry);
    }).andForwardToRealObject();
    [queue resume];
    [self enqueueCommandInQueue:queue];
    XCTAssertEqual(dispatch_semaphore_wait(waitingToRetry, PFTimeFromNow(10)), 0L);

    NSMutableArray<PFRESTCommand *> *commands = [NSMutableArray array];
    XCTestExpectation *commandSent = [self expectationWithDescription:@"Command sent"];
    commandSent.assertForOverFulfill = NO;
    [Parse _currentManager].commandRunner = [self mockCommandRunnerRecordingCommands:commands andDo:^{
        [commandSent fulfill];
    }];

    // The command is retried with the new server right away instead of after the retry interval
    [Parse setServer:@"https://127.0.0.1/other"];
    [self waitForExpectations:@[ commandSent ] timeout:10];
    [queue waitForRunningCommands];

    XCTAssertEqual([Parse _currentManager].eventuallyQueue, queue);
    XCTAssertEqual(commands.count, 1);
    XCTAssertEqual(queue.commandCount, 0);
}

- (void)testSetServerRetriesRunningCommandThatFails {
    [self initializeParse];
    // Monitor a loopback address, whose reachability doesn't change, so that setting the server to the same host keeps queues offline
    [self monitorReachabilityOfServer:@"https://127.0.0.1/parse"];
    // Keep the eventually queues of other managers offline, so that only this queue runs commands
    [self simulateReachable:NO];
    PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
    [queue pause];
    queue.connected = YES;

    // Block the command until it is released, then fail it with an error that is retried
    dispatch_semaphore_t commandStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t commandReleased = dispatch_semaphore_create(0);
    [self mockCommandRunnerFailingWithTemporaryErrorAndDo:^{
        dispatch_semaphore_signal(commandStarted);
        dispatch_semaphore_wait(commandReleased, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(commandReleased);
    }];
    [queue resume];
    [self enqueueCommandInQueue:queue];
    XCTAssertEqual(dispatch_semaphore_wait(commandStarted, PFTimeFromNow(10)), 0L);

    NSMutableArray<PFRESTCommand *> *commands = [NSMutableArray array];
    XCTestExpectation *commandSent = [self expectationWithDescription:@"Command sent"];
    commandSent.assertForOverFulfill = NO;
    [Parse _currentManager].commandRunner = [self mockCommandRunnerRecordingCommands:commands andDo:^{
        [commandSent fulfill];
    }];

    // Setting the server doesn't wait for the running command
    dispatch_group_t settingServer = dispatch_group_create();
    dispatch_group_async(settingServer, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [Parse setServer:@"https://127.0.0.1/other"];
    });
    XCTAssertEqual(dispatch_group_wait(settingServer, PFTimeFromNow(10)), 0L);
    // Accessing the queue waits until setting the server asked the queue to retry its commands
    XCTAssertEqual([Parse _currentManager].eventuallyQueue, queue);

    // The command fails after the server was set, so it is retried with the new server right away
    dispatch_semaphore_signal(commandReleased);
    [self waitForExpectations:@[ commandSent ] timeout:10];
    [queue waitForRunningCommands];

    XCTAssertEqual(commands.count, 1);
    XCTAssertEqual(queue.commandCount, 0);
}

- (void)testLDSEnabledWithoutInitializer {
    XCTAssertFalse([Parse isLocalDatastoreEnabled]);
    [Parse enableLocalDatastore];

    XCTAssertTrue([Parse isLocalDatastoreEnabled]);
    [Parse setApplicationId:@"a" clientKey:@"b"];

    XCTAssertTrue([Parse isLocalDatastoreEnabled]);
}

- (void)testInitializeWithLDSAfterInitializeShouldThrowException {
    [Parse setApplicationId:@"a" clientKey:@"b"];
    PFAssertThrowsInconsistencyException([Parse enableLocalDatastore]);
}

- (void)testInitializeWithNilApplicationIdShouldThrowException {
    NSString *yolo = nil;
    PFAssertThrowsInvalidArgumentException([Parse setApplicationId:yolo clientKey:yolo]);
    PFAssertThrowsInvalidArgumentException([Parse setApplicationId:yolo clientKey:@"a"]);
    PFAssertThrowsInvalidArgumentException([Parse setApplicationId:@"a" clientKey:yolo]);
}

@end
