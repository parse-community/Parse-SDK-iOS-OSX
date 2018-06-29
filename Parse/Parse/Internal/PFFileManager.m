/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFileManager.h"

#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFLogging.h"
#import "PFMultiProcessFileLockController.h"

static NSString *const _PFFileManagerParseDirectoryName = @"Parse";

static NSDictionary *_PFFileManagerDefaultDirectoryFileAttributes() {
#if !PF_TARGET_OS_OSX
    return @{ NSFileProtectionKey : NSFileProtectionCompleteUntilFirstUserAuthentication };
#else
    return nil;
#endif
}

static NSDataWritingOptions _PFFileManagerDefaultDataWritingOptions() {
    NSDataWritingOptions options = NSDataWritingAtomic;
#if !PF_TARGET_OS_OSX
    options |= NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication;
#endif
    return options;
}

@interface PFFileManager ()

@property (nonatomic, copy) NSString *applicationIdentifier;
@property (nonatomic, copy) NSString *applicationGroupIdentifier;

@end

@implementation PFFileManager

///--------------------------------------
#pragma mark - Class
///--------------------------------------

+ (BOOL)isApplicationGroupContainerReachableForGroupIdentifier:(NSString *)applicationGroup {
    return ([[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:applicationGroup] != nil);
}

+ (BFTask *)writeStringAsync:(NSString *)string toFile:(NSString *)filePath {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        return [self writeDataAsync:data toFile:filePath];
    }];
}

+ (BFTask *)writeDataAsync:(NSData *)data toFile:(NSString *)filePath {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSError *error = nil;
        [data writeToFile:filePath
                  options:_PFFileManagerDefaultDataWritingOptions()
                    error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
}

+ (BFTask *)createDirectoryIfNeededAsyncAtPath:(NSString *)path {
    return [self createDirectoryIfNeededAsyncAtPath:path
                                        withOptions:PFFileManagerOptionSkipBackup
                                           executor:[BFExecutor defaultPriorityBackgroundExecutor]];
}

+ (BFTask *)createDirectoryIfNeededAsyncAtPath:(NSString *)path
                                   withOptions:(PFFileManagerOptions)options
                                      executor:(BFExecutor *)executor {
    return [BFTask taskFromExecutor:executor withBlock:^id{
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:path
                                      withIntermediateDirectories:YES
                                                       attributes:_PFFileManagerDefaultDirectoryFileAttributes()
                                                            error:&error];
            if (error) {
                return [BFTask taskWithError:error];
            }
        }

#if TARGET_OS_IOS || TARGET_OS_WATCH // No backups for Apple TV, since everything is cache.
        if (options & PFFileManagerOptionSkipBackup) {
            [self _skipBackupOnPath:path];
        }
#endif
        return nil;
    }];
}

+ (BFTask *)copyItemAsyncAtPath:(NSString *)fromPath toPath:(NSString *)toPath {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:fromPath toPath:toPath error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
}

+ (BFTask *)moveItemAsyncAtPath:(NSString *)fromPath toPath:(NSString *)toPath {
    if (toPath == nil) {
        return [BFTask taskWithError:[NSError errorWithDomain:@"destination path is nil" code:-1 userInfo:nil]];
    }
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        return nil;
    }];
}

+ (BFTask *)moveContentsOfDirectoryAsyncAtPath:(NSString *)fromPath
                             toDirectoryAtPath:(NSString *)toPath
                                      executor:(BFExecutor *)executor {
    if ([fromPath isEqualToString:toPath]) {
        return [BFTask taskWithResult:nil];
    }

    return [[[self createDirectoryIfNeededAsyncAtPath:toPath
                                          withOptions:PFFileManagerOptionSkipBackup
                                             executor:executor] continueWithSuccessBlock:^id(BFTask *task) {
        NSError *error = nil;
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fromPath
                                                                                error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        return contents;
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSArray *contents = task.result;
        if (contents.count == 0) {
            return nil;
        }

        NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:contents.count];
        for (NSString *path in contents) {
            BFTask *task = [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
                NSError *error = nil;
                NSString *fromFilePath = [fromPath stringByAppendingPathComponent:path];
                NSString *toFilePath = [toPath stringByAppendingPathComponent:path];
                [[NSFileManager defaultManager] moveItemAtPath:fromFilePath
                                                        toPath:toFilePath
                                                         error:&error];
                if (error) {
                    return [BFTask taskWithError:error];
                }
                return nil;
            }];
            [tasks addObject:task];
        }
        return [BFTask taskForCompletionOfAllTasks:tasks];
    }];
}

