/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPushChannelsController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCurrentInstallationController.h"
#import "PFErrorUtilities.h"
#import "PFInstallation.h"
#import "PFInstallationConstants.h"

@interface PFPushChannelsController ()

@property (nonatomic, strong, readonly) PFCurrentInstallationController *currentInstallationController;

@end

@implementation PFPushChannelsController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(nonnull id<PFCurrentInstallationControllerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(nonnull id<PFCurrentInstallationControllerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Get
///--------------------------------------

- (BFTask<NSSet<NSString *> *>*)getSubscribedChannelsAsync {
    return [[self _getCurrentObjectAsync] continueWithSuccessBlock:^id(BFTask *task) {
        PFInstallation *installation = task.result;

        BFTask *installationTask = (installation.objectId
                                    ? (BFTask *)[installation fetchInBackground]
                                    : (BFTask *)[installation saveInBackground]);

        return [installationTask continueWithSuccessBlock:^id(BFTask *_) {
            return [NSSet setWithArray:installation.channels];
        }];
    }];
}

///--------------------------------------
#pragma mark - Subscribe
///--------------------------------------

- (BFTask *)subscribeToChannelAsyncWithName:(nonnull NSString *)name {
    return [[self _getCurrentObjectAsync] continueWithSuccessBlock:^id(BFTask *task) {
        PFInstallation *installation = task.result;
        if ([installation.channels containsObject:name] &&
            ![installation isDirtyForKey:PFInstallationKeyChannels]) {
            return @YES;
        }

        [installation addUniqueObject:name forKey:PFInstallationKeyChannels];
        return [installation saveInBackground];
    }];
}

- (BFTask *)unsubscribeFromChannelAsyncWithName:(nonnull NSString *)name {
    return [[self _getCurrentObjectAsync] continueWithSuccessBlock:^id(BFTask *task) {
        PFInstallation *installation = task.result;
        if (name.length != 0 &&
            ![installation.channels containsObject:name] &&
            ![installation isDirtyForKey:PFInstallationKeyChannels]) {
            return @YES;
        }
        [installation removeObject:name forKey:PFInstallationKeyChannels];
        return [installation saveInBackground];
    }];
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

- (BFTask *)_getCurrentObjectAsync {
    return [[self.currentInstallationController getCurrentObjectAsync] continueWithSuccessBlock:^id(BFTask *task) {
        PFInstallation *installation = task.result;
        if (!installation.deviceToken) {
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorPushMisconfigured
                                                     message:@"There is no device token stored yet."];
            return [BFTask taskWithError:error];
        }

        return task;
    }];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (PFCurrentInstallationController *)currentInstallationController {
    return self.dataSource.currentInstallationController;
}

@end
