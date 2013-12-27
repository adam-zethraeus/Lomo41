//
//  LoUICollectionViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/26/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoUICollectionViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

@interface LoUICollectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) ALAssetsGroup *album;
@property (nonatomic) NSMutableArray *pictures;
@property (nonatomic) ALAssetsLibrary *library;
@end

@implementation LoUICollectionViewController

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.pictures) {
        self.pictures = [[NSMutableArray alloc] init];
    } else {
        [self.pictures removeAllObjects];
    }
    if (!self.library) {
    self.library = [[ALAssetsLibrary alloc] init];
    }
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                       usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                           if ([@"Lomo41" compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
                               self.album = group;
                               ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                   if (result) {
                                       [self.pictures addObject:result];
                                   }
                               };
                               
                               ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
                               [self.album setAssetsFilter:onlyPhotosFilter];
                               [self.album enumerateAssetsUsingBlock:assetsEnumerationBlock];
                           }
                        }
                     failureBlock:^(NSError* er){
                         self.album = nil;
                     }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.collectionView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.album = nil;
    [self.pictures removeAllObjects];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.pictures.count;
}

#define kImageViewTag 1
- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"photoCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    ALAsset *asset = self.pictures[self.pictures.count - 1 - indexPath.row];
    CGImageRef thumbnailImageRef = [[asset defaultRepresentation] fullScreenImage];//[asset thumbnail];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:kImageViewTag];
    imageView.image = thumbnail;
    
    return cell;
}

@end
