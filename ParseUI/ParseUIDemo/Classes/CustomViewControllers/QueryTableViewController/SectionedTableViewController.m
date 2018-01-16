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

#import "SectionedTableViewController.h"

#import <Parse/PFObject.h>
#import <Parse/PFQuery.h>

#import <ParseUI/PFTableViewCell.h>

@interface SectionedTableViewController ()
{
    NSArray *_sectionSortedKeys;
    NSMutableDictionary *_sections;
}

@end

@implementation SectionedTableViewController

#pragma mark -
#pragma mark Init

- (instancetype)initWithClassName:(NSString *)className {
    self = [super initWithClassName:className];
    if (self) {
        self.title = @"Sectioned Table";
        self.pullToRefreshEnabled = YES;

        _sections = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark -
#pragma mark Data

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];

    [_sections removeAllObjects];
    for (PFObject *object in self.objects) {
        NSNumber *priority = object[@"priority"];

        NSMutableArray *array = _sections[priority];
        if (array) {
            [array addObject:object];
        } else {
            _sections[priority] = [NSMutableArray arrayWithObject:object];
        }
    }

    _sectionSortedKeys = [[_sections allKeys] sortedArrayUsingSelector:@selector(compare:)];
    [self.tableView reloadData];
}

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionArray = _sections[_sectionSortedKeys[indexPath.section]];
    return sectionArray[indexPath.row];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_sections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Priority %@", [_sectionSortedKeys[section] stringValue]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sectionAray = _sections[_sectionSortedKeys[section]];
    return [sectionAray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                        object:(PFObject *)object {
    static NSString *cellIdentifier = @"cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    cell.textLabel.text = object[@"title"];

    return cell;
}

@end
