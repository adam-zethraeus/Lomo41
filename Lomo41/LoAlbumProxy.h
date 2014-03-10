#import <Foundation/Foundation.h>

@interface LoAlbumProxy : NSObject

@property (nonatomic, strong) NSMutableArray *assets;

- (id)initForAlbum: (NSString *)albumName;
- (void)addImage: (UIImage *)image;
- (void)deleteAssetAtIndex:(NSUInteger)index withCompletionBlock:(void(^)())block;
- (void)updateAssets;
- (void)updateAssetsWithCompletionBlock:(void(^)())block;
- (void)deleteAssetList:(NSMutableArray *)list withCompletionBlock:(void(^)())block;

@end
