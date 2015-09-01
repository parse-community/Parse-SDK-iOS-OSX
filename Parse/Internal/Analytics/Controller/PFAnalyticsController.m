/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAnalyticsController.h"

#import "BFTask+Private.h"
#import "PFAnalyticsUtilities.h"
#import "PFAssert.h"
#import "PFEventuallyQueue.h"
#import "PFRESTAnalyticsCommand.h"

@interface PFAnalyticsController ()

@property (nonatomic, weak, readonly) PFEventuallyQueue *eventuallyQueue;

@end

@implementation PFAnalyticsController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithDataSource:(id<PFEventuallyQueueProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFEventuallyQueueProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Track Event
///--------------------------------------

- (BFTask *)trackAppOpenedEventAsyncWithRemoteNotificationPayload:(NSDictionary *)payload
                                                     sessionToken:(NSString *)sessionToken {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        // If the Remote Notification payload had a message sent along with it, make
        // sure to send that along so the server can identify "app opened from push"
        // instead.
        id alert = payload[@"aps"][@"alert"];
        NSString *pushDigest = (alert ? [PFAnalyticsUtilities md5DigestFromPushPayload:alert] : nil);

        PFRESTCommand *command = [PFRESTAnalyticsCommand trackAppOpenedEventCommandWithPushHash:pushDigest
                                                                                   sessionToken:sessionToken];
        return [self.eventuallyQueue enqueueCommandInBackground:command];
    }] continueWithSuccessResult:@YES];
}

- (BFTask *)trackEventAsyncWithName:(NSString *)name
                         dimensions:(NSDictionary *)dimensions
                       sessionToken:(NSString *)sessionToken {
    PFParameterAssert([[name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length],
                      @"A name for the custom event must be provided.");

    if (dimensions) {
        [dimensions enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            PFParameterAssert([key isKindOfClass:[NSString class]] && [obj isKindOfClass:[NSString class]],
                              @"trackEvent dimensions expect keys and values of type NSString.");
        }];
    }

    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        NSDictionary *encodedDimensions = [[PFNoObjectEncoder objectEncoder] encodeObject:dimensions];
        PFRESTCommand *command = [PFRESTAnalyticsCommand trackEventCommandWithEventName:name
                                                                             dimensions:encodedDimensions
                                                                           sessionToken:sessionToken];
        return [self.eventuallyQueue enqueueCommandInBackground:command];
    }] continueWithSuccessResult:@YES];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (PFEventuallyQueue *)eventuallyQueue {
    return self.dataSource.eventuallyQueue;
}

@end
