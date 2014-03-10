#import "GPUImageFilterGroup.h"

@class GPUImagePicture;

@interface LoDefaultFilter : GPUImageFilterGroup {
    GPUImagePicture *lookupImageSource;
}

@end
