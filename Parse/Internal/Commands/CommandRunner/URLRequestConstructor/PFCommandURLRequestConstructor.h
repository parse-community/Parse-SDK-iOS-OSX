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

@class BFTask PF_GENERIC(BFGenericType);
@class PFRESTCommand;

@interface PFCommandURLRequestConstructor : NSObject

@property (nonatomic, weak, readonly) id<PFInstallationIdentifierStoreProvider> dataSource;
@property (nonatomic, strong, readonly) NSURL *serverURL;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)constructorWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource serverURL:(NSURL *)serverURL;

///--------------------------------------
/// @name Data
///--------------------------------------

- (BFTask PF_GENERIC(NSURLRequest *)*)getDataURLRequestAsyncForCommand:(PFRESTCommand *)command;

///--------------------------------------
/// @name File Upload
///--------------------------------------

- (BFTask PF_GENERIC(NSURLRequest *)*)getFileUploadURLRequestAsyncForCommand:(PFRESTCommand *)command
                                                             withContentType:(NSString *)contentType
                                                       contentSourceFilePath:(NSString *)contentFilePath;

///--------------------------------------
/// @name Headers
///--------------------------------------

+ (NSDictionary *)defaultURLRequestHeadersForApplicationId:(NSString *)applicationId
                                                 clientKey:(NSString *)clientKey
                                                    bundle:(NSBundle *)bundle;

@end
