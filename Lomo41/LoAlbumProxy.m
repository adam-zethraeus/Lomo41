//
//  LoAlbumProxy.m
//  Lomo41
//
//  Created by Adam Zethraeus on 1/11/14.
//  Copyright (c) 2014 Very Nice Co. All rights reserved.
//

#import "LoAlbumProxy.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "ALAssetsLibrary+PhotoAlbumFunctionality.h"

@interface LoAlbumProxy ()
@property (nonatomic) NSString* albumName;
@property (nonatomic) ALAssetsLibrary* library;
@end

@implementation LoAlbumProxy

- (id)init {
    @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Please init LoAlbumProxy with initForAlbum." userInfo:nil];
    return nil;
}

- (id)initForAlbum: (NSString *) albumName {
    self = [super init];
    if (self) {
        if (!albumName || [albumName isEqualToString:@""]) {
            @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"A nil or empty album name is not permitted." userInfo:nil];
        }
        self.albumName = albumName;
        self.library = [[ALAssetsLibrary alloc] init];
        __weak LoAlbumProxy *weakSelf = self;
        [self.library addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group) {
            weakSelf.assets = [[NSMutableArray alloc] init];
            [weakSelf updateAssets];
        } failureBlock:^(NSError *error) {
#ifdef DEBUG
            @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Unexpected album creation failure" userInfo:nil];
#else
            NSLog(@"%@", error);
            // try to continue anyway
            weakSelf.assets = [[NSMutableArray alloc] init];
            [weakSelf updateAssets];
#endif
        }];
    }
    return self;
}

- (void)updateAssets {
    [self.library getAssetListForAlbum:self.albumName
                      withSuccessBlock:^(NSMutableArray *assets) {
                          self.assets = assets;
                      }
                     withFailureBlock:^(NSError *error) {
                         NSLog(@"updateAssets error: %@", error);
                     }];
}

- (void)addImage: (UIImage *)image {
    [self.library saveImage:image
                    toAlbum:self.albumName
           withSuccessBlock:^(NSURL *assetURL) {
               [self updateAssets]; // Often called too early due to likely framework bug.
           } withFailureBlock:^(NSError *error) {
               NSLog(@"addImage error: %@", error);
           }];
}

- (void)deleteAssetAtIndex: (NSUInteger)index {
    ALAsset* assetToDelete = self.assets[index];
    // Immediately remove from proxy.
    [self.assets removeObjectAtIndex:index];
    // Trigger library deletion and proxy update.
    [assetToDelete setImageData:nil
                       metadata:nil
                completionBlock:^(NSURL *assetURL, NSError *error) {
                    if (error) {
                        NSLog(@"deleteAssetAtIndex error: %@", error);
                    }
                    [self updateAssets];
                }];
}

@end
