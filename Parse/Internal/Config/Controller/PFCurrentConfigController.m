/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCurrentConfigController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFConfig_Private.h"
#import "PFDecoder.h"
#import "PFFileManager.h"
#import "PFJSONSerialization.h"

static NSString *const PFConfigCurrentConfigFileName_ = @"config";

@interface PFCurrentConfigController () {
    dispatch_queue_t _dataQueue;
    BFExecutor *_dataExecutor;
    PFConfig *_currentConfig;
}

@property (nonatomic, copy, readonly) NSString *configFilePath;

@end

@implementation PFCurrentConfigController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithFileManager:(PFFileManager *)fileManager {
    self = [super init];
    if (!self) return nil;

    _dataQueue = dispatch_queue_create("com.parse.config.current", DISPATCH_QUEUE_SERIAL);
    _dataExecutor = [BFExecutor executorWithDispatchQueue:_dataQueue];

    _fileManager = fileManager;

    return self;
}

+ (instancetype)controllerWithFileManager:(PFFileManager *)fileManager {
    return [[self alloc] initWithFileManager:fileManager];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (BFTask *)getCurrentConfigAsync {
    return [BFTask taskFromExecutor:_dataExecutor withBlock:^id{
        if (!_currentConfig) {
            NSError *error = nil;
            NSData *jsonData = [NSData dataWithContentsOfFile:self.configFilePath
                                                      options:NSDataReadingMappedIfSafe
                                                        error:&error];
            if (error == nil && [jsonData length] != 0) {
                NSDictionary *dictionary = [PFJSONSerialization JSONObjectFromData:jsonData];
                NSDictionary *decodedDictionary = [[PFDecoder objectDecoder] decodeObject:dictionary];
                _currentConfig = [[PFConfig alloc] initWithFetchedConfig:decodedDictionary];
            } else {
                _currentConfig = [[PFConfig alloc] init];
            }
        }
        return _currentConfig;
    }];
}

- (BFTask *)setCurrentConfigAsync:(PFConfig *)config {
    @weakify(self);
    return [BFTask taskFromExecutor:_dataExecutor withBlock:^id{
        @strongify(self);
        _currentConfig = config;

        NSDictionary *configParameters = @{ PFConfigParametersRESTKey : (config.parametersDictionary ?: @{}) };
        id encodedObject = [[PFPointerObjectEncoder objectEncoder] encodeObject:configParameters];
        NSData *jsonData = [PFJSONSerialization dataFromJSONObject:encodedObject];
        return [PFFileManager writeDataAsync:jsonData toFile:self.configFilePath];
    }];
}

- (BFTask *)clearCurrentConfigAsync {
    @weakify(self);
    return [BFTask taskFromExecutor:_dataExecutor withBlock:^id{
        @strongify(self);
        _currentConfig = nil;
        return [PFFileManager removeItemAtPathAsync:self.configFilePath];
    }];
}

- (BFTask *)clearMemoryCachedCurrentConfigAsync {
    return [BFTask taskFromExecutor:_dataExecutor withBlock:^id{
        _currentConfig = nil;
        return nil;
    }];
}

- (NSString *)configFilePath {
    return [self.fileManager parseDataItemPathForPathComponent:PFConfigCurrentConfigFileName_];
}

@end
