/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSessionCommandRunner.h"
#import "PFURLSessionCommandRunner_Private.h"

#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunningConstants.h"
#import "PFCommandURLRequestConstructor.h"
#import "PFConstants.h"
#import "PFDevice.h"
#import "PFEncoder.h"
#import "PFHTTPRequest.h"
#import "PFHTTPURLRequestConstructor.h"
#import "PFInstallationIdentifierStore.h"
#import "PFInternalUtils.h"
#import "PFLogging.h"
#import "PFMacros.h"
#import "PFRESTCommand.h"
#import "PFURLConstructor.h"
#import "PFURLSession.h"

@implementation PFURLSessionCommandRunner

@synthesize applicationId = _applicationId;
@synthesize clientKey = _clientKey;
@synthesize initialRetryDelay = _initialRetryDelay;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                     applicationId:(NSString *)applicationId
                         clientKey:(NSString *)clientKey {
    NSURLSessionConfiguration *configuration = [[self class] _urlSessionConfigurationForApplicationId:applicationId
                                                                                            clientKey:clientKey];
    PFURLSession *session = [PFURLSession sessionWithConfiguration:configuration];
    PFCommandURLRequestConstructor *constructor = [PFCommandURLRequestConstructor constructorWithDataSource:dataSource];
    self = [self initWithDataSource:dataSource
                            session:session
                 requestConstructor:constructor];
    if (!self) return nil;

    _applicationId = [applicationId copy];
    _clientKey = [clientKey copy];

    return self;
}

- (instancetype)initWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                           session:(PFURLSession *)session
                requestConstructor:(PFCommandURLRequestConstructor *)requestConstructor {
    self = [super init];
    if (!self) return nil;

    _initialRetryDelay = PFCommandRunningDefaultRetryDelay;

    _requestConstructor = requestConstructor;
    _session = session;

    return self;
}

+ (instancetype)commandRunnerWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                              applicationId:(NSString *)applicationId
                                  clientKey:(NSString *)clientKey {
    return [[self alloc] initWithDataSource:dataSource applicationId:applicationId clientKey:clientKey];
}

///--------------------------------------
#pragma mark - Dealloc
///--------------------------------------

- (void)dealloc {
    // This is required to call, since session will continue to be present in memory and running otherwise.
    [_session invalidateAndCancel];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (id<PFInstallationIdentifierStoreProvider>)dataSource {
    return _requestConstructor.dataSource;
}

///--------------------------------------
#pragma mark - Data Commands
///--------------------------------------

- (BFTask *)runCommandAsync:(PFRESTCommand *)command withOptions:(PFCommandRunningOptions)options {
    return [self runCommandAsync:command withOptions:options cancellationToken:nil];
}

- (BFTask *)runCommandAsync:(PFRESTCommand *)command
                withOptions:(PFCommandRunningOptions)options
          cancellationToken:(BFCancellationToken *)cancellationToken {
    return [self _performCommandRunningBlock:^id{
        [command resolveLocalIds];
        NSURLRequest *request = [self.requestConstructor dataURLRequestForCommand:command];
        return [_session performDataURLRequestAsync:request forCommand:command cancellationToken:cancellationToken];
    } withOptions:options cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - File Commands
///--------------------------------------

- (BFTask *)runFileUploadCommandAsync:(PFRESTCommand *)command
                      withContentType:(NSString *)contentType
                contentSourceFilePath:(NSString *)sourceFilePath
                              options:(PFCommandRunningOptions)options
                    cancellationToken:(nullable BFCancellationToken *)cancellationToken
                        progressBlock:(nullable PFProgressBlock)progressBlock {
    @weakify(self);
    return [self _performCommandRunningBlock:^id{
        @strongify(self);

        [command resolveLocalIds];
        NSURLRequest *request = [self.requestConstructor fileUploadURLRequestForCommand:command
                                                                        withContentType:contentType
                                                                  contentSourceFilePath:sourceFilePath];
        return [_session performFileUploadURLRequestAsync:request
                                               forCommand:command
                                withContentSourceFilePath:sourceFilePath
                                        cancellationToken:cancellationToken
                                            progressBlock:progressBlock];

    } withOptions:options cancellationToken:cancellationToken];
}

- (BFTask *)runFileDownloadCommandAsyncWithFileURL:(NSURL *)url
                                    targetFilePath:(NSString *)filePath
                                 cancellationToken:(nullable BFCancellationToken *)cancellationToken
                                     progressBlock:(nullable PFProgressBlock)progressBlock {
    return [self _performCommandRunningBlock:^id{
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        return [_session performFileDownloadURLRequestAsync:request
                                               toFileAtPath:filePath
                                      withCancellationToken:cancellationToken
                                              progressBlock:progressBlock];
    } withOptions:PFCommandRunningOptionRetryIfFailed cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - Retrying
///--------------------------------------

- (BFTask *)_performCommandRunningBlock:(nonnull id (^)())block
                            withOptions:(PFCommandRunningOptions)options
                      cancellationToken:(BFCancellationToken *)cancellationToken {
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }

    if (!(options & PFCommandRunningOptionRetryIfFailed)) {
        return block();
    }

    NSTimeInterval delay = self.initialRetryDelay; // Delay (secs) of next retry attempt

    // Set the initial delay to something between 1 and 2 seconds. We want it to be
    // random so that clients that fail simultaneously don't retry on simultaneous
    // intervals.
    delay += self.initialRetryDelay * ((double)(arc4random() & 0x0FFFF) / (double)0x0FFFF);
    return [self _performCommandRunningBlock:block
                       withCancellationToken:cancellationToken
                                       delay:delay
                                 forAttempts:PFCommandRunningDefaultMaxAttemptsCount];
}

- (BFTask *)_performCommandRunningBlock:(nonnull id (^)())block
                  withCancellationToken:(BFCancellationToken *)cancellationToken
                                  delay:(NSTimeInterval)delay
                            forAttempts:(NSUInteger)attempts {
    @weakify(self);
    return [block() continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        if (task.cancelled) {
            return task;
        }

        if ([[task.error userInfo][@"temporary"] boolValue] && attempts > 1) {
            PFLogError(PFLoggingTagCommon,
                       @"Network connection failed. Making attempt %lu after sleeping for %f seconds.",
                       (unsigned long)(PFCommandRunningDefaultMaxAttemptsCount - attempts + 1), (double)delay);

            return [[BFTask taskWithDelay:(int)(delay * 1000)] continueWithBlock:^id(BFTask *task) {
                return [self _performCommandRunningBlock:block
                                   withCancellationToken:cancellationToken
                                                   delay:delay * 2.0
                                             forAttempts:attempts - 1];
            } cancellationToken:cancellationToken];
        }
        return task;
    } cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - NSURLSessionConfiguration
///--------------------------------------

+ (NSURLSessionConfiguration *)_urlSessionConfigurationForApplicationId:(NSString *)applicationId
                                                              clientKey:(NSString *)clientKey {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

    // No cookies, they are bad for you.
    configuration.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
    configuration.HTTPShouldSetCookies = NO;

    // Completely disable caching of responses for security reasons.
    configuration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:[NSURLCache sharedURLCache].memoryCapacity
                                                           diskCapacity:0
                                                               diskPath:nil];

    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *headers = [PFCommandURLRequestConstructor defaultURLRequestHeadersForApplicationId:applicationId
                                                                                           clientKey:clientKey
                                                                                              bundle:bundle];
    configuration.HTTPAdditionalHeaders = headers;

    return configuration;
}

@end
