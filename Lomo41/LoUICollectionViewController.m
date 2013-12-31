//
//  LoUICollectionViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/26/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoUICollectionViewController.h"

#import "LoImageViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface LoUICollectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>
- (IBAction)doDelete:(id)sender;
- (IBAction)doShare:(id)sender;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) ALAssetsGroup *album;
@property (nonatomic) NSMutableArray *assets;
@property (nonatomic) ALAssetsLibrary *library;
@end

@implementation LoUICollectionViewController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear: (BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.assets) {
        self.assets = [[NSMutableArray alloc] init];
    } else {
        [self.assets removeAllObjects];
    }
    if (!self.library) {
        self.library = [[ALAssetsLibrary alloc] init];
    }
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([@"Lomo41" compare: [group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
                                        self.album = group;
                                        ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                            if (result) {
                                                [self.assets addObject:result];
                                            }
                                        };
                                        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
                                        [self.album setAssetsFilter:onlyPhotosFilter];
                                        [self.album enumerateAssetsUsingBlock:assetsEnumerationBlock];
                                    }
                                    [self.collectionView reloadData];
                                }
                                failureBlock:^(NSError* er){
                                    self.album = nil;
                                }];
}

- (void)viewDidDisappear: (BOOL)animated {
    self.album = nil;
    [self.assets removeAllObjects];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.assets.count;
}

//TODO: This is inelegant. Find a better pattern.
#define kFrontViewTag 1
#define kBacksideViewTag 2
#define KImageViewTag 3
#define KFlippableViewTag 4
- (UICollectionViewCell *)collectionView: (UICollectionView *)collectionView cellForItemAtIndexPath: (NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"photoCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    ALAsset *asset = self.assets[self.assets.count - 1 - indexPath.row];
    CGImageRef thumbnailImageRef = [[asset defaultRepresentation] fullScreenImage];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:KImageViewTag];
    imageView.image = thumbnail;
    UIView *flippableView = (UIView *)[cell viewWithTag:KFlippableViewTag];
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    swipeRight.delegate = self;
    swipeRight.numberOfTouchesRequired = 1;
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [flippableView addGestureRecognizer:swipeRight];
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    swipeLeft.delegate = self;
    swipeLeft.numberOfTouchesRequired = 1;
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [flippableView addGestureRecognizer:swipeLeft];
    UIView *frontView = (UIView *)[flippableView viewWithTag:kFrontViewTag];
    UIView *backsideView = (UIView *)[flippableView viewWithTag:kBacksideViewTag];
    frontView.hidden = NO;
    backsideView.hidden = YES;
    return cell;
}

- (void)didSwipe: (UISwipeGestureRecognizer*)recognizer {
    UIView *flipContainerView = (UIView*) recognizer.view;
    UIView *frontView = (UIView *)[flipContainerView viewWithTag:kFrontViewTag];
    UIView *backsideView = (UIView *)[flipContainerView viewWithTag:kBacksideViewTag];
    UIViewAnimationOptions direction = UIViewAnimationOptionTransitionFlipFromLeft;
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        direction = UIViewAnimationOptionTransitionFlipFromRight;
    }
    [UIView transitionWithView:flipContainerView
                      duration:0.2f
                       options:direction
                    animations:^{
                        if (!frontView.isHidden) {
                            frontView.hidden = YES;
                            backsideView.hidden = NO;
                        } else {
                            frontView.hidden = NO;
                            backsideView.hidden = YES;
                        }
                    } completion:nil];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewImage"]) {
        // TODO: The Button's parent's parent is the UICollectionViewCell.
        // This is gross and I'm using it only to avoid subclassing, which is probably dumb.
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell*)((UIView*)sender).superview.superview.superview.superview];
        LoImageViewController *destViewController = segue.destinationViewController;
        destViewController.asset = self.assets[self.assets.count - 1 - indexPath.row];
    }
}



- (IBAction)doDelete:(id)sender {
    NSLog(@"delete");
}

- (IBAction)doShare:(id)sender {
    NSLog(@"share");
}
@end
