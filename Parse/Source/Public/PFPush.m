/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPush.h"
#import "PFPushPrivate.h"

#import <AudioToolbox/AudioToolbox.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFEncoder.h"
#import "PFHash.h"
#import "PFInstallationPrivate.h"
#import "PFKeychainStore.h"
#import "PFMacros.h"
#import "PFMutablePushState.h"
#import "PFMutableQueryState.h"
#import "PFPushChannelsController.h"
#import "PFPushController.h"
#import "PFPushManager.h"
#import "PFPushUtilities.h"
#import "PFQueryPrivate.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"
#import "PFApplication.h"

static Class _pushInternalUtilClass = nil;

@interface PFPush ()

@property (nonatomic, strong) PFMutablePushState *state;
@property (nonatomic, strong) PFQuery<PFInstallation *> *query;

@end

@implementation PFPush (Private)

+ (Class)pushInternalUtilClass {
    return _pushInternalUtilClass ?: [PFPushUtilities class];
}

+ (void)setPushInternalUtilClass:(Class)utilClass {
    if (utilClass) {
        PFParameterAssert([utilClass conformsToProtocol:@protocol(PFPushInternalUtils)],
                          @"utilClass must conform to PFPushInternalUtils protocol");
    }
    _pushInternalUtilClass = utilClass;
}

@end

@implementation PFPush

///--------------------------------------
#pragma mark - Instance
///--------------------------------------

#pragma mark Init

+ (instancetype)push {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _state = [[PFMutablePushState alloc] init];

    return self;
}

#pragma mark Accessors

- (void)setQuery:(PFQuery *)query {
    PFParameterAssert(!self.state.channels || !query, @"Can't set both the query and channel(s) properties.");
    _query = query;
}

- (void)setChannelSet:(NSSet *)channelSet {
    PFParameterAssert(!self.query || !channelSet, @"Can't set both the query and channel(s) properties.");
    self.state.channels = channelSet;
}

- (void)setChannel:(NSString *)channel {
    self.channelSet = PF_SET(channel);
}

- (void)setChannels:(NSArray *)channels {
    self.channelSet = [NSSet setWithArray:channels];
}

- (void)setMessage:(NSString *)message {
    [self.state setPayloadWithMessage:message];
}

- (void)expireAtDate:(NSDate *)date {
    self.state.expirationDate = date;
    self.state.expirationTimeInterval = nil;
}

- (void)expireAfterTimeInterval:(NSTimeInterval)timeInterval {
    self.state.expirationDate = nil;
    self.state.expirationTimeInterval = @(timeInterval);
}

- (void)clearExpiration {
    self.state.expirationDate = nil;
    self.state.expirationTimeInterval = nil;
}

- (void)setPushDate:(NSDate *)pushDate {
    self.state.pushDate = pushDate;
}

- (NSDate *)pushDate {
    return self.state.pushDate;
}

- (void)setData:(NSDictionary *)data {
    self.state.payload = data;
}

#pragma mark Sending

- (BFTask *)sendPushInBackground {
    if (self.query) {
        PFParameterAssert(!self.query.state.sortKeys, @"Cannot send push notifications to an ordered query.");
        PFParameterAssert(self.query.state.limit == -1, @"Cannot send push notifications to a limit query.");
        PFParameterAssert(self.query.state.skip == 0, @"Cannot send push notifications to a skip query.");
    }

    // Capture state first.
    PFPushController *pushController = [[self class] pushController];
    PFPushState *state = [self _currentStateCopy];
    return [[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        return [pushController sendPushNotificationAsyncWithState:state sessionToken:sessionToken];
    }];
}

- (void)sendPushInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [[self sendPushInBackground] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

#pragma mark Command

- (PFPushState *)_currentStateCopy {
    if (self.query) {
        PFMutablePushState *state = [self.state mutableCopy];
        state.queryState = self.query.state;
        return [state copy];
    }
    return [self.state copy];
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (instancetype)copyWithZone:(NSZone *)zone {
    PFPush *push = [[PFPush allocWithZone:zone] init];
    push.state = [self.state mutableCopy];
    return push;
}

///--------------------------------------
#pragma mark - NSObject
///--------------------------------------

- (NSUInteger)hash {
    return PFIntegerPairHash(self.query.hash, self.state.hash);
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[PFPush class]]) {
        return NO;
    }

    PFPush *push = (PFPush *)object;
    return (((self.query == nil && push.query == nil) ||
             [self.query isEqual:push.query]) &&
            [self.state isEqual:push.state]);
}

///--------------------------------------
#pragma mark - Sending Push Notifications
///--------------------------------------

#pragma mark To Channel

