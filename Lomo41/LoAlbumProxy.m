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
@property (nonatomic) dispatch_queue_t sessionQueue;
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
        self.assets = [[NSMutableArray alloc] init];
        self.sessionQueue = dispatch_queue_create("album proxy queue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(self.sessionQueue, ^(){
            [self updateAssets];
        });
    }
    return self;
}

- (void)updateAssets {
    [self.library getAssetListForAlbum:self.albumName
                      withSuccessBlock:^(NSMutableArray *assets) {
                          self.assets = assets;
                          NSLog(@"assets updated: %lu", self.assets.count);
                      }
                     withFailureBlock:^(NSError *error) {
                         NSLog(@"updateAssets error: %@", error);
                     }];
}

- (void)addImage: (UIImage *)image {
    dispatch_async(self.sessionQueue, ^(){
        [self.library saveImage:image
                        toAlbum:self.albumName
               withSuccessBlock:^(NSURL *assetURL) {
                   [self updateAssets];
               } withFailureBlock:^(NSError *error) {
                   NSLog(@"addImage error: %@", error);
               }];
    });
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