+ (BFTask *)removeDirectoryContentsAsyncAtPath:(NSString *)path {
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:path];

        NSFileManager *fileManager = [NSFileManager defaultManager];

        NSError *error = nil;
        NSArray *fileNames = [fileManager contentsOfDirectoryAtPath:path error:&error];
        if (error) {
            PFLogError(PFLoggingTagCommon, @"Failed to list directory: %@", path);
            return [BFTask taskWithError:error];
        }

        NSMutableArray *fileTasks = [NSMutableArray array];
        for (NSString *fileName in fileNames) {
            NSString *filePath = [path stringByAppendingPathComponent:fileName];
            BFTask *fileTask = [[self removeItemAtPathAsync:filePath withFileLock:NO] continueWithBlock:^id(BFTask *task) {
                if (task.faulted) {
                    PFLogError(PFLoggingTagCommon, @"Failed to delete file: %@ with error: %@", filePath, task.error);
                }
                return task;
            }];
            [fileTasks addObject:fileTask];
        }
        return [BFTask taskForCompletionOfAllTasks:fileTasks];
    }] continueWithBlock:^id(BFTask *task) {
        [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:path];
        return task;
    }];
}

+ (BFTask *)removeItemAtPathAsync:(NSString *)path {
    return [self removeItemAtPathAsync:path withFileLock:YES];
}

+ (BFTask *)removeItemAtPathAsync:(NSString *)path withFileLock:(BOOL)useFileLock {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        if (useFileLock) {
            [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:path];
        }
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:path]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
            if (error) {
                if (useFileLock) {
                    [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:path];
                }
                return [BFTask taskWithError:error];
            }
        }
        if (useFileLock) {
            [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:path];
        }
        return nil;
    }];
}

///--------------------------------------
#pragma mark - Instance
///--------------------------------------

#pragma mark Init

- (instancetype)initWithApplicationIdentifier:(NSString *)applicationIdentifier
                   applicationGroupIdentifier:(NSString *)applicationGroupIdentifier {
    self = [super init];
    if (!self) return nil;

    _applicationIdentifier = [applicationIdentifier copy];
    _applicationGroupIdentifier = [applicationGroupIdentifier copy];

    return self;
}

#pragma mark Public

- (NSString *)parseDefaultDataDirectoryPath {
    // NSHomeDirectory: Returns the path to either the user's or application's
    // home directory, depending on the platform. Sandboxed by default on iOS.
#if PF_TARGET_OS_OSX
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths firstObject];
    directoryPath = [directoryPath stringByAppendingPathComponent:_PFFileManagerParseDirectoryName];
    directoryPath = [directoryPath stringByAppendingPathComponent:self.applicationIdentifier];
#else
    NSString *directoryPath = nil;
    if (self.applicationGroupIdentifier) {
        NSURL *containerPath = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:self.applicationGroupIdentifier];
        directoryPath = [containerPath.path stringByAppendingPathComponent:_PFFileManagerParseDirectoryName];
        directoryPath = [directoryPath stringByAppendingPathComponent:self.applicationIdentifier];
    } else {
        return [self parseLocalSandboxDataDirectoryPath];
    }
#endif

    BFTask *createDirectoryTask = [[self class] createDirectoryIfNeededAsyncAtPath:directoryPath
                                                                       withOptions:PFFileManagerOptionSkipBackup
                                                                          executor:[BFExecutor immediateExecutor]];
    [createDirectoryTask waitForResult:nil withMainThreadWarning:NO];

    return directoryPath;
}

- (NSString *)parseLocalSandboxDataDirectoryPath {
#if PF_TARGET_OS_OSX
    return [self parseDefaultDataDirectoryPath];
#else
    NSString *library = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
    NSString *privateDocuments = [library stringByAppendingPathComponent:@"Private Documents"];
    NSString *directoryPath = [privateDocuments stringByAppendingPathComponent:_PFFileManagerParseDirectoryName];
    BFTask *createDirectoryTask = [[self class] createDirectoryIfNeededAsyncAtPath:directoryPath
                                                                       withOptions:PFFileManagerOptionSkipBackup
                                                                          executor:[BFExecutor immediateExecutor]];
    [createDirectoryTask waitForResult:nil withMainThreadWarning:NO];

    return directoryPath;
#endif
}

- (NSString *)parseDataItemPathForPathComponent:(NSString *)pathComponent {
    return [[self parseDefaultDataDirectoryPath] stringByAppendingPathComponent:pathComponent];
}

- (NSString *)parseCacheItemPathForPathComponent:(NSString *)component {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *folderPath = paths.firstObject;
    folderPath = [folderPath stringByAppendingPathComponent:_PFFileManagerParseDirectoryName];
#if PF_TARGET_OS_OSX
    // We append the applicationId in case the OS X application isn't sandboxed,
    // to avoid collisions in the generic ~/Library/Caches/Parse/------ dir.
    folderPath = [folderPath stringByAppendingPathComponent:self.applicationIdentifier];
#endif
    folderPath = [folderPath stringByAppendingPathComponent:component];
    return folderPath.stringByStandardizingPath;
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

// Skips all backups on the provided path.
+ (BOOL)_skipBackupOnPath:(NSString *)path {
    if (path == nil) {
        return NO;
    }

    NSError *error = nil;

    NSURL *url = [NSURL fileURLWithPath:path];
    BOOL success = [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
    if (!success) {
        PFLogError(PFLoggingTagCommon,
                   @"Unable to exclude %@ from backup with error: %@", [url lastPathComponent], error);
    }

    return success;
}

@end
