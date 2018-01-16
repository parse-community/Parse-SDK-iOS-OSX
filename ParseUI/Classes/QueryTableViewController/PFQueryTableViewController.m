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

#import "PFQueryTableViewController.h"

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>

#import <Parse/Parse.h>

#import "PFActivityIndicatorTableViewCell.h"
#import "PFImageView.h"
#import "PFLoadingView.h"
#import "PFLocalization.h"
#import "PFTableViewCell.h"
#import "PFUIAlertView.h"

// Add headers to kill any warnings.
// `initWithStyle:` is a UITableViewController method.
// `initWithCoder:`/`initWithNibName:bundle:` are UIViewController methods and are, for sure, available.
@interface UITableViewController ()

- (instancetype)initWithStyle:(UITableViewStyle)style NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

@end

@interface PFQueryTableViewController () {
    NSMutableArray<PFObject *> *_mutableObjects;

    BOOL _firstLoad;           // Whether we have loaded the first set of objects
    NSInteger _currentPage;    // The last page that was loaded
    NSInteger _lastLoadCount;  // The count of objects from the last load.
    // Set to -1 when objects haven't loaded, or there was an error.
    UITableViewCellSeparatorStyle _savedSeparatorStyle;
}

@property (nonatomic, strong) PFLoadingView *loadingView;

- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

@end

@implementation PFQueryTableViewController

#pragma mark -
#pragma mark Init

- (instancetype)initWithCoder:(NSCoder *)decoder {
    // initWithCoder is usually a parallel designated initializer, as is the case here
    // It's used by storyboard
    if (self = [super initWithCoder:decoder]) {
        [self _setupWithClassName:nil];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    // This is used by interface builder
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self _setupWithClassName:nil];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self initWithStyle:style className:nil];
}

- (instancetype)initWithClassName:(NSString *)className {
    return [self initWithStyle:UITableViewStylePlain className:className];
}

- (instancetype)initWithStyle:(UITableViewStyle)style className:(NSString *)className {
    if (self = [super initWithStyle:style]) {
        [self _setupWithClassName:className];
    }
    return self;
}

- (void)_setupWithClassName:(NSString *)otherClassName {
    _mutableObjects = [NSMutableArray array];
    _firstLoad = YES;

    // Set some reasonable defaults
    _objectsPerPage = 25;
    _loadingViewEnabled = YES;
    _paginationEnabled = YES;
    _pullToRefreshEnabled = YES;
    _lastLoadCount = -1;

    _parseClassName = [otherClassName copy];
}

#pragma mark -
#pragma mark UIViewController

- (void)loadView {
    [super loadView];

    // Setup the Pull to Refresh UI if needed
    if (self.pullToRefreshEnabled) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self
                           action:@selector(_refreshControlValueChanged:)
                 forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refreshControl;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self loadObjects];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.loadingView.frame = self.tableView.bounds;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView beginUpdates];

    // If we're currently showing the pagination cell, we need to hide it during editing.
    if ([self paginationEnabled] && [self _shouldShowPaginationCell]) {
        [self.tableView deleteRowsAtIndexPaths:@[ [self _indexPathForPaginationCell] ]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    [super setEditing:editing animated:animated];

    // Ensure proper re-insertion of the pagination cell.
    if ([self paginationEnabled] && [self _shouldShowPaginationCell]) {
        [self.tableView insertRowsAtIndexPaths:@[ [self _indexPathForPaginationCell] ]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    [self.tableView endUpdates];
}

#pragma mark -
#pragma mark Data

- (void)objectsWillLoad {
    if (_firstLoad) {
        _savedSeparatorStyle = self.tableView.separatorStyle;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    [self _refreshLoadingView];
}

- (void)objectsDidLoad:(NSError *)error {
    if (_firstLoad) {
        _firstLoad = NO;
        self.tableView.separatorStyle = _savedSeparatorStyle;
    }
    [self _refreshLoadingView];
}

- (PFQuery *)queryForTable {
    if (!self.parseClassName) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"You need to specify a parseClassName for the PFQueryTableViewController.", nil];
    }

    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];

    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0 && ![Parse isLocalDatastoreEnabled]) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }

    [query orderByDescending:@"createdAt"];

    return query;
}

// Alters a query to add functionality like pagination
- (void)_alterQuery:(PFQuery *)query forLoadingPage:(NSInteger)page {
    if (self.paginationEnabled && self.objectsPerPage) {
        query.limit = self.objectsPerPage;
        query.skip = page * self.objectsPerPage;
    }
}

- (void)clear {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mutableObjects removeAllObjects];
        [self.tableView reloadData];
        _currentPage = 0;
    });
}

- (BFTask<NSArray<__kindof PFObject *> *> *)loadObjects {
    return [self loadObjects:0 clear:YES];
}

