/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCommandCache.h"

#include <mach/mach_time.h>
#include <sys/xattr.h>

#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCoreManager.h"
#import "PFErrorUtilities.h"
#import "PFEventuallyQueue_Private.h"
#import "PFFileManager.h"
#import "PFLogging.h"
#import "PFMacros.h"
#import "PFMultiProcessFileLockController.h"
#import "PFObject.h"
#import "PFObjectLocalIdStore.h"
#import "PFObjectPrivate.h"
#import "PFRESTCommand.h"
#import "Parse_Private.h"

static NSString *const _PFCommandCacheDiskCacheDirectoryName = @"Command Cache";

static const NSString *PFCommandCachePrefixString = @"Command";
static unsigned long long const PFCommandCacheDefaultDiskCacheSize = 10 * 1024 * 1024; // 10 MB

@interface PFCommandCache () <PFEventuallyQueueSubclass> {
    unsigned int _fileCounter;
}

@property (nonatomic, assign, readwrite, setter=_setDiskCacheSize:) unsigned long long diskCacheSize;

@end

@implementation PFCommandCache

@dynamic dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)newDefaultCommandCacheWithCommonDataSource:(id<PFCommandRunnerProvider>)dataSource
                                            coreDataSource:(id<PFObjectLocalIdStoreProvider>)coreDataSource
                                           cacheFolderPath:(NSString *)cacheFolderPath {
    NSString *diskCachePath = [cacheFolderPath stringByAppendingPathComponent:_PFCommandCacheDiskCacheDirectoryName];
    diskCachePath = diskCachePath.stringByStandardizingPath;
    PFCommandCache *cache = [[PFCommandCache alloc] initWithDataSource:dataSource
                                                        coreDataSource:coreDataSource
                                                      maxAttemptsCount:PFEventuallyQueueDefaultMaxAttemptsCount
                                                         retryInterval:PFEventuallyQueueDefaultTimeoutRetryInterval
                                                         diskCachePath:diskCachePath
                                                         diskCacheSize:PFCommandCacheDefaultDiskCacheSize];
    [cache start];
    return cache;
}

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource
                    coreDataSource:(id<PFObjectLocalIdStoreProvider>)coreDataSource
                  maxAttemptsCount:(NSUInteger)attemptsCount
                     retryInterval:(NSTimeInterval)retryInterval
                     diskCachePath:(NSString *)diskCachePath
                     diskCacheSize:(unsigned long long)diskCacheSize {
    self = [super initWithDataSource:dataSource maxAttemptsCount:attemptsCount retryInterval:retryInterval];
    if (!self) return nil;

    _coreDataSource = coreDataSource;
    _diskCachePath = diskCachePath;
    _diskCacheSize = diskCacheSize;
    _fileCounter = 0;

    [self _createDiskCachePathIfNeeded];

    return self;
}

///--------------------------------------
#pragma mark - Controlling Queue
///--------------------------------------

- (void)removeAllCommands {
    [self pause];

    [super removeAllCommands];

    NSArray *commandIdentifiers = [self _pendingCommandIdentifiers];
    NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:commandIdentifiers.count];

    for (NSString *identifier in commandIdentifiers) {
        BFTask *task = [self _removeFileForCommandWithIdentifier:identifier];
        [tasks addObject:task];
    }

    [[BFTask taskForCompletionOfAllTasks:tasks] waitUntilFinished];

    [self resume];
}

///--------------------------------------
#pragma mark - PFEventuallyQueue
///--------------------------------------

- (void)_simulateReboot {
    [super _simulateReboot];
    [self _createDiskCachePathIfNeeded];
}

///--------------------------------------
#pragma mark - PFEventuallyQueueSubclass
///--------------------------------------

- (NSString *)_newIdentifierForCommand:(id<PFNetworkCommand>)command {
    // Start with current time - so we can sort identifiers and get the oldest one first.
    return [NSString stringWithFormat:@"%@-%016qx-%08x-%@",
            PFCommandCachePrefixString,
            (unsigned long long)[NSDate timeIntervalSinceReferenceDate],
            _fileCounter++,
            [NSUUID UUID].UUIDString];
}

