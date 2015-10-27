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

@class BFTask PF_GENERIC(__covariant BFGenericType);

@interface PFCloudCodeController : NSObject

@property (nonatomic, strong, readonly) id<PFCommandRunnerProvider> dataSource;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider>)dataSource;

///--------------------------------------
/// @name Cloud Functions
///--------------------------------------

/*!
 Calls a Cloud Code function and returns a result of it's execution.

 @param functionName Function name to call.
 @param parameters   Parameters to pass. (can't be nil).
 @param sessionToken Session token to use.

 @returns `BFTask` with a result set to a result of Cloud Function.
 */
- (BFTask *)callCloudCodeFunctionAsync:(NSString *)functionName
                        withParameters:(NSDictionary *)parameters
                          sessionToken:(NSString *)sessionToken;

@end