- (BFTask<NSArray<__kindof PFObject *> *> *)loadObjects:(NSInteger)page clear:(BOOL)clear {
    self.loading = YES;
    [self objectsWillLoad];

    PFQuery *query = [self queryForTable];
    [self _alterQuery:query forLoadingPage:page];

    BFTaskCompletionSource<NSArray<__kindof PFObject *> *> *source = [BFTaskCompletionSource taskCompletionSource];
    [query findObjectsInBackgroundWithBlock:^(NSArray *foundObjects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![Parse isLocalDatastoreEnabled] &&
                query.cachePolicy != kPFCachePolicyCacheOnly &&
                error.code == kPFErrorCacheMiss) {
                // no-op on cache miss
                return;
            }

            self.loading = NO;

            if (error) {
                _lastLoadCount = -1;
            } else {
                _currentPage = page;
                _lastLoadCount = [foundObjects count];

                if (clear) {
                    [_mutableObjects removeAllObjects];
                }

                [_mutableObjects addObjectsFromArray:foundObjects];
            }
            [self.tableView reloadData];
            [self objectsDidLoad:error];
            [self.refreshControl endRefreshing];

            if (error) {
                [source trySetError:error];
            } else {
                [source trySetResult:foundObjects];
            }
        });
    }];

    return source.task;
}

- (void)loadNextPage {
    if (!self.loading) {
        [self loadObjects:(_currentPage + 1) clear:NO];
    }
}

#pragma mark -
#pragma mark UIScrollViewDelegate

// scrollViewDidEndDragging:willDecelerate: is called when a user stops dragging the table view.
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // If the user lets go and the table view has no momentum,
    // scrollViewDidEndDragging:willDecelerate: is called with willDecelerate:NO.
    // In this case, we trigger a load for all the PFImageViews
    // in our PFTableViewCells through _loadImagesForOnscreenRows.
    if (!decelerate) {
        [self _loadImagesForOnscreenRows];
    }
}

// If the user lets go and the table view has momentum,
// scrollViewDidEndDragging:willDecelerate: is called with willDecelerate:YES.
// We will defer loading of images until scrollViewDidEndDecelerating: is called.
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self _loadImagesForOnscreenRows];
}

#pragma mark -
#pragma mark UITableViewDataSource

// Return the number of rows in the section.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [self.objects count];

    if ([self _shouldShowPaginationCell]) {
        count += 1;
    }

    return count;
}

// Default implementation that displays a default style cell
- (PFTableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(PFObject *)object {
    static NSString *cellIdentifier = @"PFTableViewCell";
    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    [self tableView:tableView configureCell:cell atIndexPath:indexPath object:object];

    return cell;
}

- (void)tableView:(UITableView *)tableView
    configureCell:(PFTableViewCell *)cell
      atIndexPath:(NSIndexPath *)indexPath
           object:(PFObject *)object {
    // Grab a key to display
    NSString *key;
    if (self.textKey) {
        key = self.textKey;
    } else if ([[object allKeys] count] > 0) {
        key = [[object allKeys] objectAtIndex:0];
    }

    // Configure the cell
    if (key) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [object objectForKey:key]];
    }

    if (self.placeholderImage) {
        cell.imageView.image = self.placeholderImage;
    }

    if (self.imageKey) {
        cell.imageView.file = object[self.imageKey];
    }
}

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    return self.objects[indexPath.row];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath {
    [self removeObjectAtIndexPath:indexPath animated:YES];
}

- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    [self removeObjectsAtIndexPaths:@[ indexPath ] animated:animated];
}

- (void)removeObjectsAtIndexPaths:(NSArray *)indexPaths {
    [self removeObjectsAtIndexPaths:indexPaths animated:YES];
}

- (void)removeCellAtIndexPath:(nullable NSIndexPath *)indexPath animated:(BOOL)animated {
    [self removeCellsAtIndexPaths:@[indexPath] animated: animated];
}

- (void)removeCellsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated {
    NSMutableIndexSet *mutableIndexSet = [[NSMutableIndexSet alloc]init];
    
    for (NSIndexPath *indexPath in indexPaths) {
        [mutableIndexSet addIndex:indexPath.row];
    }
    
    [_mutableObjects removeObjectsAtIndexes:mutableIndexSet];
    
    [self.tableView deleteRowsAtIndexPaths:indexPaths
                          withRowAnimation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone];
}

