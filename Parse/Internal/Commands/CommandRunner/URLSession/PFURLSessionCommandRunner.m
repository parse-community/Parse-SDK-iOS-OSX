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

@interface PFURLSessionCommandRunner () <PFURLSessionDelegate>

@property (nonatomic, strong) NSNotificationCenter *notificationCenter;
@property (nonatomic, assign) NSUInteger retryAttempts;

@end

@implementation PFURLSessionCommandRunner

@synthesize applicationId = _applicationId;
@synthesize clientKey = _clientKey;
@synthesize serverURL = _serverURL;
@synthesize initialRetryDelay = _initialRetryDelay;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                     applicationId:(NSString *)applicationId
                         clientKey:(nullable NSString *)clientKey
                         serverURL:(NSURL *)serverURL {
    return [self initWithDataSource:dataSource
                      retryAttempts:PFCommandRunningDefaultMaxAttemptsCount
                      applicationId:applicationId
                          clientKey:clientKey
                          serverURL:serverURL];
}

- (instancetype)initWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                     retryAttempts:(NSUInteger)retryAttempts
                     applicationId:(NSString *)applicationId
                         clientKey:(nullable NSString *)clientKey
                         serverURL:(NSURL *)serverURL {
    NSURLSessionConfiguration *configuration = [[self class] _urlSessionConfigurationForApplicationId:applicationId clientKey:clientKey];

    PFURLSession *session = [PFURLSession sessionWithConfiguration:configuration delegate:self];
    PFCommandURLRequestConstructor *constructor = [PFCommandURLRequestConstructor constructorWithDataSource:dataSource serverURL:serverURL];
    self = [self initWithDataSource:dataSource
                            session:session
                 requestConstructor:constructor
                 notificationCenter:[NSNotificationCenter defaultCenter]];
    if (!self) return nil;

    _retryAttempts = retryAttempts;
    _applicationId = [applicationId copy];
    _clientKey = [clientKey copy];
    _serverURL = serverURL;

    return self;
}

- (instancetype)initWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                           session:(PFURLSession *)session
                requestConstructor:(PFCommandURLRequestConstructor *)requestConstructor
                notificationCenter:(NSNotificationCenter *)notificationCenter {
    self = [super init];
    if (!self) return nil;

    _initialRetryDelay = PFCommandRunningDefaultRetryDelay;
    _retryAttempts = PFCommandRunningDefaultMaxAttemptsCount;

    _requestConstructor = requestConstructor;
    _session = session;
    _notificationCenter = notificationCenter;

    return self;
}

+ (instancetype)commandRunnerWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                              applicationId:(NSString *)applicationId
                                  clientKey:(nullable NSString *)clientKey
                                  serverURL:(nonnull NSURL *)serverURL {
    return [[self alloc] initWithDataSource:dataSource applicationId:applicationId clientKey:clientKey serverURL:serverURL];
}

