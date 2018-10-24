/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "BFTask+Private.h"
#import "Parse.h"
#import "ParseInternal.h"
#import "ParseManager.h"
#import "ParseClientConfiguration_Private.h"
#import "PFEventuallyPin.h"
#import "PFObject+Subclass.h"
#import "PFOfflineStore.h"
#import "PFPin.h"
#import "PFPinningEventuallyQueue.h"
#import "PFUserPrivate.h"
#import "PFSystemLogger.h"
#import "PFSession.h"
#import "PFFileManager.h"
#import "PFApplication.h"
#import "PFKeychainStore.h"
#import "PFLogging.h"
#import "PFObjectSubclassingController.h"
#import "Parse_Private.h"

#if !TARGET_OS_WATCH && !TARGET_OS_TV
#import "PFInstallationPrivate.h"
#endif

#import "PFCategoryLoader.h"

@implementation Parse

static ParseManager *currentParseManager_;
static ParseClientConfiguration *currentParseConfiguration_;

+ (void)initialize {
    if (self == [Parse class]) {
        // Load all private categories, that we have...
        // Without this call - private categories - will require `-ObjC` in linker flags.
        // By explicitly calling empty method - we can avoid that.
        [PFCategoryLoader loadPrivateCategories];

        currentParseConfiguration_ = [ParseClientConfiguration emptyConfiguration];
    }
}

///--------------------------------------
#pragma mark - Connect
///--------------------------------------

+ (void)setApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey {
    PFParameterAssert(clientKey.length, @"`clientKey` should not be nil.");
    currentParseConfiguration_.applicationId = applicationId;
    currentParseConfiguration_.clientKey = clientKey;
    currentParseConfiguration_.server = [PFInternalUtils parseServerURLString]; // TODO: (nlutsenko) Clean this up after tests are updated.

    [self initializeWithConfiguration:currentParseConfiguration_];

    // This is needed to reset LDS's state in between initializations of Parse. We rely on this in the
    // context of unit tests.
    currentParseConfiguration_.localDatastoreEnabled = NO;
}

+ (void)initializeWithConfiguration:(ParseClientConfiguration *)configuration {
    PFConsistencyAssert(configuration.applicationId.length != 0,
                        @"You must set your configuration's `applicationId` before calling %s!", __PRETTY_FUNCTION__);
    PFConsistencyAssert(![PFApplication currentApplication].extensionEnvironment ||
                        configuration.applicationGroupIdentifier == nil ||
                        configuration.containingApplicationBundleIdentifier != nil,
                        @"'containingApplicationBundleIdentifier' must be non-nil in extension environment");
    PFConsistencyAssert(![self currentConfiguration], @"Parse is already initialized.");

    ParseManager *manager = [[ParseManager alloc] initWithConfiguration:configuration];
    [manager startManaging];

    currentParseManager_ = manager;

#if TARGET_OS_IOS
    [PFNetworkActivityIndicatorManager sharedManager].enabled = YES;
#endif

    [currentParseManager_ preloadDiskObjectsToMemoryAsync];

    [[self parseModulesCollection] parseDidInitializeWithApplicationId:configuration.applicationId clientKey:configuration.clientKey];
}

+ (nullable ParseClientConfiguration *)currentConfiguration {
    return currentParseManager_.configuration;
}

+ (NSString *)getApplicationId {
    PFConsistencyAssert(currentParseManager_,
                        @"You have to call setApplicationId:clientKey: on Parse to configure Parse.");
    return currentParseManager_.configuration.applicationId;
}

+ (nullable NSString *)getClientKey {
    PFConsistencyAssert(currentParseManager_,
                        @"You have to call setApplicationId:clientKey: on Parse to configure Parse.");
    return currentParseManager_.configuration.clientKey;
}

///--------------------------------------
#pragma mark - Extensions Data Sharing
///--------------------------------------

