/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFInstallationIdentifierStore.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFFileManager.h"
#import "PFInternalUtils.h"
#import "PFMacros.h"
#import "PFMultiProcessFileLockController.h"
#import "Parse_Private.h"

static NSString *const PFInstallationIdentifierFileName = @"installationId";

@interface PFInstallationIdentifierStore () {
    dispatch_queue_t _synchronizationQueue;
    PFFileManager *_fileManager;
}

@property (nonatomic, copy, readwrite) NSString *installationIdentifier;
@property (nonatomic, copy, readonly) NSString *installationIdentifierFilePath;

@end

@implementation PFInstallationIdentifierStore

@synthesize installationIdentifier = _installationIdentifier;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithFileManager:(PFFileManager *)fileManager {
    self = [super init];
    if (!self) return nil;

    _synchronizationQueue = dispatch_queue_create("com.parse.installationIdentifier", DISPATCH_QUEUE_SERIAL);
    PFMarkDispatchQueue(_synchronizationQueue);

    _fileManager = fileManager;

    return self;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (NSString *)installationIdentifier {
    __block NSString *identifier = nil;
    dispatch_sync(_synchronizationQueue, ^{
        if (!_installationIdentifier) {
            [self _loadInstallationIdentifier];
        }

        identifier = _installationIdentifier;
    });
    return identifier;
}

- (void)setInstallationIdentifier:(NSString *)installationIdentifier {
    PFAssertIsOnDispatchQueue(_synchronizationQueue);
    if (_installationIdentifier != installationIdentifier) {
        _installationIdentifier = [installationIdentifier copy];
    }
}

- (void)clearInstallationIdentifier {
    dispatch_sync(_synchronizationQueue, ^{
        NSString *filePath = self.installationIdentifierFilePath;
        [[PFFileManager removeItemAtPathAsync:filePath] waitForResult:nil withMainThreadWarning:NO];

        self.installationIdentifier = nil;
    });
}

///--------------------------------------
#pragma mark - Disk Operations
///--------------------------------------

- (void)_loadInstallationIdentifier {
    PFAssertIsOnDispatchQueue(_synchronizationQueue);

    NSString *filePath = self.installationIdentifierFilePath;
    [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:filePath];

    NSString *identifier = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    if (!identifier) {
        identifier = [[[NSUUID UUID] UUIDString] lowercaseString];
        [[PFFileManager writeStringAsync:identifier toFile:filePath] waitForResult:nil withMainThreadWarning:NO];
    }
    self.installationIdentifier = identifier;

    [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:filePath];
}

- (void)_clearCachedInstallationIdentifier {
    dispatch_sync(_synchronizationQueue, ^{
        self.installationIdentifier = nil;
    });
}

- (NSString *)installationIdentifierFilePath {
    return [_fileManager parseDataItemPathForPathComponent:PFInstallationIdentifierFileName];
}

@end