- (NSArray *)_pendingCommandIdentifiers {
    NSArray *result = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.diskCachePath error:nil];
    // Only accept files that starts with "Command" since sometimes the directory is filled with garbage
    // e.g.: https://phab.parse.com/file/info/PHID-FILE-qgbwk7sm7kcyaks6n4j7/
    result = [result filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@", PFCommandCachePrefixString]];

    return [result sortedArrayUsingSelector:@selector(compare:)];
}

- (id<PFNetworkCommand>)_commandWithIdentifier:(NSString *)identifier error:(NSError **)error {
    [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:self.diskCachePath];

    NSError *innerError = nil;
    NSData *jsonData = [NSData dataWithContentsOfFile:[self _filePathForCommandWithIdentifier:identifier]
                                              options:NSDataReadingUncached
                                                error:&innerError];

    [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:self.diskCachePath];

    if (innerError || !jsonData) {
        NSString *message = [NSString stringWithFormat:@"Failed to read command from cache. %@",
                             innerError ? innerError.localizedDescription : @""];
        innerError = [PFErrorUtilities errorWithCode:kPFErrorInternalServer
                                             message:message];
        if (error) {
            *error = innerError;
        }
        return nil;
    }

    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:0
                                                      error:&innerError];
    if (innerError) {
        NSString *message = [NSString stringWithFormat:@"Failed to deserialiaze command from cache. %@",
                             innerError.localizedDescription];
        innerError = [PFErrorUtilities errorWithCode:kPFErrorInternalServer
                                             message:message];
    } else {
        if ([PFRESTCommand isValidDictionaryRepresentation:jsonObject]) {
            return [PFRESTCommand commandFromDictionaryRepresentation:jsonObject];
        }
        innerError = [PFErrorUtilities errorWithCode:kPFErrorInternalServer
                                             message:@"Failed to construct eventually command from cache."
                                           shouldLog:NO];
    }
    if (innerError && error) {
        *error = innerError;
    }

    return nil;
}

- (BFTask *)_enqueueCommandInBackground:(id<PFNetworkCommand>)command
                                 object:(PFObject *)object
                             identifier:(NSString *)identifier {
    return [self _saveCommandToCacheInBackground:command object:object identifier:identifier];
}

- (BFTask *)_didFinishRunningCommand:(id<PFNetworkCommand>)command
                      withIdentifier:(NSString *)identifier
                          resultTask:(BFTask *)resultTask {
    // Get the new objectId and mark the new localId so it can be resolved.
    if (command.localId) {
        NSDictionary *dictionaryResult = nil;
        if ([resultTask.result isKindOfClass:[NSDictionary class]]) {
            dictionaryResult = resultTask.result;
        } else if ([resultTask.result isKindOfClass:[PFCommandResult class]]) {
            PFCommandResult *commandResult = resultTask.result;
            dictionaryResult = commandResult.result;
        }

        if (dictionaryResult != nil) {
            NSString *objectId = dictionaryResult[@"objectId"];
            if (objectId) {
                [self.coreDataSource.objectLocalIdStore setObjectId:objectId forLocalId:command.localId];
            }
        }
    }

    [[self _removeFileForCommandWithIdentifier:identifier] waitUntilFinished];
    return [super _didFinishRunningCommand:command withIdentifier:identifier resultTask:resultTask];
}

- (BFTask *)_waitForOperationSet:(PFOperationSet *)operationSet eventuallyPin:(PFEventuallyPin *)eventuallyPin {
    // Do nothing. This is only relevant in PFPinningEventuallyQueue. Looks super hacky you said? Yes it is!
    return [BFTask taskWithResult:nil];
}

///--------------------------------------
#pragma mark - Disk Cache
///--------------------------------------

