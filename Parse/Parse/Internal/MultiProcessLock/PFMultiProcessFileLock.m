/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMultiProcessFileLock.h"

#import "PFAssert.h"
#import "PFMacros.h"

static const NSTimeInterval PFMultiProcessLockAttemptsDelay = 0.001;

@interface PFMultiProcessFileLock () {
    dispatch_queue_t _synchronizationQueue;
    int _fileDescriptor;
}

@property (nonatomic, copy, readwrite) NSString *filePath;
@property (nonatomic, copy, readwrite) NSString *lockFilePath;

@end

@implementation PFMultiProcessFileLock

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initForFileWithPath:(NSString *)path {
    self = [super init];
    if (!self) return nil;

    _filePath = [path copy];
    _lockFilePath = [path stringByAppendingPathExtension:@"pflock"];

    NSString *queueName = [NSString stringWithFormat:@"com.parse.multiprocess.%@", path.lastPathComponent.stringByDeletingPathExtension];
    _synchronizationQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);

    return self;
}

+ (instancetype)lockForFileWithPath:(NSString *)path {
    return [[self alloc] initForFileWithPath:path];
}

- (void)dealloc {
    [self unlock];
}

///--------------------------------------
#pragma mark - NSLocking
///--------------------------------------

- (void)lock {
    dispatch_sync(_synchronizationQueue, ^{
        // Greater than zero means that the lock was already succesfully acquired.
        if (_fileDescriptor > 0) {
            return;
        }

        BOOL locked = NO;
        while (!locked) @autoreleasepool {
            locked = [self _tryLock];
            if (!locked) {
                [NSThread sleepForTimeInterval:PFMultiProcessLockAttemptsDelay];
            }
        }
    });
}

- (void)unlock {
    dispatch_sync(_synchronizationQueue, ^{
        // Only descriptor that is greater than zero is going to be open.
        if (_fileDescriptor <= 0) {
            return;
        }

        close(_fileDescriptor);
        _fileDescriptor = 0;
    });
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

- (BOOL)_tryLock {
    const char *filePath = self.lockFilePath.fileSystemRepresentation;

    // Atomically create a lock file if it doesn't exist and acquire the lock.
    _fileDescriptor = open(filePath, (O_RDWR | O_CREAT | O_EXLOCK),
                           ((S_IRUSR | S_IWUSR | S_IXUSR) | (S_IRGRP | S_IWGRP | S_IXGRP) | (S_IROTH | S_IWOTH | S_IXOTH)));
    return (_fileDescriptor > 0);
}

@end