+ (BFTask *)sendPushMessageToChannelInBackground:(NSString *)channel withMessage:(NSString *)message {
    NSDictionary *data = @{ @"alert" : message };
    return [self sendPushDataToChannelInBackground:channel withData:data];
}

+ (void)sendPushMessageToChannelInBackground:(NSString *)channel withMessage:(NSString *)message block:(PFBooleanResultBlock)block {
    [[self sendPushMessageToChannelInBackground:channel withMessage:message] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

+ (BFTask *)sendPushDataToChannelInBackground:(NSString *)channel withData:(NSDictionary *)data {
    PFPush *push = [self push];
    [push setChannel:channel];
    [push setData:data];
    return [push sendPushInBackground];
}

+ (void)sendPushDataToChannelInBackground:(NSString *)channel withData:(NSDictionary *)data block:(PFBooleanResultBlock)block {
    [[self sendPushDataToChannelInBackground:channel withData:data] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

#pragma mark To Query

+ (BFTask *)sendPushMessageToQueryInBackground:(PFQuery *)query withMessage:(NSString *)message {
    PFPush *push = [PFPush push];
    push.query = query;
    push.message = message;
    return [push sendPushInBackground];
}

+ (void)sendPushMessageToQueryInBackground:(PFQuery *)query withMessage:(NSString *)message block:(PFBooleanResultBlock)block {
    PFPush *push = [PFPush push];
    push.query = query;
    push.message = message;
    [push sendPushInBackgroundWithBlock:block];
}

+ (BFTask *)sendPushDataToQueryInBackground:(PFQuery *)query withData:(NSDictionary *)data {
    PFPush *push = [PFPush push];
    push.query = query;
    push.data = data;
    return [push sendPushInBackground];
}

+ (void)sendPushDataToQueryInBackground:(PFQuery *)query withData:(NSDictionary *)data block:(PFBooleanResultBlock)block {
    PFPush *push = [PFPush push];
    push.query = query;
    push.data = data;
    [push sendPushInBackgroundWithBlock:block];
}

///--------------------------------------
#pragma mark - Channels
///--------------------------------------

#pragma mark Get

+ (BFTask<NSSet<NSString *> *>*)getSubscribedChannelsInBackground {
    return [[self channelsController] getSubscribedChannelsAsync];
}

+ (void)getSubscribedChannelsInBackgroundWithBlock:(PFSetResultBlock)block {
    [[self getSubscribedChannelsInBackground] thenCallBackOnMainThreadAsync:block];
}

#pragma mark Subscribe

+ (BFTask *)subscribeToChannelInBackground:(NSString *)channel {
    return [[self channelsController] subscribeToChannelAsyncWithName:channel];
}

+ (void)subscribeToChannelInBackground:(NSString *)channel block:(PFBooleanResultBlock)block {
    [[self subscribeToChannelInBackground:channel] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

#pragma mark Unsubscribe

+ (BFTask *)unsubscribeFromChannelInBackground:(NSString *)channel {
    return [[self channelsController] unsubscribeFromChannelAsyncWithName:channel];
}

+ (void)unsubscribeFromChannelInBackground:(NSString *)channel block:(PFBooleanResultBlock)block {
    [[self unsubscribeFromChannelInBackground:channel] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

///--------------------------------------
#pragma mark - Handling Notifications
///--------------------------------------

#if TARGET_OS_IOS || TARGET_OS_TV
+ (void)handlePush:(NSDictionary *)userInfo {
    UIApplication *application = [PFApplication currentApplication].systemApplication;
    if (application.applicationState != UIApplicationStateActive) {
        return;
    }

    NSDictionary *aps = userInfo[@"aps"];
    
#if TARGET_OS_IOS
    id alert = aps[@"alert"];

    if (alert) {
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleNameKey];
        NSString *message = nil;
        if ([alert isKindOfClass:[NSString class]]) {
            message = alert;
        } else if ([alert isKindOfClass:[NSDictionary class]]) {
            NSDictionary *alertDict = alert;
            NSString *locKey = alertDict[@"loc-key"];
            if (locKey) {
                NSString *format = [[NSBundle mainBundle] localizedStringForKey:locKey value:@"" table:nil];
                message = [PFInternalUtils _stringWithFormat:format arguments:alertDict[@"loc-args"]];
            }
        }
        if (message) {
            [[self pushInternalUtilClass] showAlertViewWithTitle:appName message:message];
        }
    }
#endif

    NSNumber *badgeNumber = aps[@"badge"];
    if (badgeNumber) {
        NSInteger number = [aps[@"badge"] integerValue];
        application.applicationIconBadgeNumber = number;
    }

#if TARGET_OS_IOS
    NSString *soundName = aps[@"sound"];

    // Vibrate or play sound only if `sound` is specified.
    if ([soundName isKindOfClass:[NSString class]] && soundName.length != 0) {
        // Vibrate if the sound is `default`, otherwise - play the sound name.
        if ([soundName isEqualToString:@"default"]) {
            [[self pushInternalUtilClass] playVibrate];
        } else {
            [[self pushInternalUtilClass] playAudioWithName:soundName];
        }
    }
#endif
}
#endif

///--------------------------------------
#pragma mark - Store Token
///--------------------------------------

+ (void)storeDeviceToken:(id)deviceToken {
    NSString *deviceTokenString = [[self pushInternalUtilClass] convertDeviceTokenToString:deviceToken];
    [PFInstallation currentInstallation].deviceToken = deviceTokenString;
}

///--------------------------------------
#pragma mark - Deprecated
///--------------------------------------

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)setPushToIOS:(BOOL)pushToIOS {
}

- (void)setPushToAndroid:(BOOL)pushToAndroid {
}
#pragma clang diagnostic pop

///--------------------------------------
#pragma mark - Push Manager
///--------------------------------------

+ (PFPushController *)pushController {
    return [Parse _currentManager].pushManager.pushController;
}

+ (PFPushChannelsController *)channelsController {
    return [Parse _currentManager].pushManager.channelsController;
}

@end

///--------------------------------------
#pragma mark - Synchronous
///--------------------------------------

@implementation PFPush (Synchronous)

#pragma mark Sending Push Notifications

- (BOOL)sendPush:(NSError **)error {
    return [[[self sendPushInBackground] waitForResult:error] boolValue];
}

+ (BOOL)sendPushMessageToChannel:(NSString *)channel withMessage:(NSString *)message error:(NSError **)error {
    return [[[self sendPushMessageToChannelInBackground:channel withMessage:message] waitForResult:error] boolValue];
}

+ (BOOL)sendPushDataToChannel:(NSString *)channel withData:(NSDictionary *)data error:(NSError **)error {
    return [[[PFPush sendPushDataToChannelInBackground:channel withData:data] waitForResult:error] boolValue];
}

+ (BOOL)sendPushMessageToQuery:(PFQuery *)query withMessage:(NSString *)message error:(NSError **)error {
    PFPush *push = [PFPush push];
    push.query = query;
    push.message = message;
    return [push sendPush:error];
}

+ (BOOL)sendPushDataToQuery:(PFQuery *)query withData:(NSDictionary *)data error:(NSError **)error {
    PFPush *push = [PFPush push];
    push.query = query;
    push.data = data;
    return [push sendPush:error];
}

#pragma mark Managing Channel Subscriptions

+ (NSSet<NSString *> *)getSubscribedChannels:(NSError **)error {
    return [[self getSubscribedChannelsInBackground] waitForResult:error];
}

+ (BOOL)subscribeToChannel:(NSString *)channel error:(NSError **)error {
    return [[[self subscribeToChannelInBackground:channel] waitForResult:error] boolValue];
}

+ (BOOL)unsubscribeFromChannel:(NSString *)channel error:(NSError **)error {
    return [[[self unsubscribeFromChannelInBackground:channel] waitForResult:error] boolValue];
}

@end

///--------------------------------------
#pragma mark - Deprecated
///--------------------------------------

@implementation PFPush (Deprecated)

#pragma mark Sending Push Notifications

- (void)sendPushInBackgroundWithTarget:(nullable id)target selector:(nullable SEL)selector {
    [self sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

+ (void)sendPushMessageToChannelInBackground:(NSString *)channel
                                 withMessage:(NSString *)message
                                      target:(nullable id)target
                                    selector:(nullable SEL)selector {
    [self sendPushMessageToChannelInBackground:channel withMessage:message block:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

+ (void)sendPushDataToChannelInBackground:(NSString *)channel
                                 withData:(NSDictionary *)data
                                   target:(nullable id)target
                                 selector:(nullable SEL)selector {
    [self sendPushDataToChannelInBackground:channel withData:data block:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

#pragma mark Managing Channel Subscriptions

+ (void)getSubscribedChannelsInBackgroundWithTarget:(id)target selector:(SEL)selector {
    [self getSubscribedChannelsInBackgroundWithBlock:^(NSSet *channels, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:channels object:error];
    }];
}

+ (void)subscribeToChannelInBackground:(NSString *)channel target:(nullable id)target selector:(nullable SEL)selector {
    [self subscribeToChannelInBackground:channel block:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

+ (void)unsubscribeFromChannelInBackground:(NSString *)channel target:(nullable id)target selector:(nullable SEL)selector {
    [self unsubscribeFromChannelInBackground:channel block:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

@end
