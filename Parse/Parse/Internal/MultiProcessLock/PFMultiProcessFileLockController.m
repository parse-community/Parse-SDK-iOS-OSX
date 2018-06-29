/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMultiProcessFileLockController.h"

#import "PFMultiProcessFileLock.h"

@interface PFMultiProcessFileLockController () {
    dispatch_queue_t _synchronizationQueue;
    NSMutableDictionary *_locksDictionary;
    NSMutableDictionary *_contentAccessDictionary;
}

@end

@implementation PFMultiProcessFileLockController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _synchronizationQueue = dispatch_queue_create("com.parse.multiprocesslock.controller", DISPATCH_QUEUE_CONCURRENT);

    _locksDictionary = [NSMutableDictionary dictionary];
    _contentAccessDictionary = [NSMutableDictionary dictionary];

    return self;
}

+ (instancetype)sharedController {
    static PFMultiProcessFileLockController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [[self alloc] init];
    });
    return controller;
}

///--------------------------------------
#pragma mark - Public
///--------------------------------------

- (void)beginLockedContentAccessForFileAtPath:(NSString *)filePath {
    dispatch_barrier_sync(_synchronizationQueue, ^{
        PFMultiProcessFileLock *fileLock = self->_locksDictionary[filePath];
        if (!fileLock) {
            fileLock = [PFMultiProcessFileLock lockForFileWithPath:filePath];
            self->_locksDictionary[filePath] = fileLock;
        }

        [fileLock lock];

        NSUInteger contentAccess = [self->_contentAccessDictionary[filePath] unsignedIntegerValue];
        self->_contentAccessDictionary[filePath] = @(contentAccess + 1);
    });
}

- (void)endLockedContentAccessForFileAtPath:(NSString *)filePath {
    dispatch_barrier_sync(_synchronizationQueue, ^{
        PFMultiProcessFileLock *fileLock = self->_locksDictionary[filePath];
        [fileLock unlock];

        if (fileLock && [self->_contentAccessDictionary[filePath] unsignedIntegerValue] == 0) {
            [self->_locksDictionary removeObjectForKey:filePath];
            [self->_contentAccessDictionary removeObjectForKey:filePath];
        }
    });
}

- (NSUInteger)lockedContentAccessCountForFileAtPath:(NSString *)filePath {
    __block NSUInteger value = 0;
    dispatch_sync(_synchronizationQueue, ^{
        value = [self->_contentAccessDictionary[filePath] unsignedIntegerValue];
    });
    return value;
}

@end
