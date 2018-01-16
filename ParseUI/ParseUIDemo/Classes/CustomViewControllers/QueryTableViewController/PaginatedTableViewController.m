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

#import "PaginatedTableViewController.h"

#import <Parse/PFObject.h>
#import <Parse/PFQuery.h>

#import <ParseUI/PFTableViewCell.h>

@implementation PaginatedTableViewController

#pragma mark -
#pragma mark init

- (instancetype)initWithClassName:(NSString *)className {
    self = [super initWithClassName:className];
    if (self) {
        self.title = @"Paginated Table";
        self.pullToRefreshEnabled = YES;
        self.objectsPerPage = 10;
        self.paginationEnabled = YES;
    }
    return self;
}

#pragma mark -
#pragma mark Data

- (PFQuery *)queryForTable {
    PFQuery *query = [super queryForTable];
    [query orderByAscending:@"priority"];
    return query;
}

#pragma mark -
#pragma mark TableView

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(PFObject *)object {
    static NSString *cellIdentifier = @"cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }

    cell.textLabel.text = object[@"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Priority: %@", object[@"priority"]];

    return cell;
}

@end
