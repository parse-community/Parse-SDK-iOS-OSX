/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFReachability.h"

#import <SystemConfiguration/SystemConfiguration.h>

#import "PFAssert.h"
#import "PFConstants.h"
#import "PFLogging.h"
#import "PFMacros.h"
#import "PFWeakValue.h"

@interface PFReachability () {
    dispatch_queue_t _synchronizationQueue;
    NSMutableArray *_listenersArray;

    SCNetworkReachabilityRef _networkReachability;
}

@property (nonatomic, assign, readwrite) SCNetworkReachabilityFlags flags;

@end

static void _reachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    PFReachability *reachability = (__bridge PFReachability *)info;
    reachability.flags = flags;
}

@implementation PFReachability

@synthesize flags = _flags;

///--------------------------------------
#pragma mark - Class
///--------------------------------------

+ (BOOL)_reachabilityStateForFlags:(SCNetworkConnectionFlags)flags {
    PFReachabilityState reachabilityState = PFReachabilityStateNotReachable;

    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        // if target host is not reachable
        return reachabilityState;
    }

    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        // if target host is reachable and no connection is required
        //  then we'll assume (for now) that your on Wi-Fi
        reachabilityState = PFReachabilityStateReachableViaWiFi;
    }
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        // ... and the connection is on-demand (or on-traffic) if the
        //     calling application is using the CFSocketStream or higher APIs
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            // ... and no [user] intervention is needed
            reachabilityState = PFReachabilityStateReachableViaWiFi;
        }
    }

#if TARGET_OS_IPHONE
    if (((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) &&
        ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)) {
        // ... but WWAN connections are OK if the calling application
        //     is using the CFNetwork (CFSocketStream?) APIs.
        // ... and a network connection is not required (kSCNetworkReachabilityFlagsConnectionRequired)
        //     which could be et w/connection flag (e.g. IsWWAN) indicating type of connection required.
        reachabilityState = PFReachabilityStateReachableViaCell;
    }
#endif

    return reachabilityState;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (!self) return nil;

    _synchronizationQueue = dispatch_queue_create("com.parse.reachability", DISPATCH_QUEUE_CONCURRENT);
    _listenersArray = [NSMutableArray array];
    [self _startMonitoringReachabilityWithURL:url];

    return self;
}

+ (instancetype)sharedParseReachability {
    static PFReachability *reachability;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *serverUrlAsString = [NSString stringWithFormat:@"%@/%ld", kPFParseServer, (long)PARSE_API_VERSION];
        NSURL *serverUrl = [NSURL URLWithString:serverUrlAsString];
        reachability = [[self alloc] initWithURL:serverUrl];
    });
    return reachability;
}

///--------------------------------------
#pragma mark - Dealloc
///--------------------------------------

- (void)dealloc {
    if (_networkReachability != NULL) {
        SCNetworkReachabilitySetCallback(_networkReachability, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(_networkReachability, NULL);
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

///--------------------------------------
#pragma mark - Listeners
///--------------------------------------

- (void)addListener:(id<PFReachabilityListener>)listener {
    PFWeakValue *value = [PFWeakValue valueWithWeakObject:listener];
    dispatch_barrier_sync(_synchronizationQueue, ^{
        [_listenersArray addObject:value];
    });
}

- (void)removeListener:(id<PFReachabilityListener>)listener {
    dispatch_barrier_sync(_synchronizationQueue, ^{
        [_listenersArray filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            id weakObject = [evaluatedObject weakObject];
            return (weakObject == nil || weakObject == listener);
        }]];
    });
}

- (void)removeAllListeners {
    dispatch_barrier_sync(_synchronizationQueue, ^{
        [_listenersArray removeAllObjects];
    });
}

- (void)_notifyAllListeners {
    @weakify(self);
    dispatch_async(_synchronizationQueue, ^{
        @strongify(self);
        PFReachabilityState state = [[self class] _reachabilityStateForFlags:_flags];
        for (PFWeakValue *value in _listenersArray) {
            [value.weakObject reachability:self didChangeReachabilityState:state];
        }

        dispatch_barrier_async(_synchronizationQueue, ^{
            [_listenersArray filterUsingPredicate:[NSPredicate predicateWithFormat:@"SELf.weakObject != nil"]];
        });
    });
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setFlags:(SCNetworkReachabilityFlags)flags {
    dispatch_barrier_async(_synchronizationQueue, ^{
        _flags = flags;
        [self _notifyAllListeners];
    });
}

- (SCNetworkReachabilityFlags)flags {
    __block SCNetworkReachabilityFlags flags;
    dispatch_sync(_synchronizationQueue, ^{
        flags = _flags;
    });
    return flags;
}

- (PFReachabilityState)currentState {
    return [[self class] _reachabilityStateForFlags:self.flags];
}

///--------------------------------------
#pragma mark - Reachability
///--------------------------------------

- (void)_startMonitoringReachabilityWithURL:(NSURL *)url {
    dispatch_barrier_async(_synchronizationQueue, ^{
        _networkReachability = SCNetworkReachabilityCreateWithName(NULL, [[url host] UTF8String]);
        if (_networkReachability != NULL) {
            // Set the initial flags
            SCNetworkReachabilityFlags flags;
            SCNetworkReachabilityGetFlags(_networkReachability, &flags);
            self.flags = flags;

            // Set up notification for changes in reachability.
            SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
            if (SCNetworkReachabilitySetCallback(_networkReachability, _reachabilityCallback, &context)) {
                if (!SCNetworkReachabilitySetDispatchQueue(_networkReachability, _synchronizationQueue)) {
                    PFLogError(PFLoggingTagCommon, @"Unable to start listening for network connectivity status.");
                }
            }
        }
    });
}

@end