+ (instancetype)commandRunnerWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                              retryAttempts:(NSUInteger)retryAttempts
                              applicationId:(NSString *)applicationId
                                  clientKey:(nullable NSString *)clientKey
                                  serverURL:(nonnull NSURL *)serverURL {
    return [[self alloc] initWithDataSource:dataSource
                              retryAttempts:retryAttempts
                              applicationId:applicationId
                                  clientKey:clientKey
                                  serverURL:serverURL];
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

- (BFTask<PFCommandResult *> *)runCommandAsync:(PFRESTCommand *)command withOptions:(PFCommandRunningOptions)options {
    return [self runCommandAsync:command withOptions:options cancellationToken:nil];
}

- (BFTask<PFCommandResult *> *)runCommandAsync:(PFRESTCommand *)command
                                   withOptions:(PFCommandRunningOptions)options
                             cancellationToken:(BFCancellationToken *)cancellationToken {
    return [self _performCommandRunningBlock:^id {
        [command resolveLocalIds];
        return [[self.requestConstructor getDataURLRequestAsyncForCommand:command] continueWithSuccessBlock:^id(BFTask <NSURLRequest *>*task) {
            return [_session performDataURLRequestAsync:task.result forCommand:command cancellationToken:cancellationToken];
        }];
    } withOptions:options cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - File Commands
///--------------------------------------

- (BFTask<PFCommandResult *> *)runFileUploadCommandAsync:(PFRESTCommand *)command
                                         withContentType:(NSString *)contentType
                                   contentSourceFilePath:(NSString *)sourceFilePath
                                                 options:(PFCommandRunningOptions)options
                                       cancellationToken:(nullable BFCancellationToken *)cancellationToken
                                           progressBlock:(nullable PFProgressBlock)progressBlock {
    @weakify(self);
    return [self _performCommandRunningBlock:^id {
        @strongify(self);

        [command resolveLocalIds];
        return [[self.requestConstructor getFileUploadURLRequestAsyncForCommand:command
                                                                withContentType:contentType
                                                          contentSourceFilePath:sourceFilePath] continueWithSuccessBlock:^id(BFTask<NSURLRequest *> *task) {
            return [_session performFileUploadURLRequestAsync:task.result
                                                   forCommand:command
                                    withContentSourceFilePath:sourceFilePath
                                            cancellationToken:cancellationToken
                                                progressBlock:progressBlock];
        }];
    } withOptions:options cancellationToken:cancellationToken];
}

- (BFTask<PFCommandResult *> *)runFileDownloadCommandAsyncWithFileURL:(NSURL *)url
                                                       targetFilePath:(NSString *)filePath
                                                    cancellationToken:(nullable BFCancellationToken *)cancellationToken
                                                        progressBlock:(nullable PFProgressBlock)progressBlock {
    return [self _performCommandRunningBlock:^id {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        return [_session performFileDownloadURLRequestAsync:request
                                               toFileAtPath:filePath
                                      withCancellationToken:cancellationToken
                                              progressBlock:progressBlock];
    } withOptions:PFCommandRunningOptionRetryIfFailed
                           cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - Retrying
///--------------------------------------

- (BFTask *)_performCommandRunningBlock:(nonnull id (^)(void))block
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
                                 forAttempts:_retryAttempts];
}

- (BFTask *)_performCommandRunningBlock:(nonnull id (^)(void))block
                  withCancellationToken:(BFCancellationToken *)cancellationToken
                                  delay:(NSTimeInterval)delay
                            forAttempts:(NSUInteger)attempts {
    @weakify(self);
    return [block() continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        if (task.cancelled) {
            return task;
        }

        if ([task.error.userInfo[@"temporary"] boolValue] && attempts > 1) {
            PFLogError(PFLoggingTagCommon,
                       @"Network connection failed. Making attempt %lu after sleeping for %f seconds.",
                       (unsigned long)(_retryAttempts - attempts + 1), (double)delay);

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
                                                              clientKey:(nullable NSString *)clientKey {
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

///--------------------------------------
#pragma mark - PFURLSessionDelegate
///--------------------------------------

- (void)urlSession:(PFURLSession *)session willPerformURLRequest:(NSURLRequest *)request {
    [[BFExecutor defaultPriorityBackgroundExecutor] execute:^{
        NSDictionary *userInfo = ([PFLogger sharedLogger].logLevel == PFLogLevelDebug ?
                                  @{ PFNetworkNotificationURLRequestUserInfoKey : request } : nil);
        [self.notificationCenter postNotificationName:PFNetworkWillSendURLRequestNotification
                                               object:self
                                             userInfo:userInfo];
    }];
}

- (void)urlSession:(PFURLSession *)session
didPerformURLRequest:(NSURLRequest *)request
   withURLResponse:(nullable NSURLResponse *)response
    responseString:(nullable NSString *)responseString {
    [[BFExecutor defaultPriorityBackgroundExecutor] execute:^{
        NSMutableDictionary *userInfo = nil;
        if ([PFLogger sharedLogger].logLevel == PFLogLevelDebug) {
            userInfo = [NSMutableDictionary dictionaryWithObject:request
                                                          forKey:PFNetworkNotificationURLRequestUserInfoKey];
            if (response) {
                userInfo[PFNetworkNotificationURLResponseUserInfoKey] = response;
            }
            if (responseString) {
                userInfo[PFNetworkNotificationURLResponseBodyUserInfoKey] = responseString;
            }
        }
        [self.notificationCenter postNotificationName:PFNetworkDidReceiveURLResponseNotification
                                               object:self
                                             userInfo:userInfo];
    }];
}

@end
