/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPurchaseController.h"

#import <StoreKit/StoreKit.h>

#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFConstants.h"
#import "PFDecoder.h"
#import "PFFileManager.h"
#import "PFFile_Private.h"
#import "PFHTTPRequest.h"
#import "PFMacros.h"
#import "PFPaymentTransactionObserver.h"
#import "PFProductsRequestHandler.h"
#import "PFRESTCommand.h"

@interface PFPurchaseController () {
    PFProductsRequestHandler *_currentProductsRequestHandler;
}

@end

@implementation PFPurchaseController

@synthesize paymentQueue = _paymentQueue;
@synthesize transactionObserver = _transactionObserver;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithCommandRunner:(id<PFCommandRunning>)commandRunner
                          fileManager:(PFFileManager *)fileManager
                               bundle:(NSBundle *)bundle {
    self = [super init];
    if (!self) return nil;

    _commandRunner = commandRunner;
    _fileManager = fileManager;
    _bundle = bundle;

    return self;
}

+ (instancetype)controllerWithCommandRunner:(id<PFCommandRunning>)commandRunner
                                fileManager:(PFFileManager *)fileManager
                                     bundle:(NSBundle *)bundle {
    return [[self alloc] initWithCommandRunner:commandRunner fileManager:fileManager bundle:bundle];
}

///--------------------------------------
#pragma mark - Dealloc
///--------------------------------------

- (void)dealloc {
    if (_paymentQueue && _transactionObserver) {
        [_paymentQueue removeTransactionObserver:_transactionObserver];
    }
}

///--------------------------------------
#pragma mark - Products
///--------------------------------------

- (BFTask *)findProductsAsyncWithIdentifiers:(NSSet *)productIdentifiers {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id {
        @strongify(self);
        Class requestClass = self.productsRequestClass ?: [SKProductsRequest class];
        SKProductsRequest *request = [[requestClass alloc] initWithProductIdentifiers:productIdentifiers];
        _currentProductsRequestHandler = [[PFProductsRequestHandler alloc] initWithProductsRequest:request];
        return [_currentProductsRequestHandler findProductsAsync];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        _currentProductsRequestHandler = nil;
        return task;
    }];
}

- (BFTask *)buyProductAsyncWithIdentifier:(NSString *)productIdentifier {
    PFParameterAssert(productIdentifier, @"You must pass in a valid product identifier.");

    if (![self canPurchase]) {
        NSError *error = [NSError errorWithDomain:PFParseErrorDomain
                                             code:kPFErrorPaymentDisabled
                                         userInfo:nil];
        return [BFTask taskWithError:error];
    }
    NSSet *identifiers = PF_SET(productIdentifier);
    @weakify(self);
    return [[self findProductsAsyncWithIdentifiers:identifiers] continueWithSuccessBlock:^id(BFTask *task) {
        PFProductsRequestResult *result = task.result;
        @strongify(self);

        for (NSString *invalidIdentifier in result.invalidProductIdentifiers) {
            if ([invalidIdentifier isEqualToString:productIdentifier]) {
                return [BFTask taskWithError:[NSError errorWithDomain:PFParseErrorDomain
                                                                 code:kPFErrorInvalidProductIdentifier
                                                             userInfo:nil]];
            }
        }

        for (SKProduct *product in result.validProducts) {
            if ([product.productIdentifier isEqualToString:productIdentifier]) {
                BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
                [self.transactionObserver handle:productIdentifier runOnceBlock:^(NSError *error) {
                    if (error) {
                        [source trySetError:error];
                    } else {
                        [source trySetResult:nil];
                    }
                }];
                SKPayment *payment = [SKPayment paymentWithProduct:product];
                [self.paymentQueue addPayment:payment];
                return source.task;
            }
        }

        return [BFTask taskWithError:[NSError errorWithDomain:PFParseErrorDomain
                                                         code:kPFErrorProductNotFoundInAppStore
                                                     userInfo:nil]];
    }];
}

