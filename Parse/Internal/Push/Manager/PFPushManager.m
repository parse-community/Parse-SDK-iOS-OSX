/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPushManager.h"

#import "PFAssert.h"
#import "PFMacros.h"
#import "PFPushChannelsController.h"
#import "PFPushController.h"

@interface PFPushManager () {
    dispatch_queue_t _controllerAccessQueue;
}

@end

@implementation PFPushManager

@synthesize pushController = _pushController;
@synthesize channelsController = _channelsController;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                          coreDataSource:(id<PFCurrentInstallationControllerProvider>)coreDataSource {
    self = [super init];
    if (!self) return nil;

    _commonDataSource = commonDataSource;
    _coreDataSource = coreDataSource;
    _controllerAccessQueue = dispatch_queue_create("com.parse.push.controller.accessQueue", DISPATCH_QUEUE_SERIAL);

    return self;
}

+ (instancetype)managerWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                             coreDataSource:(id<PFCurrentInstallationControllerProvider>)coreDataSource {
    return [[self alloc] initWithCommonDataSource:commonDataSource coreDataSource:coreDataSource];
}

///--------------------------------------
#pragma mark - PushController
///--------------------------------------

- (PFPushController *)pushController {
    __block PFPushController *controller;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_pushController) {
            _pushController = [PFPushController controllerWithCommandRunner:self.commonDataSource.commandRunner];
        }
        controller = _pushController;
    });
    return controller;
}

- (void)setPushController:(PFPushController *)pushController {
    dispatch_sync(_controllerAccessQueue, ^{
        _pushController = pushController;
    });
}

///--------------------------------------
#pragma mark - Channels Controller
///--------------------------------------

- (PFPushChannelsController *)channelsController {
    __block PFPushChannelsController *controller;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_channelsController) {
            _channelsController = [PFPushChannelsController controllerWithDataSource:self.coreDataSource];
        }
        controller = _channelsController;
    });
    return controller;
}

- (void)setChannelsController:(PFPushChannelsController *)channelsController {
    dispatch_sync(_controllerAccessQueue, ^{
        _channelsController = channelsController;
    });
}

@end
