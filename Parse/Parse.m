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
#import "PFEventuallyPin.h"
#import "PFObject+Subclass.h"
#import "PFOfflineStore.h"
#import "PFPin.h"
#import "PFPinningEventuallyQueue.h"
#import "PFUserPrivate.h"
#import "PFLogger.h"
#import "PFSession.h"
#import "PFFileManager.h"
#import "PFApplication.h"
#import "PFKeychainStore.h"
#import "PFLogging.h"
#import "PFInstallationPrivate.h"
#import "PFObjectSubclassingController.h"

#if PARSE_IOS_ONLY
#import "PFProduct+Private.h"
#endif

#import "PFCategoryLoader.h"

@implementation Parse

static ParseManager *currentParseManager_;

static BOOL shouldEnableLocalDatastore_;

static NSString *applicationGroupIdentifier_;
static NSString *containingApplicationBundleIdentifier_;

+ (void)initialize {
    if (self == [Parse class]) {
        // Load all private categories, that we have...
        // Without this call - private categories - will require `-ObjC` in linker flags.
        // By explicitly calling empty method - we can avoid that.
        [PFCategoryLoader loadPrivateCategories];
    }
}

///--------------------------------------
#pragma mark - Connect
///--------------------------------------

+ (void)setApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey {
    PFConsistencyAssert([applicationId length], @"'applicationId' should not be nil.");
    PFConsistencyAssert([clientKey length], @"'clientKey' should not be nil.");
    
    // Setup new manager first, so it's 100% ready whenever someone sends a request for anything.
    ParseManager *manager = [[ParseManager alloc] initWithApplicationId:applicationId clientKey:clientKey];
    [manager configureWithApplicationGroupIdentifier:applicationGroupIdentifier_
                     containingApplicationIdentifier:containingApplicationBundleIdentifier_
                               enabledLocalDataStore:shouldEnableLocalDatastore_];
    currentParseManager_ = manager;

    shouldEnableLocalDatastore_ = NO;

    PFObjectSubclassingController *subclassingController = [PFObjectSubclassingController defaultController];
    // Register built-in subclasses of PFObject so they get used.
    // We're forced to register subclasses directly this way, in order to prevent a deadlock.
    // If we ever switch to bundle scanning, this code can go away.
    [subclassingController registerSubclass:[PFUser class]];
    [subclassingController registerSubclass:[PFInstallation class]];
    [subclassingController registerSubclass:[PFSession class]];
    [subclassingController registerSubclass:[PFRole class]];
    [subclassingController registerSubclass:[PFPin class]];
    [subclassingController registerSubclass:[PFEventuallyPin class]];
#if TARGET_OS_IPHONE
    [subclassingController registerSubclass:[PFProduct class]];
#endif

    [currentParseManager_ preloadDiskObjectsToMemoryAsync];

    [[self parseModulesCollection] parseDidInitializeWithApplicationId:applicationId clientKey:clientKey];
}

+ (NSString *)getApplicationId {
    PFConsistencyAssert(currentParseManager_,
                        @"You have to call setApplicationId:clientKey: on Parse to configure Parse.");
    return currentParseManager_.applicationId;
}

+ (NSString *)getClientKey {
    PFConsistencyAssert(currentParseManager_,
                        @"You have to call setApplicationId:clientKey: on Parse to configure Parse.");
    return currentParseManager_.clientKey;
}

///--------------------------------------
#pragma mark - Extensions Data Sharing
///--------------------------------------

+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier {
    PFConsistencyAssert(!currentParseManager_,
                        @"'enableDataSharingWithApplicationGroupIdentifier:' must be called before 'setApplicationId:clientKey'");
    PFParameterAssert([groupIdentifier length], @"'groupIdentifier' should not be nil.");
    PFConsistencyAssert(![PFApplication currentApplication].extensionEnvironment, @"This method cannot be used in application extensions.");
    PFConsistencyAssert([PFFileManager isApplicationGroupContainerReachableForGroupIdentifier:groupIdentifier],
                        @"ApplicationGroupContainer is unreachable. Please double check your Xcode project settings.");
    applicationGroupIdentifier_ = [groupIdentifier copy];
}

+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier
                                 containingApplication:(NSString *)bundleIdentifier {
    PFConsistencyAssert(!currentParseManager_,
                        @"'enableDataSharingWithApplicationGroupIdentifier:containingApplication:' must be called before 'setApplicationId:clientKey'");
    PFParameterAssert([groupIdentifier length], @"'groupIdentifier' should not be nil.");
    PFParameterAssert([bundleIdentifier length], @"Containing application bundle identifier should not be nil.");
    PFConsistencyAssert([PFApplication currentApplication].extensionEnvironment, @"This method can only be used in application extensions.");
    PFConsistencyAssert([PFFileManager isApplicationGroupContainerReachableForGroupIdentifier:groupIdentifier],
                        @"ApplicationGroupContainer is unreachable. Please double check your Xcode project settings.");

    applicationGroupIdentifier_ = groupIdentifier;
    containingApplicationBundleIdentifier_ = bundleIdentifier;
}

+ (NSString *)applicationGroupIdentifierForDataSharing {
    return applicationGroupIdentifier_;
}

+ (NSString *)containingApplicationBundleIdentifierForDataSharing {
    return containingApplicationBundleIdentifier_;
}

+ (void)_resetDataSharingIdentifiers {
    applicationGroupIdentifier_ = nil;
    containingApplicationBundleIdentifier_ = nil;
}

///--------------------------------------
#pragma mark - Local Datastore
///--------------------------------------

+ (void)enableLocalDatastore {
    PFConsistencyAssert(!currentParseManager_,
                        @"'enableLocalDataStore' must be called before 'setApplicationId:clientKey:'");

    // Lazily enableLocalDatastore after init. We can't use ParseModule because
    // ParseModule isn't processed in main thread and may cause race condition.
    shouldEnableLocalDatastore_ = YES;
}

+ (BOOL)isLocalDatastoreEnabled {
    if (!currentParseManager_) {
        return shouldEnableLocalDatastore_;
    }
    return currentParseManager_.offlineStoreLoaded;
}

///--------------------------------------
#pragma mark - User Interface
///--------------------------------------

#if PARSE_IOS_ONLY

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
    [PFLogger sharedLogger].logLevel = logLevel;
}

+ (PFLogLevel)logLevel {
    return [PFLogger sharedLogger].logLevel;
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
