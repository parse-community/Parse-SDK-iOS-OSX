/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFQueryController.h"

#import <Bolts/BFCancellationToken.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFObjectPrivate.h"
#import "PFOfflineStore.h"
#import "PFPin.h"
#import "PFQueryState.h"
#import "PFRESTQueryCommand.h"
#import "PFUser.h"
#import "Parse_Private.h"

@interface PFQueryController () <PFQueryControllerSubclass>

@end

@implementation PFQueryController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _commonDataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider>)dataSource {
    return [[self alloc] initWithCommonDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Find
///--------------------------------------

- (BFTask *)findObjectsAsyncForQueryState:(PFQueryState *)queryState
                    withCancellationToken:(BFCancellationToken *)cancellationToken
                                     user:(PFUser *)user {
    NSDate *queryStart = (queryState.trace ? [NSDate date] : nil);
    __block NSDate *querySent = nil;

    NSString *sessionToken = user.sessionToken;
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        if (cancellationToken.cancellationRequested) {
            return [BFTask cancelledTask];
        }

        PFRESTCommand *command = [PFRESTQueryCommand findCommandForQueryState:queryState withSessionToken:sessionToken];
        querySent = (queryState.trace ? [NSDate date] : nil);
        return [self runNetworkCommandAsync:command
                      withCancellationToken:cancellationToken
                              forQueryState:queryState];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        PFCommandResult *result = task.result;
        NSDate *queryReceived = (queryState.trace ? [NSDate date] : nil);

        NSArray *resultObjects = result.result[@"results"];
        NSMutableArray *foundObjects = [NSMutableArray arrayWithCapacity:resultObjects.count];
        if (resultObjects != nil) {
            NSString *resultClassName = result.result[@"className"];
            if (!resultClassName) {
                resultClassName = queryState.parseClassName;
            }
            NSArray *selectedKeys = queryState.selectedKeys.allObjects;
            for (NSDictionary *resultObject in resultObjects) {
                PFObject *object = [PFObject _objectFromDictionary:resultObject
                                                  defaultClassName:resultClassName
                                                      selectedKeys:selectedKeys];
                [foundObjects addObject:object];
            }
        }

        NSString *traceLog = [result.result objectForKey:@"trace"];
        if (traceLog != nil) {
            NSLog(@"Pre-processing took %f seconds\n%@Client side parsing took %f seconds",
                  [querySent timeIntervalSinceDate:queryStart], traceLog,
                  [queryReceived timeIntervalSinceNow]);
        }

        return foundObjects;
    } cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - Count
///--------------------------------------

- (BFTask *)countObjectsAsyncForQueryState:(PFQueryState *)queryState
                     withCancellationToken:(BFCancellationToken *)cancellationToken
                                      user:(PFUser *)user {
    NSString *sessionToken = user.sessionToken;
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        if (cancellationToken.cancellationRequested) {
            return [BFTask cancelledTask];
        }

        PFRESTQueryCommand *findCommand = [PFRESTQueryCommand findCommandForQueryState:queryState
                                                                      withSessionToken:sessionToken];
        PFRESTCommand *countCommand = [PFRESTQueryCommand countCommandFromFindCommand:findCommand];
        return [self runNetworkCommandAsync:countCommand
                      withCancellationToken:cancellationToken
                              forQueryState:queryState];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        PFCommandResult *result = task.result;
        return result.result[@"count"];
    } cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - Caching
///--------------------------------------

- (NSString *)cacheKeyForQueryState:(PFQueryState *)queryState sessionToken:(NSString *)sessionToken {
    return nil;
}

- (BOOL)hasCachedResultForQueryState:(PFQueryState *)queryState sessionToken:(NSString *)sessionToken {
    return NO;
}

- (void)clearCachedResultForQueryState:(PFQueryState *)queryState sessionToken:(NSString *)sessionToken {
}

- (void)clearAllCachedResults {
}

///--------------------------------------
#pragma mark - PFQueryControllerSubclass
///--------------------------------------

- (BFTask *)runNetworkCommandAsync:(PFRESTCommand *)command
             withCancellationToken:(BFCancellationToken *)cancellationToken
                     forQueryState:(PFQueryState *)queryState {
    return [self.commonDataSource.commandRunner runCommandAsync:command
                                                    withOptions:PFCommandRunningOptionRetryIfFailed
                                              cancellationToken:cancellationToken];
}

@end
