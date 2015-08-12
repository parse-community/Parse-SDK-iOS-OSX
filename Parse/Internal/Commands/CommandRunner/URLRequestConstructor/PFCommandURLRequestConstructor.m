/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCommandURLRequestConstructor.h"

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

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    return self;
}

+ (instancetype)constructorWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Data
///--------------------------------------

- (NSURLRequest *)dataURLRequestForCommand:(PFRESTCommand *)command {
    NSURL *url = [PFURLConstructor URLFromBaseURL:[NSURL URLWithString:[PFInternalUtils parseServerURLString]]
                                             path:[NSString stringWithFormat:@"/1/%@", command.httpPath]];
    NSDictionary *headers = [self _URLRequestHeadersForCommand:command];

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
}

///--------------------------------------
#pragma mark - File
///--------------------------------------

- (NSURLRequest *)fileUploadURLRequestForCommand:(PFRESTCommand *)command
                                 withContentType:(NSString *)contentType
                           contentSourceFilePath:(NSString *)contentFilePath {
    NSMutableURLRequest *request = [[self dataURLRequestForCommand:command] mutableCopy];

    if (contentType) {
        [request setValue:contentType forHTTPHeaderField:PFHTTPRequestHeaderNameContentType];
    }

    //TODO (nlutsenko): Check for error here.
    NSNumber *fileSize = [PFInternalUtils fileSizeOfFileAtPath:contentFilePath error:nil];
    [request setValue:[fileSize stringValue] forHTTPHeaderField:PFHTTPRequestHeaderNameContentLength];

    return request;
}

///--------------------------------------
#pragma mark - Headers
///--------------------------------------

+ (NSDictionary *)defaultURLRequestHeadersForApplicationId:(NSString *)applicationId
                                                 clientKey:(NSString *)clientKey
                                                    bundle:(NSBundle *)bundle {
#if TARGET_OS_IPHONE
    NSString *versionPrefix = @"i";
#else
    NSString *versionPrefix = @"osx";
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

- (NSDictionary *)_URLRequestHeadersForCommand:(PFRESTCommand *)command {
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    [headers addEntriesFromDictionary:command.additionalRequestHeaders];
    PFInstallationIdentifierStore *installationIdentifierStore = self.dataSource.installationIdentifierStore;
    headers[PFCommandHeaderNameInstallationId] = installationIdentifierStore.installationIdentifier;
    if (command.sessionToken) {
        headers[PFCommandHeaderNameSessionToken] = command.sessionToken;
    }
    return [headers copy];
}

@end
