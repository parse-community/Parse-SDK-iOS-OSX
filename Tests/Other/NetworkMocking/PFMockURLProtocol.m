/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMockURLProtocol.h"

#import "PFTestSwizzlingUtilities.h"

@interface PFMockURLProtocolMock : NSObject

@property (nonatomic, strong) PFMockURLProtocolRequestTestBlock testBlock;
@property (nonatomic, strong) PFMockURLResponseContructingBlock responseBlock;
@property (nonatomic, assign) NSUInteger attempts;

@end

@implementation PFMockURLProtocolMock

@end

///--------------------------------------
#pragma mark - PFMockURLProtocol
///--------------------------------------

@interface PFMockURLProtocol ()

@property (nonatomic, strong) PFMockURLProtocolMock *mock;
@property (nonatomic, assign, getter = isLoading) BOOL loading;

@end

@implementation PFMockURLProtocol

static NSMutableArray *_mocksArray;
static PFTestSwizzledMethod *_swizzledURLSessionMethod;

///--------------------------------------
#pragma mark - Mocking
///--------------------------------------

+ (void)mockRequestsWithResponse:(PFMockURLResponseContructingBlock)constructingBlock {
    return [self mockRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withResponse:constructingBlock];
}

+ (void)mockRequestsPassingTest:(PFMockURLProtocolRequestTestBlock)testBlock
                   withResponse:(PFMockURLResponseContructingBlock)constructingBlock {
    return [self mockRequestsPassingTest:testBlock
                            withResponse:constructingBlock
                             forAttempts:NSUIntegerMax];
}

+ (void)mockRequestsPassingTest:(PFMockURLProtocolRequestTestBlock)testBlock
                   withResponse:(PFMockURLResponseContructingBlock)constructingBlock
                    forAttempts:(NSUInteger)attemptsCount {
    NSParameterAssert(testBlock != nil);
    NSParameterAssert(constructingBlock != nil);

    PFMockURLProtocolMock *mock = [[PFMockURLProtocolMock alloc] init];
    mock.testBlock = testBlock;
    mock.responseBlock = constructingBlock;
    mock.attempts = attemptsCount;

    if (!_mocksArray) {
        _mocksArray = [NSMutableArray array];
    }
    [_mocksArray addObject:mock];

    if (_mocksArray.count == 1) {
        [NSURLProtocol registerClass:self];
        Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: [NSURLSessionConfiguration class];
        _swizzledURLSessionMethod = [PFTestSwizzlingUtilities swizzleMethod:@selector(protocolClasses)
                                                                    inClass:cls
                                                                 withMethod:@selector(protocolClasses)
                                                                    inClass:[self class]];
    }
}

+ (void)removeAllMocking {
    if (_mocksArray) {
        [NSURLProtocol unregisterClass:self];
        _swizzledURLSessionMethod.swizzled = NO;
    }
    [_mocksArray removeAllObjects];
}

+ (PFMockURLProtocolMock *)_firstMockForRequest:(NSURLRequest *)request {
    for (PFMockURLProtocolMock *mock in _mocksArray) {
        if (mock.attempts > 0 && mock.testBlock(request)) {
            return mock;
        }
    }
    return nil;
}

- (NSArray *)protocolClasses {
    return @[[PFMockURLProtocol class]];
}

///--------------------------------------
#pragma mark - NSURLProtocol
///--------------------------------------

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [self _firstMockForRequest:request] != nil;
}

+ (BOOL)canInitWithTask:(NSURLSessionTask *)task {
    return [self _firstMockForRequest:task.originalRequest] != nil;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (instancetype)initWithRequest:(NSURLRequest *)request
                 cachedResponse:(NSCachedURLResponse *)response
                         client:(id<NSURLProtocolClient>)client {
    self = [super initWithRequest:request cachedResponse:response client:client];
    if (self) {
        _mock = [[self class] _firstMockForRequest:request];
    }
    return self;
}

- (instancetype)initWithTask:(NSURLSessionTask *)task
              cachedResponse:(NSCachedURLResponse *)cachedResponse
                      client:(id<NSURLProtocolClient>)client {
    self = [super initWithTask:task cachedResponse:cachedResponse client:client];
    if (!self) return nil;

    _mock = [[self class] _firstMockForRequest:task.originalRequest];

    return self;
}

- (NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)startLoading {
    self.loading = YES;
    self.mock.attempts -= 1;

    NSURLRequest *request = self.request;
    id<NSURLProtocolClient> client = self.client;

    PFMockURLResponse *response = self.mock.responseBlock(request);

    if (response.error) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(response.delay * NSEC_PER_SEC)),
                       dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                       ^{
                           if (self.loading) {
                               [client URLProtocol:self didFailWithError:response.error];
                           }
                       });
        return;
    }

    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                 statusCode:response.statusCode
                                                                HTTPVersion:@"HTTP/1.1"
                                                               headerFields:response.httpHeaders];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(response.delay * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       if (!self.loading) {
                           return;
                       }

                       [client URLProtocol:self
                        didReceiveResponse:urlResponse
                        cacheStoragePolicy:NSURLCacheStorageNotAllowed];

                       if (response.responseData) {
                           [client URLProtocol:self didLoadData:response.responseData];
                       }

                       [client URLProtocolDidFinishLoading:self];
                   });
}

- (void)stopLoading {
    self.loading = NO;
}

@end
