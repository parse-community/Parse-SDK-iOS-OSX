/*
 *  Copyright (c) 2014, Parse, LLC. All rights reserved.
 *
 *  You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
 *  copy, modify, and distribute this software in source code or binary form for use
 *  in connection with the web services and APIs provided by Parse.
 *
 *  As with any software that integrates with the Parse platform, your use of
 *  this software is subject to the Parse Terms of Service
 *  [https://www.parse.com/about/terms]. This copyright notice shall be
 *  included in all copies or substantial portions of the software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 *  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 *  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 *  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#import "PFProductTableViewController.h"

#import <Parse/PFProduct.h>
#import <Parse/PFPurchase.h>
#import <Parse/PFQuery.h>

#import "PFUIAlertView.h"
#import "PFLocalization.h"
#import "PFPurchaseTableViewCell.h"

static NSString *const PFProductMetadataPriceKey = @"price";
static NSString *const PFProductMetadataPriceLocaleKey = @"priceLocale";

@interface PFProductTableViewController () <SKProductsRequestDelegate> {
    NSMutableDictionary *_productMetadataDictionary;
    NSMutableDictionary *_productProgressDictionary;

    SKProductsRequest *_storeProductsRequest;
}

@end

@implementation PFProductTableViewController

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:UITableViewStylePlain className:[PFProduct parseClassName]]) {
        self.pullToRefreshEnabled = NO;
        self.paginationEnabled = NO;

        _productMetadataDictionary = [NSMutableDictionary dictionary];
        _productProgressDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style className:(NSString *)className {
    return [self initWithStyle:style];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.rowHeight = 84.0f;
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    if (error) {
        return;
    }

    [self.objects enumerateObjectsUsingBlock:^(PFProduct *product, NSUInteger idx, BOOL *stop) {
        // No download for this product - just continue
        if (!product.downloadName) {
            return;
        }

        [PFPurchase addObserverForProduct:product.productIdentifier block:^(SKPaymentTransaction *transaction) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
            PFPurchaseTableViewCell *cell = (PFPurchaseTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];

            cell.state = PFPurchaseTableViewCellStateDownloading;
            [PFPurchase downloadAssetForTransaction:transaction
                                         completion:^(NSString *filePath, NSError *error) {
                                             if (!error) {
                                                 cell.state = PFPurchaseTableViewCellStateDownloaded;
                                             } else {
                                                 cell.state = PFPurchaseTableViewCellStateNormal;

                                                 NSString *title = PFLocalizedString(@"Download Error",
                                                                                     @"Download Error");
                                                 [PFUIAlertView presentAlertInViewController:self withTitle:title error:error];
                                             }
                                         }
                                           progress:^(int percentDone) {
                                               _productProgressDictionary[product.productIdentifier] = @(percentDone);
                                               [cell.progressView setProgress:percentDone/100.0f animated:YES];
                                           }];
        }];
    }];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(PFProduct *)product {
    static NSString *cellIdentifier = @"PFPurchaseTableViewCell";

    PFPurchaseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PFPurchaseTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:cellIdentifier];
    }

    if (indexPath.row % 2 == 0) {
        cell.backgroundView.backgroundColor = [UIColor colorWithWhite:242.0f/255.0f alpha:1.0f];
        cell.textLabel.shadowOffset = CGSizeZero;
        cell.textLabel.shadowColor = [UIColor whiteColor];
        cell.priceLabel.shadowOffset = CGSizeZero;
        cell.priceLabel.shadowColor = [UIColor whiteColor];

    } else {
        cell.backgroundView.backgroundColor = [UIColor colorWithWhite:232.0f/255.0f alpha:1.0f];
        cell.textLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        cell.textLabel.shadowColor = [UIColor whiteColor];
        cell.priceLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
        cell.priceLabel.shadowColor = [UIColor whiteColor];
    }

    cell.imageView.file = product.icon;
    cell.textLabel.text = product.title;
    cell.detailTextLabel.text = product.subtitle;

    NSString *price = [self _priceForProduct:product];
    if (price) {
        cell.priceLabel.text = [NSString stringWithFormat:@"  $%@  ", price];
    }

    if (product.downloadName) {
        NSString *contentPath = [PFPurchase assetContentPathForProduct:product];
        if (contentPath) {
            cell.state = PFPurchaseTableViewCellStateDownloaded;
        }
    } else {
        int progress = [self _downloadProgressForProduct:product];
        if (progress == 0) {
            cell.state = PFPurchaseTableViewCellStateNormal;
        } else if (progress == 100) {
            cell.state = PFPurchaseTableViewCellStateDownloaded;
        } else {
            cell.state = PFPurchaseTableViewCellStateDownloading;
        }
    }

    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.objects.count) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        PFProduct *product = self.objects[indexPath.row];
        [PFPurchase buyProduct:product.productIdentifier block:^(NSError *error) {
            if (error) {
                NSString *title = PFLocalizedString(@"Purchase Error", @"Purchase Error");
                [PFUIAlertView presentAlertInViewController:self withTitle:title error:error];
            }
        }];
    }
}

#pragma mark -
#pragma mark Data

- (NSString *)_priceForProduct:(PFProduct *)product {
    return _productMetadataDictionary[product.productIdentifier][PFProductMetadataPriceKey];
}

- (int)_downloadProgressForProduct:(PFProduct *)product {
    return [_productProgressDictionary[product.productIdentifier] intValue];
}

#pragma mark -
#pragma mark PFQueryTableViewController

- (PFQuery *)queryForTable {
    PFQuery *query = [super queryForTable];
    [query orderByAscending:@"order"];
    return query;
}

#pragma mark -
#pragma mark Querying Store

- (void)_queryStoreForProductsWithIdentifiers:(NSSet *)identifiers {
    _storeProductsRequest.delegate = nil;
    _storeProductsRequest = nil;

    _storeProductsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:identifiers];
    _storeProductsRequest.delegate = self;
    [_storeProductsRequest start];
}

#pragma mark -
#pragma mark SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if (request != _storeProductsRequest) {
        return;
    }

    NSArray *validProducts = response.products;
    if ([validProducts count] == 0) {
        return;
    }

    [validProducts enumerateObjectsUsingBlock:^(SKProduct *product,  NSUInteger idx, BOOL *stop) {
        NSDictionary *metadata = @{ PFProductMetadataPriceKey : product.price,
                                    PFProductMetadataPriceLocaleKey : product.priceLocale };
        _productMetadataDictionary[product.productIdentifier] = metadata;
    }];
    [self.tableView reloadData];

    _storeProductsRequest.delegate = nil;
}

- (void)requestDidFinish:(SKRequest *)request {
    _storeProductsRequest.delegate = nil;
    _storeProductsRequest = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    _storeProductsRequest.delegate = nil;
    _storeProductsRequest = nil;
}

@end
