/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import StoreKit;

#import <OCMock/OCMock.h>

@import Bolts.BFExecutor;
@import Bolts.BFTask;

#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFEncoder.h"
#import "PFFileManager.h"
#import "PFFile_Private.h"
#import "PFMacros.h"
#import "PFPaymentTransactionObserver.h"
#import "PFProductsRequestHandler.h"
#import "PFPurchaseController.h"
#import "PFRESTCommand.h"
#import "PFTestSKPaymentTransaction.h"
#import "PFTestSKProduct.h"
#import "PFTestSKProductsRequest.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"
#import "BFTask+Private.h"

@protocol PurchaseControllerDataSource <PFCommandRunnerProvider, PFFileManagerProvider>

@end

@interface PurchaseControllerTests : PFUnitTestCase
@end

@implementation PurchaseControllerTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    PFTestSKProductsRequest.validProducts = PF_SET([self sampleProduct]);
}

- (void)tearDown {
    PFTestSKProductsRequest.validProducts = nil;

    [[NSFileManager defaultManager] removeItemAtPath:[self sampleReceiptFilePath] error:nil];

    [super tearDown];
}

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFCommandRunnerProvider, PFFileManagerProvider>)mockedDataSource {
    id dataSource = PFStrictProtocolMock(@protocol(PurchaseControllerDataSource));
    id commandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    OCMStub([dataSource commandRunner]).andReturn(commandRunner);
    id fileManager = PFStrictClassMock([PFFileManager class]);
    OCMStub([dataSource fileManager]).andReturn(fileManager);
    return dataSource;
}

- (SKProduct *)sampleProduct {
    return [PFTestSKProduct productWithProductIdentifier:@"product"
                                                   price:[NSDecimalNumber decimalNumberWithString:@"13.37"]
                                                   title:@"Fizz"
                                             description:@"FizzBuzz"];
}

- (NSData *)sampleData {
    uint8_t sampleData[16] = {
        0xFF, 0x00, 0xFF, 0x00,
        0xFF, 0x00, 0xFF, 0x00,
        0xFF, 0x00, 0xFF, 0x00,
        0xFF, 0x00, 0xFF, 0x00,
    };

    return [NSData dataWithBytes:sampleData length:sizeof(sampleData)];
}

- (NSString *)sampleReceiptFilePath {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"receipt.data"];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructor {
    id dataSource = [self mockedDataSource];
    id bundle = PFStrictClassMock([NSBundle class]);

    PFPurchaseController *controller = [[PFPurchaseController alloc] initWithDataSource:dataSource bundle:bundle];

    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);
    XCTAssertEqual(controller.bundle, bundle);

    // This makes the test less sad.
    controller.paymentQueue = PFClassMock([SKPaymentQueue class]);

    XCTAssertNotNil(controller.paymentQueue);
    XCTAssertNotNil(controller.transactionObserver);
}

