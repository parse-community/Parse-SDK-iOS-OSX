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

#import "StoryboardCollectionViewController.h"

#import <Parse/PFQuery.h>

#import <ParseUI/PFCollectionViewCell.h>

@implementation StoryboardCollectionViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;

    layout.sectionInset = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 10.0f);
    layout.minimumInteritemSpacing = 5.0f;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;

    const CGRect bounds = UIEdgeInsetsInsetRect(self.view.bounds, layout.sectionInset);
    CGFloat sideSize = MIN(CGRectGetWidth(bounds), CGRectGetHeight(bounds)) / 2.0f - layout.minimumInteritemSpacing;
    layout.itemSize = CGSizeMake(sideSize, sideSize);
}


#pragma mark -
#pragma mark Query

- (PFQuery *)queryForCollection {
    PFQuery *query = [super queryForCollection];
    [query orderByAscending:@"priority"];
    return query;
}

#pragma mark -
#pragma mark CollectionView

- (PFCollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
                                  object:(PFObject *)object {
    PFCollectionViewCell *cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath object:object];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:object[@"title"] attributes:nil];
    NSAttributedString *priorityString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\nPriority: %@", object[@"priority"]]
                                                                         attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:13.0f],
                                                                                       NSForegroundColorAttributeName : [UIColor grayColor] }];
    [title appendAttributedString:priorityString];
    cell.textLabel.attributedText = title;

    cell.contentView.layer.borderWidth = 1.0f;
    cell.contentView.layer.borderColor = [UIColor lightGrayColor].CGColor;

    return cell;
}

@end