- (BFTask *)_cleanupDiskCacheWithRequiredFreeSize:(NSUInteger)requiredSize {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        NSUInteger size = requiredSize;

        NSMutableDictionary<NSString *, NSNumber *> *commandSizes = [NSMutableDictionary dictionary];

        [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:self.diskCachePath];

        NSDictionary *directoryAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.diskCachePath error:nil];
        if ([directoryAttributes[NSFileSize] unsignedLongLongValue] > self.diskCacheSize) {
            NSDirectoryEnumerator<NSURL *> *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:self.diskCachePath]
                                                                              includingPropertiesForKeys:@[ NSURLFileSizeKey ]
                                                                                                 options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                                            errorHandler:nil];
            NSURL *fileURL = nil;
            while ((fileURL = [enumerator nextObject])) {
                NSNumber *fileSize = nil;
                if (![fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil]) {
                    continue;
                }
                if (fileSize) {
                    commandSizes[fileURL.path.lastPathComponent] = fileSize;
                    size += fileSize.unsignedIntegerValue;
                }
            }
        }

        [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:self.diskCachePath];

        if (size > self.diskCacheSize) {
            // Get identifiers and sort them to remove oldest commands first
            NSArray<NSString *> *identifiers = [commandSizes.allKeys sortedArrayUsingSelector:@selector(compare:)];
            for (NSString *identifier in identifiers) @autoreleasepool {
                [self _removeFileForCommandWithIdentifier:identifier];
                size -= [commandSizes[identifier] unsignedIntegerValue];

                if (size <= self.diskCacheSize) {
                    break;
                }
                [commandSizes removeObjectForKey:identifier];
            }
        }

        return nil;
    }];
}

- (void)_setDiskCacheSize:(unsigned long long)diskCacheSize {
    _diskCacheSize = diskCacheSize;
}

///--------------------------------------
#pragma mark - Files
///--------------------------------------

- (BFTask *)_saveCommandToCacheInBackground:(id<PFNetworkCommand>)command
                                     object:(PFObject *)object
                                 identifier:(NSString *)identifier {
    if (object != nil && object.objectId == nil) {
        command.localId = [object getOrCreateLocalId];
    }

    @weakify(self);
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);

        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:[command dictionaryRepresentation]
                                                       options:0
                                                         error:&error];
        NSUInteger commandSize = data.length;
        if (commandSize > self.diskCacheSize) {
            error = [PFErrorUtilities errorWithCode:kPFErrorInternalServer
                                            message:@"Failed to run command, because it's too big."];
        } else if (commandSize == 0) {
            error = [PFErrorUtilities errorWithCode:kPFErrorInternalServer
                                            message:@"Failed to run command, because it's empty."];
        }

        if (error) {
            return [BFTask taskWithError:error];
        }

        [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:self.diskCachePath];
        return [[[self _cleanupDiskCacheWithRequiredFreeSize:commandSize] continueWithBlock:^id(BFTask *task) {
            NSString *filePath = [self _filePathForCommandWithIdentifier:identifier];
            return [PFFileManager writeDataAsync:data toFile:filePath];
        }] continueWithBlock:^id(BFTask *task) {
            [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:self.diskCachePath];
            return task;
        }];
    }];
}

- (BFTask *)_removeFileForCommandWithIdentifier:(NSString *)identifier {
    NSString *filePath = [self _filePathForCommandWithIdentifier:identifier];
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:self.diskCachePath];
        return [PFFileManager removeItemAtPathAsync:filePath withFileLock:NO];
    }] continueWithBlock:^id(BFTask *task) {
        [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:self.diskCachePath];
        return task; // Roll-forward the previous task.
    }];
}

- (NSString *)_filePathForCommandWithIdentifier:(NSString *)identifier {
    return [self.diskCachePath stringByAppendingPathComponent:identifier];
}

- (void)_createDiskCachePathIfNeeded {
    [[PFFileManager createDirectoryIfNeededAsyncAtPath:_diskCachePath] waitForResult:nil withMainThreadWarning:NO];
}

@end
