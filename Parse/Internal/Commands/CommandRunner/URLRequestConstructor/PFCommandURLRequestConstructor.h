/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

#import "PFDataProvider.h"

@class BFTask<__covariant BFGenericType>;
@class PFRESTCommand;

NS_ASSUME_NONNULL_BEGIN

@interface PFCommandURLRequestConstructor : NSObject

@property (nonatomic, weak, readonly) id<PFInstallationIdentifierStoreProvider> dataSource;
@property (nonatomic, strong, readonly) NSURL *serverURL;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)constructorWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource serverURL:(NSURL *)serverURL;

///--------------------------------------
#pragma mark - Data
///--------------------------------------

- (BFTask<NSURLRequest *> *)getDataURLRequestAsyncForCommand:(PFRESTCommand *)command;

///--------------------------------------
#pragma mark - File Upload
///--------------------------------------

- (BFTask<NSURLRequest *> *)getFileUploadURLRequestAsyncForCommand:(PFRESTCommand *)command
                                                   withContentType:(NSString *)contentType
                                             contentSourceFilePath:(NSString *)contentFilePath;

///--------------------------------------
#pragma mark - Headers
///--------------------------------------

+ (NSDictionary *)defaultURLRequestHeadersForApplicationId:(NSString *)applicationId
                                                 clientKey:(nullable NSString *)clientKey
                                                    bundle:(NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