- (BFTask *)downloadAssetAsyncForTransaction:(SKPaymentTransaction *)transaction
                           withProgressBlock:(PFProgressBlock)progressBlock
                                sessionToken:(NSString *)sessionToken {
    NSString *productIdentifier = transaction.payment.productIdentifier;
    NSURL *appStoreReceiptURL = [self.bundle appStoreReceiptURL];
    if (!productIdentifier || !appStoreReceiptURL) {
        return [BFTask taskWithError:[NSError errorWithDomain:PFParseErrorDomain
                                                         code:kPFErrorReceiptMissing
                                                     userInfo:nil]];
    }

    NSError *error = nil;
    NSData *appStoreReceipt = [NSData dataWithContentsOfURL:appStoreReceiptURL
                                                    options:NSDataReadingMappedIfSafe
                                                      error:&error];
    if (!appStoreReceipt || error) {
        NSDictionary *userInfo = nil;
        if (error) {
            userInfo = @{ NSUnderlyingErrorKey : error };
        }
        return [BFTask taskWithError:[NSError errorWithDomain:PFParseErrorDomain
                                                         code:kPFErrorReceiptMissing
                                                     userInfo:userInfo]];
    }

    NSDictionary *params = [[PFEncoder objectEncoder] encodeObject:@{ @"receipt" : appStoreReceipt,
                                                                      @"productIdentifier" : productIdentifier }];
    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"validate_purchase"
                                                     httpMethod:PFHTTPRequestMethodPOST
                                                     parameters:params
                                                   sessionToken:sessionToken];
    BFTask *task = [self.commandRunner runCommandAsync:command withOptions:PFCommandRunningOptionRetryIfFailed];
    @weakify(self);
    return [task continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);

        PFCommandResult *result = task.result;
        PFFile *file = [[PFDecoder objectDecoder] decodeObject:result.result];
        if (![file isKindOfClass:[PFFile class]]) {
            return [BFTask taskWithError:[NSError errorWithDomain:PFParseErrorDomain
                                                             code:kPFErrorInvalidPurchaseReceipt
                                                         userInfo:result.result]];
        }

        NSString *finalFilePath = [self assetContentPathForProductWithIdentifier:transaction.payment.productIdentifier
                                                                        fileName:file.name];
        NSString *directoryPath = [finalFilePath stringByDeletingLastPathComponent];
        return [[[[[PFFileManager createDirectoryIfNeededAsyncAtPath:directoryPath] continueWithBlock:^id(BFTask *task) {
            if (task.faulted) {
                return [BFTask taskWithError:[NSError errorWithDomain:PFParseErrorDomain
                                                                 code:kPFErrorProductDownloadFileSystemFailure
                                                             userInfo:nil]];
            }
            return file;
        }] continueWithSuccessBlock:^id(BFTask *task) {
            return [file getDataStreamInBackgroundWithProgressBlock:progressBlock];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            NSString *cachedFilePath = [file _cachedFilePath];
            return [[PFFileManager copyItemAsyncAtPath:cachedFilePath
                                                toPath:finalFilePath] continueWithBlock:^id(BFTask *task) {
                // No-op file exists error.
                if (task.error.code == NSFileWriteFileExistsError) {
                    return nil;
                }
                return task;
            }];
        }] continueWithSuccessResult:finalFilePath];
    }];
}

- (NSString *)assetContentPathForProductWithIdentifier:(NSString *)identifier fileName:(NSString *)fileName {
    // We store files locally at (ParsePrivateDir)/(ProductIdentifier)/filename
    NSString *filePath = [self.fileManager parseDataItemPathForPathComponent:identifier];
    filePath = [filePath stringByAppendingPathComponent:fileName];
    return filePath;
}

- (BOOL)canPurchase {
    return [[self.paymentQueue class] canMakePayments];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (SKPaymentQueue *)paymentQueue {
    if (!_paymentQueue) {
        _paymentQueue = [SKPaymentQueue defaultQueue];
    }
    return _paymentQueue;
}

- (PFPaymentTransactionObserver *)transactionObserver {
    if (!_transactionObserver) {
        _transactionObserver = [[PFPaymentTransactionObserver alloc] init];
        [self.paymentQueue addTransactionObserver:_transactionObserver];
    }
    return _transactionObserver;
}

@end
