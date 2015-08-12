/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFProductsRequestHandler.h"

#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>

@implementation PFProductsRequestResult

- (instancetype)initWithProductsResponse:(SKProductsResponse *)response {
    self = [super init];
    if (!self) return nil;

    _validProducts = [NSSet setWithArray:response.products];
    _invalidProductIdentifiers = [NSSet setWithArray:response.invalidProductIdentifiers];

    return self;
}

@end

@interface PFProductsRequestHandler () <SKProductsRequestDelegate>

@property (nonatomic, strong) BFTaskCompletionSource *taskCompletionSource;
@property (nonatomic, strong) SKProductsRequest *productsRequest;

@end

@implementation PFProductsRequestHandler

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithProductsRequest:(SKProductsRequest *)request {
    self = [super init];
    if (!self) return nil;

    _productsRequest = request;
    _productsRequest.delegate = self;

    return self;
}

///--------------------------------------
#pragma mark - Dealloc
///--------------------------------------

- (void)dealloc {
    // Clear the delegate, as it's still an `assign`, instead of `weak`
    _productsRequest.delegate = nil;
}

///--------------------------------------
#pragma mark - Find
///--------------------------------------

- (BFTask *)findProductsAsync {
    _taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [_productsRequest start];
    return _taskCompletionSource.task;
}

///--------------------------------------
#pragma mark - SKProductsRequestDelegate
///--------------------------------------

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    PFProductsRequestResult *result = [[PFProductsRequestResult alloc] initWithProductsResponse:response];
    [self.taskCompletionSource trySetResult:result];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    [self.taskCompletionSource trySetError:error];

    // according to documentation, this method does not call requestDidFinish
    request.delegate = nil;
}

- (void)requestDidFinish:(SKRequest *)request {
    // the documentation assures that this is the point safe to get rid of the request
    request.delegate = nil;
}

@end
