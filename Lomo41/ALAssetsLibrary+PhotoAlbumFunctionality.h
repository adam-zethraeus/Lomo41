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
           withFailuireBlock:(void (^)(NSError* error))failureBlock;
@end