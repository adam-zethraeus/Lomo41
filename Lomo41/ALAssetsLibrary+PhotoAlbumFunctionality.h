//
//  LoShotProcessor.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/20/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ALAssetsLibrary(PhotoAlbumFunctionality)

- (void)saveImage:(UIImage *)image
          toAlbum:(NSString *)albumName
 withSuccessBlock:(void (^)(NSURL *assetURL))successBlock
 withFailureBlock:(void (^)(NSError *error))failureBlock;

- (void)addAssetUrl:(NSURL *)assetURL
            toAlbum:(NSString *)albumName
   withSuccessBlock:(void (^)(NSURL *assetURL))successBlock
   withFailureBlock:(void (^)(NSError* error))failureBlock;

- (void)getAssetListForAlbum:(NSString *)albumName
            withSuccessBlock:(void (^)(NSMutableArray *assets))successBlock
           withFailureBlock:(void (^)(NSError* error))failureBlock;
@end