- (void)removeObjectsAtIndexPaths:(NSArray *)indexPaths animated:(BOOL)animated {
    if (indexPaths.count == 0) {
        return;
    }

    // We need the contents as both an index set and a list of index paths.
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];

    for (NSIndexPath *indexPath in indexPaths) {
        if (indexPath.section != 0) {
            [NSException raise:NSRangeException format:@"Index Path section %lu out of range!", (long)indexPath.section];
        }

        if (indexPath.row >= self.objects.count) {
            [NSException raise:NSRangeException format:@"Index Path row %lu out of range!", (long)indexPath.row];
        }

        [indexes addIndex:indexPath.row];
    }

    BFContinuationBlock deletionHandlerBlock = ^id (BFTask *task) {
        self.refreshControl.enabled = YES;
        if (task.error) {
            [self _handleDeletionError:task.error];
        }

        return nil;
    };

    NSMutableArray *allDeletionTasks = [NSMutableArray arrayWithCapacity:indexes.count];
    NSArray *objectsToRemove = [self.objects objectsAtIndexes:indexes];

    // Remove the contents from our local cache so we can give the user immediate feedback.
    [_mutableObjects removeObjectsInArray:objectsToRemove];
    [self.tableView deleteRowsAtIndexPaths:indexPaths
                          withRowAnimation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone];

    for (id obj in objectsToRemove) {
        [allDeletionTasks addObject:[obj deleteInBackground]];
    }

    [[BFTask taskForCompletionOfAllTasks:allDeletionTasks] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                                                      withBlock:deletionHandlerBlock];
}

- (PFTableViewCell *)tableView:(UITableView *)otherTableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"PFTableViewCellNextPage";

    PFActivityIndicatorTableViewCell *cell = [otherTableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[PFActivityIndicatorTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:cellIdentifier];
        cell.textLabel.text = PFLocalizedString(@"Load more...", @"Load more...");
    }

    cell.animating = self.loading;

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)otherTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PFTableViewCell *cell;
    if ([self _shouldShowPaginationCell] && [indexPath isEqual:[self _indexPathForPaginationCell]]) {
        // Return the pagination cell on the last cell
        cell = [self tableView:otherTableView cellForNextPageAtIndexPath:indexPath];
    } else {
        cell = [self tableView:otherTableView
         cellForRowAtIndexPath:indexPath
                        object:[self objectAtIndexPath:indexPath]];
    }

    if ([cell isKindOfClass:[PFTableViewCell class]] &&
        !otherTableView.dragging &&
        !otherTableView.decelerating) {
        // The reason we dispatch to the main queue is that we want to enable subclasses to override
        // tableView:cellForRowAtIndexPath:object:, and we still do image loading after they assign
        // the remote image file.
        dispatch_async(dispatch_get_main_queue(), ^{
            [cell.imageView loadInBackground];
        });
    }
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)otherTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Handle selection of the next page row
    if (!_firstLoad &&
        self.paginationEnabled &&
        [indexPath isEqual:[self _indexPathForPaginationCell]]) {
        [self loadNextPage];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:[self _indexPathForPaginationCell]]) {
        return UITableViewCellEditingStyleNone;
    }

    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:[self _indexPathForPaginationCell]]) {
        return NO;
    }

    return YES;
}

#pragma mark -
#pragma mark Private

// Whether we need to show the pagination cell
- (BOOL)_shouldShowPaginationCell {
    return (self.paginationEnabled &&
            !self.editing &&
            [self.objects count] != 0 &&
            (_lastLoadCount == -1 || _lastLoadCount >= (NSInteger)self.objectsPerPage));
}

// The row of the pagination cell
- (NSIndexPath *)_indexPathForPaginationCell {
    return [NSIndexPath indexPathForRow:[self.objects count] inSection:0];
}

- (void)_loadImagesForOnscreenRows {
    if (self.objects.count > 0) {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths) {
            [self _loadImageForCellAtIndexPath:indexPath];
        }
    }
}

- (void)_loadImageForCellAtIndexPath:(NSIndexPath *)indexPath {
    PFTableViewCell *cell = (PFTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[PFTableViewCell class]]) {
        [cell.imageView loadInBackground];
    }
}

#pragma mark -
#pragma mark Error handling

- (void)_handleDeletionError:(NSError *)error {
    // Fully reload on error.
    [self loadObjects];

    NSString *message = [NSString stringWithFormat:@"%@: \"%@\"",
                         PFLocalizedString(@"Error occurred during deletion", @"Error occurred during deletion"),
                         error.localizedDescription];
    [PFUIAlertView presentAlertInViewController:self withTitle:PFLocalizedString(@"Delete Error", @"Delete Error") message:message];
}

#pragma mark -
#pragma mark Actions

- (void)_refreshControlValueChanged:(UIRefreshControl *)refreshControl {
    [self loadObjects];
}

#pragma mark -
#pragma mark Accessors

- (NSArray<__kindof PFObject *> *)objects {
    return _mutableObjects;
}

#pragma mark -
#pragma mark Loading View

- (void)_refreshLoadingView {
    BOOL showLoadingView = self.loadingViewEnabled && self.loading && _firstLoad;

    if (showLoadingView) {
        [self.tableView addSubview:self.loadingView];
        [self.view setNeedsLayout];
    } else {
        // Avoid loading `loadingView` - just use an ivar.
        if (_loadingView) {
            [self.loadingView removeFromSuperview];
            self.loadingView = nil;
        }
    }
}

- (PFLoadingView *)loadingView {
    if (!_loadingView) {
        _loadingView = [[PFLoadingView alloc] initWithFrame:CGRectZero];
    }
    return _loadingView;
}

@end
