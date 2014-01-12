#import "ALAssetsLibrary+PhotoAlbumFunctionality.h"

@implementation ALAssetsLibrary(PhotoAlbumFunctionality)

- (void)saveImage:(UIImage *)image
          toAlbum:(NSString *)albumName
 withSuccessBlock:(void (^)(NSURL *assetURL))successBlock
 withFailureBlock:(void (^)(NSError *error))failureBlock {
    [self writeImageToSavedPhotosAlbum:image.CGImage
                           orientation:(ALAssetOrientation)image.imageOrientation
                       completionBlock:^(NSURL* assetURL, NSError* error) {
                           if (error) {
                               if (failureBlock) failureBlock(error);
                           } else {
                               [self addAssetUrl:assetURL
                                         toAlbum:albumName
                                withSuccessBlock:successBlock
                                withFailureBlock:failureBlock];
                           }
                       }];
}

- (void)addAssetForUrl:(NSURL *)assetURL
               toGroup:(ALAssetsGroup *)group
      withSuccessBlock:(void (^)(NSURL *assetURL))successBlock
      withFailureBlock:(void (^)(NSError *error))failureBlock {
    [self assetForURL: assetURL
          resultBlock:^(ALAsset *asset) {
              [group addAsset: asset];
              if (successBlock) successBlock(assetURL);
          } failureBlock: failureBlock];
}

- (void)addAssetUrl:(NSURL *)assetURL
            toAlbum:(NSString *)albumName
   withSuccessBlock:(void (^)(NSURL *assetURL))successBlock
   withFailureBlock:(void (^)(NSError* error))failureBlock {
    __block BOOL albumWasFound = NO;
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
            albumWasFound = YES;
            [self addAssetForUrl:assetURL
                         toGroup:group
                withSuccessBlock:successBlock
                withFailureBlock:failureBlock];
            return;
        }
        if (group == nil && albumWasFound == NO) {
            __weak ALAssetsLibrary* weakSelf = self;
            [self addAssetsGroupAlbumWithName:albumName
                                  resultBlock:^(ALAssetsGroup *group) {
                                      [weakSelf addAssetForUrl:assetURL
                                                       toGroup:group
                                              withSuccessBlock:successBlock
                                              withFailureBlock:failureBlock];
                                      return;
                                  }
                                 failureBlock:failureBlock];
        }
    } failureBlock: failureBlock];
}

- (void)getAssetListForAlbum:(NSString *)albumName
            withSuccessBlock:(void (^)(NSMutableArray *assets))successBlock
           withFailureBlock:(void (^)(NSError* error))failureBlock {
    __block NSMutableArray *assets = [[NSMutableArray alloc] init];
    [self enumerateGroupsWithTypes:ALAssetsGroupAlbum
                        usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                            if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]] == NSOrderedSame) {
                                ALAssetsGroup *album = group;
                                ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
                                [album setAssetsFilter:onlyPhotosFilter];
                                [album enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                    if (result) {
                                        [assets addObject:result];
                                    }
                                }];
                            }
                            if (successBlock) successBlock(assets);
                        }
                      failureBlock:^(NSError* error){
                          if (failureBlock) failureBlock(error);
                      }];
}

@end
