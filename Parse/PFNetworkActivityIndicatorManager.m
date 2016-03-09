/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFNetworkActivityIndicatorManager.h"

#import "PFApplication.h"
#import "PFCommandRunningConstants.h"

static NSTimeInterval const PFNetworkActivityIndicatorVisibilityDelay = 0.17;

@interface PFNetworkActivityIndicatorManager () {
    dispatch_queue_t _networkActivityAccessQueue;
}

@property (nonatomic, assign, readwrite) NSUInteger networkActivityCount;

@property (nonatomic, strong) NSTimer *activityIndicatorVisibilityTimer;

@end

@implementation PFNetworkActivityIndicatorManager

@synthesize enabled = _enabled;
@synthesize networkActivityCount = _networkActivityCount;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (PFNetworkActivityIndicatorManager *)sharedManager {
    static PFNetworkActivityIndicatorManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[PFNetworkActivityIndicatorManager alloc] init];
        manager.enabled = YES;
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _networkActivityAccessQueue = dispatch_queue_create("com.parse.networkActivityIndicatorManager",
                                                        DISPATCH_QUEUE_SERIAL);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleWillSendURLRequestNotification:)
                                                 name:PFNetworkWillSendURLRequestNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleDidReceiveURLResponseNotification:)
                                                 name:PFNetworkDidReceiveURLResponseNotification
                                               object:nil];

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_activityIndicatorVisibilityTimer invalidate];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setNetworkActivityCount:(NSUInteger)networkActivityCount {
    dispatch_sync(_networkActivityAccessQueue, ^{
        _networkActivityCount = networkActivityCount;
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updateNetworkActivityIndicatorVisibilityAfterDelay];
    });
}

- (NSUInteger)networkActivityCount {
    __block NSUInteger count = 0;
    dispatch_sync(_networkActivityAccessQueue, ^{
        count = _networkActivityCount;
    });
    return count;
}

- (BOOL)isNetworkActivityIndicatorVisible {
    return self.networkActivityCount > 0;
}

///--------------------------------------
#pragma mark - Counts
///--------------------------------------

- (void)incrementActivityCount {
    dispatch_sync(_networkActivityAccessQueue, ^{
        _networkActivityCount++;
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updateNetworkActivityIndicatorVisibilityAfterDelay];
    });
}

- (void)decrementActivityCount {
    dispatch_sync(_networkActivityAccessQueue, ^{
        _networkActivityCount = MAX(_networkActivityCount - 1, 0);
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _updateNetworkActivityIndicatorVisibilityAfterDelay];
    });
}

///--------------------------------------
#pragma mark - Network Activity Indicator
///--------------------------------------

- (void)_updateNetworkActivityIndicatorVisibilityAfterDelay {
    if (self.enabled) {
        // Delay hiding of activity indicator for a short interval, to avoid flickering
        if (!self.networkActivityIndicatorVisible) {
            [self.activityIndicatorVisibilityTimer invalidate];

            NSTimeInterval timeInterval = PFNetworkActivityIndicatorVisibilityDelay;
            SEL selector = @selector(_updateNetworkActivityIndicatorVisibility);
            self.activityIndicatorVisibilityTimer = [NSTimer timerWithTimeInterval:timeInterval
                                                                            target:self
                                                                          selector:selector
                                                                          userInfo:nil
                                                                           repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.activityIndicatorVisibilityTimer
                                      forMode:NSRunLoopCommonModes];
        } else {
            [self performSelectorOnMainThread:@selector(_updateNetworkActivityIndicatorVisibility)
                                   withObject:nil
                                waitUntilDone:NO
                                        modes:@[ NSRunLoopCommonModes ]];
        }
    }
}

- (void)_updateNetworkActivityIndicatorVisibility NS_EXTENSION_UNAVAILABLE_IOS("") {
    if (![PFApplication currentApplication].extensionEnvironment) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = self.networkActivityIndicatorVisible;
    }
}

///--------------------------------------
#pragma mark - Command Running
///--------------------------------------

- (void)_handleWillSendURLRequestNotification:(NSNotification *)notification {
    [self incrementActivityCount];
}

- (void)_handleDidReceiveURLResponseNotification:(NSNotification *)notification {
    [self decrementActivityCount];
}

@end
