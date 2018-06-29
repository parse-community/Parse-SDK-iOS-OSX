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

#import "SectionedCollectionViewController.h"

#import <Parse/PFObject.h>
#import <Parse/PFQuery.h>

#import <ParseUI/PFCollectionViewCell.h>

#pragma mark -
#pragma mark SimpleCollectionReusableView

@interface SimpleCollectionReusableView : UICollectionReusableView

@property (nonatomic, strong, readonly) UILabel *label;

@end

@implementation SimpleCollectionReusableView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    _label = [[UILabel alloc] initWithFrame:CGRectZero];
    _label.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_label];

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    _label.frame = self.bounds;
}

@end

@interface SectionedCollectionViewController ()
{
    NSArray *_sectionSortedKeys;
    NSMutableDictionary *_sections;
}

@end

#pragma mark -
#pragma mark SectionedCollectionViewController

@implementation SectionedCollectionViewController

#pragma mark -
#pragma mark Init

- (instancetype)initWithClassName:(NSString *)className {
    self = [super initWithClassName:className];
    if (!self) return nil;

    self.title = @"Sectioned Collection";
    self.pullToRefreshEnabled = YES;

    _sections = [NSMutableDictionary dictionary];

    return self;
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;

    layout.sectionInset = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 10.0f);
    layout.minimumInteritemSpacing = 5.0f;

    [self.collectionView registerClass:[SimpleCollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;

    const CGRect bounds = UIEdgeInsetsInsetRect(self.view.bounds, layout.sectionInset);
    CGFloat sideSize = MIN(CGRectGetWidth(bounds), CGRectGetHeight(bounds)) / 3.0f - layout.minimumInteritemSpacing * 2.0f;
    layout.itemSize = CGSizeMake(sideSize, sideSize);
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
    [self.collectionView reloadData];
}

- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *sectionAray = _sections[_sectionSortedKeys[indexPath.section]];
    return sectionAray[indexPath.row];
}

#pragma mark -
#pragma mark CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [_sections count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *sectionAray = _sections[_sectionSortedKeys[section]];
    return [sectionAray count];
}

- (PFCollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
                                  object:(PFObject *)object {
    PFCollectionViewCell *cell = [super collectionView:collectionView cellForItemAtIndexPath:indexPath object:object];

    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.text = object[@"title"];

    cell.contentView.layer.borderWidth = 1.0f;
    cell.contentView.layer.borderColor = [UIColor lightGrayColor].CGColor;

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        SimpleCollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"header" forIndexPath:indexPath];
        NSNumber *priority = _sectionSortedKeys[indexPath.section];
        view.label.text = [NSString stringWithFormat:@"Priority %@", [priority stringValue]];
        return view;
    }
    return [super collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if ([_sections count]) {
        return CGSizeMake(CGRectGetWidth(self.collectionView.bounds), 40.0f);
    }
    return CGSizeZero;
}

@end