- (void)testFindProductsAsync {
    id dataSource = [self mockedDataSource];
    id bundle = PFStrictClassMock([NSBundle class]);

    PFPurchaseController *purchaseController = [PFPurchaseController controllerWithDataSource:dataSource bundle:bundle];

    purchaseController.productsRequestClass = [PFTestSKProductsRequest class];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[purchaseController findProductsAsyncWithIdentifiers:PF_SET(@"product")] continueWithSuccessBlock:^id(BFTask *task) {
        NSSet *products = [(PFProductsRequestResult *)task.result validProducts];
        XCTAssertEqual(products.count, 1);
        id product = [products anyObject];

        XCTAssertEqualObjects([product productIdentifier], @"product");

        [expectation fulfill];
        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testBuyProductsAsync {
    id dataSource = [self mockedDataSource];
    id bundle = PFStrictClassMock([NSBundle class]);

    PFPurchaseController *purchaseController = [PFPurchaseController controllerWithDataSource:dataSource bundle:bundle];

    purchaseController.productsRequestClass = [PFTestSKProductsRequest class];
    purchaseController.paymentQueue = PFStrictClassMock([SKPaymentQueue class]);

    __block SKPaymentTransaction *transaction = nil;
    SKPaymentQueue *paymentQueue = purchaseController.paymentQueue;

    // Use a block for this so that we don't accidentally force lazy loading of the transaction observer too early.
    // Otherwise it will call addTransactionObserver right away, which will cause us to crash of course.
    OCMStub([paymentQueue addTransactionObserver:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isEqual:purchaseController.transactionObserver];
    }]]);

    OCMStub([paymentQueue finishTransaction:[OCMArg checkWithBlock:^BOOL(id obj) {
        return obj == transaction;
    }]]);

    OCMStub([paymentQueue addPayment:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        // Do stuff
        __unsafe_unretained SKPayment *payment = nil;
        [invocation getArgument:&payment atIndex:2];

        if ([payment.productIdentifier isEqualToString:@"product"]) {
            transaction = [PFTestSKPaymentTransaction transactionForPayment:payment
                                                                  withError:nil
                                                                    inState:SKPaymentTransactionStatePurchased];
        } else {
            transaction = [PFTestSKPaymentTransaction transactionForPayment:payment
                                                                  withError:nil
                                                                    inState:SKPaymentTransactionStateFailed];
        }

        [purchaseController.transactionObserver paymentQueue:paymentQueue updatedTransactions: @[ transaction ]];
    });

    XCTestExpectation *successExpectation = [self expectationWithDescription:@"Success"];
    [[purchaseController buyProductAsyncWithIdentifier:@"product"] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [successExpectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];

    OCMStub([purchaseController canPurchase]).andReturn(YES);
    XCTestExpectation *failInvalidProductExpectation = [self expectationWithDescription:@"Failed Invalid Product"];

    [[purchaseController buyProductAsyncWithIdentifier:@"nonexistent"] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.faulted);
        XCTAssertNotNil(task.error);

        [failInvalidProductExpectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testDownloadAssetAsync {
    id dataSource = [self mockedDataSource];
    id bundle = PFStrictClassMock([NSBundle class]);

    PFPurchaseController *purchaseController = [PFPurchaseController controllerWithDataSource:dataSource bundle:bundle];

    purchaseController.productsRequestClass = [PFTestSKProductsRequest class];
    purchaseController.paymentQueue = PFStrictClassMock([SKPaymentQueue class]);

    SKPayment *payment = [SKPayment paymentWithProduct:[self sampleProduct]];
    PFTestSKPaymentTransaction *transaction = [PFTestSKPaymentTransaction transactionForPayment:payment
                                                                                      withError:nil
                                                                                        inState:SKPaymentTransactionStatePurchased];

    NSString *receiptFile = [self sampleReceiptFilePath];
    OCMStub([bundle appStoreReceiptURL]).andReturn([NSURL fileURLWithPath:receiptFile]);
    [[self sampleData] writeToFile:receiptFile atomically:YES];

    PFFile *mockedFile = PFPartialMock([PFFile fileWithName:@"testData" data:[self sampleData]]);

    // lol. Probably should just stick this in the PFFile_Private header.
    NSString *stagedPath = [mockedFile valueForKey:@"stagedFilePath"];
    OCMStub([mockedFile _cachedFilePath]).andReturn(stagedPath);

    PFCommandResult *mockedCommandResult = [PFCommandResult commandResultWithResult:(NSDictionary *)mockedFile
                                                                       resultString:nil
                                                                       httpResponse:nil];
    BFTask *mockedTask = [BFTask taskWithResult:mockedCommandResult];

    NSString *tempDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];

    id commandRunner = [dataSource commandRunner];
    OCMStub([[commandRunner ignoringNonObjectArgs] runCommandAsync:[OCMArg isNotNil] withOptions:0]).andReturn(mockedTask);

    id fileManager = [dataSource fileManager];
    OCMStub([fileManager parseDataItemPathForPathComponent:@"product"]).andReturn(tempDirectory);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    XCTestExpectation *progressExpectation = [self expectationWithDescription:@"progress"];

    __block int lastProgress = -1;
    [[purchaseController downloadAssetAsyncForTransaction:transaction
                                        withProgressBlock:^(int percentDone) {
                                            XCTAssertGreaterThan(percentDone, lastProgress);
                                            lastProgress = percentDone;

                                            if (lastProgress == 100) {
                                                [progressExpectation fulfill];
                                            }
                                        }
                                             sessionToken:@"token"] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);

        NSData *contentsOfFile = [NSData dataWithContentsOfFile:task.result];
        XCTAssertEqualObjects(contentsOfFile, [self sampleData]);

        [expectation fulfill];

        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testDownloadInvalidReceipt {
    id dataSource = [self mockedDataSource];
    id bundle = PFStrictClassMock([NSBundle class]);

    PFPurchaseController *purchaseController = [PFPurchaseController controllerWithDataSource:dataSource bundle:bundle];

    purchaseController.productsRequestClass = [PFTestSKProductsRequest class];
    purchaseController.paymentQueue = PFStrictClassMock([SKPaymentQueue class]);

    SKPayment *payment = [SKPayment paymentWithProduct:[self sampleProduct]];
    PFTestSKPaymentTransaction *transaction = [PFTestSKPaymentTransaction transactionForPayment:payment
                                                                                      withError:nil
                                                                                        inState:SKPaymentTransactionStatePurchased];
    OCMStub([bundle appStoreReceiptURL]).andReturn(nil);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[purchaseController downloadAssetAsyncForTransaction:transaction
                                        withProgressBlock:nil
                                             sessionToken:@"token"] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.faulted);
        XCTAssertNotNil(task.error);
        XCTAssertEqual(task.error.code, kPFErrorReceiptMissing);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testDownloadMissingReceiptData {
    id dataSource = [self mockedDataSource];
    id bundle = PFStrictClassMock([NSBundle class]);

    PFPurchaseController *purchaseController = [PFPurchaseController controllerWithDataSource:dataSource bundle:bundle];

    purchaseController.productsRequestClass = [PFTestSKProductsRequest class];
    purchaseController.paymentQueue = PFStrictClassMock([SKPaymentQueue class]);

    SKPayment *payment = [SKPayment paymentWithProduct:[self sampleProduct]];
    PFTestSKPaymentTransaction *transaction = [PFTestSKPaymentTransaction transactionForPayment:payment
                                                                                      withError:nil
                                                                                        inState:SKPaymentTransactionStatePurchased];

    OCMStub([bundle appStoreReceiptURL]).andReturn([NSURL fileURLWithPath:[self sampleReceiptFilePath]]);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[purchaseController downloadAssetAsyncForTransaction:transaction
                                        withProgressBlock:nil
                                             sessionToken:@"token"] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.faulted);
        XCTAssertNotNil(task.error);
        XCTAssertEqual(task.error.code, kPFErrorReceiptMissing);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testDownloadInvalidFile {
    id dataSource = [self mockedDataSource];
    id bundle = PFStrictClassMock([NSBundle class]);

    PFPurchaseController *purchaseController = [PFPurchaseController controllerWithDataSource:dataSource bundle:bundle];

    purchaseController.productsRequestClass = [PFTestSKProductsRequest class];
    purchaseController.paymentQueue = PFStrictClassMock([SKPaymentQueue class]);

    SKPayment *payment = [SKPayment paymentWithProduct:[self sampleProduct]];
    PFTestSKPaymentTransaction *transaction = [PFTestSKPaymentTransaction transactionForPayment:payment
                                                                                      withError:nil
                                                                                        inState:SKPaymentTransactionStatePurchased];

    NSString *temporaryFile = [self sampleReceiptFilePath];
    OCMStub([bundle appStoreReceiptURL]).andReturn([NSURL fileURLWithPath:temporaryFile]);
    [[self sampleData] writeToFile:temporaryFile atomically:YES];

    PFCommandResult *mockedResult = [PFCommandResult commandResultWithResult:@{ @"a" : @"Hello" }
                                                                resultString:nil
                                                                httpResponse:nil];
    BFTask *mockedTask = [BFTask taskWithResult:mockedResult];
    id commandRunner = [dataSource commandRunner];
    OCMStub([[commandRunner ignoringNonObjectArgs] runCommandAsync:OCMOCK_ANY withOptions:0]).andReturn(mockedTask);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[purchaseController downloadAssetAsyncForTransaction:transaction
                                        withProgressBlock:nil
                                             sessionToken:@"token"] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.faulted);
        XCTAssertNotNil(task.error);
        XCTAssertEqual(task.error.code, kPFErrorInvalidPurchaseReceipt);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

@end
