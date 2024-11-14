/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFConfig.h"
#import "PFConfig_Private.h"

#import "BFTask+Private.h"
#import "PFConfigController.h"
#import "PFCoreManager.h"
#import "PFCurrentConfigController.h"
#import "PFCurrentUserController.h"
#import "PFInternalUtils.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

NSString *const PFConfigParametersRESTKey = @"params";

@interface PFConfig ()

@property (atomic, copy, readwrite) NSDictionary *parametersDictionary;

@end

@implementation PFConfig

///--------------------------------------
#pragma mark - Class
///--------------------------------------

+ (PFConfigController *)_configController {
    return [Parse _currentManager].coreManager.configController;
}

#pragma mark Public

+ (PFConfig *)currentConfig {
    return [[self getCurrentConfigInBackground] waitForResult:nil withMainThreadWarning:NO];
}

+ (BFTask<PFConfig *> *)getCurrentConfigInBackground {
    return [[self _configController].currentConfigController getCurrentConfigAsync];
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithFetchedConfig:(NSDictionary *)resultDictionary {
    self = [self init];
    if (!self) return nil;

    _parametersDictionary = resultDictionary[PFConfigParametersRESTKey];

    return self;
}

///--------------------------------------
#pragma mark - Fetch
///--------------------------------------

+ (BFTask *)getConfigInBackground {
    PFCurrentUserController *controller = [Parse _currentManager].coreManager.currentUserController;
    return [[controller getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        return [[self _configController] fetchConfigAsyncWithSessionToken:sessionToken];
    }];
}

+ (void)getConfigInBackgroundWithBlock:(PFConfigResultBlock)block {
    [[self getConfigInBackground] thenCallBackOnMainThreadAsync:block];
}

///--------------------------------------
#pragma mark - Getting Values
///--------------------------------------

- (id)objectForKey:(NSString *)key {
    return _parametersDictionary[key];
}

- (id)objectForKeyedSubscript:(NSString *)keyedSubscript {
    return _parametersDictionary[keyedSubscript];
}

#pragma mark Equality Testing

- (NSUInteger)hash {
    return _parametersDictionary.hash;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[PFConfig class]]) {
        PFConfig *other = object;

        // Compare pointers first, to account for nil dictionary
        return (self.parametersDictionary == other.parametersDictionary ||
                [self.parametersDictionary isEqual:other.parametersDictionary]);
    }

    return NO;
}

@end

///--------------------------------------
#pragma mark - Synchronous
///--------------------------------------

@implementation PFConfig (Synchronous)

#pragma mark Retrieving Config

+ (PFConfig *)getConfig {
    return [self getConfig:nil];
}

+ (PFConfig *)getConfig:(NSError **)error {
    return [[self getConfigInBackground] waitForResult:error];
}

@end