+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier {
    PFConsistencyAssert(!currentParseManager_,
                        @"'enableDataSharingWithApplicationGroupIdentifier:' must be called before 'setApplicationId:clientKey'");
    PFParameterAssert([groupIdentifier length], @"'groupIdentifier' should not be nil.");
    PFConsistencyAssert(![PFApplication currentApplication].extensionEnvironment, @"This method cannot be used in application extensions.");

    currentParseConfiguration_.applicationGroupIdentifier = groupIdentifier;
}

+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier
                                  containingApplication:(NSString *)bundleIdentifier {
    PFConsistencyAssert(!currentParseManager_,
                        @"'enableDataSharingWithApplicationGroupIdentifier:containingApplication:' must be called before 'setApplicationId:clientKey'");
    PFParameterAssert([groupIdentifier length], @"'groupIdentifier' should not be nil.");
    PFParameterAssert([bundleIdentifier length], @"Containing application bundle identifier should not be nil.");

    currentParseConfiguration_.applicationGroupIdentifier = groupIdentifier;
    currentParseConfiguration_.containingApplicationBundleIdentifier = bundleIdentifier;
}

+ (NSString *)applicationGroupIdentifierForDataSharing {
    ParseClientConfiguration *config = currentParseManager_ ? currentParseManager_.configuration
                                                            : currentParseConfiguration_;
    return config.applicationGroupIdentifier;
}

+ (NSString *)containingApplicationBundleIdentifierForDataSharing {
    ParseClientConfiguration *config = currentParseManager_ ? currentParseManager_.configuration
                                                            : currentParseConfiguration_;
    return config.containingApplicationBundleIdentifier;
}

+ (void)_resetDataSharingIdentifiers {
    [currentParseConfiguration_ _resetDataSharingIdentifiers];
}

///--------------------------------------
#pragma mark - Local Datastore
///--------------------------------------

+ (void)enableLocalDatastore {
    PFConsistencyAssert(!currentParseManager_,
                        @"'enableLocalDataStore' must be called before 'setApplicationId:clientKey:'");

    // Lazily enableLocalDatastore after init. We can't use ParseModule because
    // ParseModule isn't processed in main thread and may cause race condition.
    currentParseConfiguration_.localDatastoreEnabled = YES;
}

+ (BOOL)isLocalDatastoreEnabled {
    if (!currentParseManager_) {
        return currentParseConfiguration_.localDatastoreEnabled;
    }
    return currentParseManager_.offlineStoreLoaded;
}

///--------------------------------------
#pragma mark - User Interface
///--------------------------------------

#if TARGET_OS_IOS

+ (void)offlineMessagesEnabled:(BOOL)enabled {
    // Deprecated method - shouldn't do anything.
}

+ (void)errorMessagesEnabled:(BOOL)enabled {
    // Deprecated method - shouldn't do anything.
}

#endif

///--------------------------------------
#pragma mark - Logging
///--------------------------------------

+ (void)setLogLevel:(PFLogLevel)logLevel {
    [PFSystemLogger sharedLogger].logLevel = logLevel;
}

+ (PFLogLevel)logLevel {
    return [PFSystemLogger sharedLogger].logLevel;
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

+ (ParseManager *)_currentManager {
    return currentParseManager_;
}

+ (void)_clearCurrentManager {
    currentParseManager_ = nil;
}

///--------------------------------------
#pragma mark - Modules
///--------------------------------------

+ (void)enableParseModule:(id<ParseModule>)module {
    [[self parseModulesCollection] addParseModule:module];
}

+ (void)disableParseModule:(id<ParseModule>)module {
    [[self parseModulesCollection] removeParseModule:module];
}

+ (BOOL)isModuleEnabled:(id<ParseModule>)module {
    return [[self parseModulesCollection] containsModule:module];
}

+ (ParseModuleCollection *)parseModulesCollection {
    static ParseModuleCollection *collection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collection = [[ParseModuleCollection alloc] init];
    });
    return collection;
}

@end
