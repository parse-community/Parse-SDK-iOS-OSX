/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCommandURLRequestConstructor.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandRunningConstants.h"
#import "PFDevice.h"
#import "PFHTTPRequest.h"
#import "PFHTTPURLRequestConstructor.h"
#import "PFInstallationIdentifierStore.h"
#import "PFInternalUtils.h"
#import "PFRESTCommand.h"
#import "PFURLConstructor.h"
#import "Parse_Private.h"

@implementation PFCommandURLRequestConstructor

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource serverURL:(NSURL *)serverURL {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;
    _serverURL = serverURL;

    return self;
}

+ (instancetype)constructorWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource serverURL:(NSURL *)serverURL {
    return [[self alloc] initWithDataSource:dataSource serverURL:serverURL];
}

///--------------------------------------
#pragma mark - Data
///--------------------------------------

- (BFTask<NSURLRequest *> *)getDataURLRequestAsyncForCommand:(PFRESTCommand *)command {
    return (BFTask *)[[self _getURLRequestHeadersAsyncForCommand:command] continueWithSuccessBlock:^id(BFTask<NSDictionary *> *task) {
        NSURL *url = [PFURLConstructor URLFromAbsoluteString:self.serverURL.absoluteString
                                                        path:command.httpPath
                                                       query:nil];
        NSDictionary *headers = task.result;

        NSString *requestMethod = command.httpMethod;
        NSDictionary *requestParameters = nil;
        if (command.parameters) {
            NSDictionary *parameters = nil;

            // The request URI may be too long to include parameters in the URI.
            // To avoid this problem we send the parameters in a POST request json-encoded body
            // and add a custom parameter that overrides the method in a request.
            if ([requestMethod isEqualToString:PFHTTPRequestMethodGET] ||
                [requestMethod isEqualToString:PFHTTPRequestMethodHEAD] ||
                [requestMethod isEqualToString:PFHTTPRequestMethodDELETE]) {
                NSMutableDictionary *mutableParameters = [command.parameters mutableCopy];
                mutableParameters[PFCommandParameterNameMethodOverride] = command.httpMethod;

                requestMethod = PFHTTPRequestMethodPOST;
                parameters = [mutableParameters copy];
            } else {
                parameters = command.parameters;
            }
            requestParameters = [[PFPointerObjectEncoder objectEncoder] encodeObject:parameters];
        }

        return [PFHTTPURLRequestConstructor urlRequestWithURL:url
                                                   httpMethod:requestMethod
                                                  httpHeaders:headers
                                                   parameters:requestParameters];
    }];
}

///--------------------------------------
#pragma mark - File
///--------------------------------------

- (BFTask<NSURLRequest *> *)getFileUploadURLRequestAsyncForCommand:(PFRESTCommand *)command
                                                   withContentType:(NSString *)contentType
                                             contentSourceFilePath:(NSString *)contentFilePath {
    return [[self getDataURLRequestAsyncForCommand:command] continueWithSuccessBlock:^id(BFTask<NSURLRequest *> *task) {
        NSMutableURLRequest *request = [task.result mutableCopy];

        if (contentType) {
            [request setValue:contentType forHTTPHeaderField:PFHTTPRequestHeaderNameContentType];
        }

        NSURL *fileURL = [NSURL fileURLWithPath:contentFilePath];
        NSNumber *fileSize = nil;
        NSError *error = nil;
        [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        if (fileSize) {
            [request setValue:fileSize.stringValue forHTTPHeaderField:PFHTTPRequestHeaderNameContentLength];
        }

        return request;
    }];
}

///--------------------------------------
#pragma mark - Headers
///--------------------------------------

+ (NSDictionary *)defaultURLRequestHeadersForApplicationId:(NSString *)applicationId
                                                 clientKey:(NSString *)clientKey
                                                    bundle:(NSBundle *)bundle {
#if TARGET_OS_IOS
    NSString *versionPrefix = @"i";
#elif PF_TARGET_OS_OSX
    NSString *versionPrefix = @"osx";
#elif TARGET_OS_TV
    NSString *versionPrefix = @"apple-tv";
#elif TARGET_OS_WATCH
    NSString *versionPrefix = @"apple-watch";
#endif

    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];

    mutableHeaders[PFCommandHeaderNameApplicationId] = applicationId;
    mutableHeaders[PFCommandHeaderNameClientKey] = clientKey;

    mutableHeaders[PFCommandHeaderNameClientVersion] = [versionPrefix stringByAppendingString:PARSE_VERSION];
    mutableHeaders[PFCommandHeaderNameOSVersion] = [PFDevice currentDevice].operatingSystemFullVersion;

    // Bundle Version and Display Version can be null, when running tests
    NSString *bundleVersion = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    if (bundleVersion) {
        mutableHeaders[PFCommandHeaderNameAppBuildVersion] = bundleVersion;
    }
    NSString *displayVersion = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (displayVersion) {
        mutableHeaders[PFCommandHeaderNameAppDisplayVersion] = displayVersion;
    }

    return [mutableHeaders copy];
}

- (BFTask<NSDictionary *> *)_getURLRequestHeadersAsyncForCommand:(PFRESTCommand *)command {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id {
        NSMutableDictionary *headers = [NSMutableDictionary dictionary];
        [headers addEntriesFromDictionary:command.additionalRequestHeaders];
        if (command.sessionToken) {
            headers[PFCommandHeaderNameSessionToken] = command.sessionToken;
        }
        return [[self.dataSource.installationIdentifierStore getInstallationIdentifierAsync] continueWithSuccessBlock:^id(BFTask <NSString *>*task) {
            headers[PFCommandHeaderNameInstallationId] = task.result;
            return [headers copy];
        }];
    }];
}

@end
