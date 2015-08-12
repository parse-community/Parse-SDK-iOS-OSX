/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectFilePersistenceController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFFileManager.h"
#import "PFJSONSerialization.h"
#import "PFMacros.h"
#import "PFMultiProcessFileLockController.h"
#import "PFObjectFileCoder.h"
#import "PFObjectPrivate.h"

@implementation PFObjectFilePersistenceController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithDataSource:(id<PFFileManagerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFFileManagerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Objects
///--------------------------------------

- (BFTask *)loadPersistentObjectAsyncForKey:(NSString *)key {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);

        NSString *path = [self.dataSource.fileManager parseDataItemPathForPathComponent:key];
        [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:path];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:path];
            return nil;
        }

        NSError *error = nil;
        NSData *jsonData = [NSData dataWithContentsOfFile:path
                                                  options:NSDataReadingMappedIfSafe
                                                    error:&error];
        [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:path];

        if (error) {
            return [BFTask taskWithError:error];
        }
        return jsonData;
    }] continueWithSuccessBlock:^id(BFTask *task) {
        NSData *jsonData = task.result;
        if (jsonData) {
            PFObject *object = [PFObjectFileCoder objectFromData:jsonData usingDecoder:[PFDecoder objectDecoder]];
            return object;
        }

        return nil;
    }];
}

- (BFTask *)persistObjectAsync:(PFObject *)object forKey:(NSString *)key {
    @weakify(self);
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);

        NSData *data = [PFObjectFileCoder dataFromObject:object usingEncoder:[PFPointerObjectEncoder objectEncoder]];

        NSString *filePath = [self.dataSource.fileManager parseDataItemPathForPathComponent:key];
        [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:filePath];

        return [[PFFileManager writeDataAsync:data toFile:filePath] continueWithBlock:^id(BFTask *task) {
            [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:filePath];
            return nil;
        }];
    }];
}

@end
