#import "UIImage+RotationFunctionality.h"

@implementation UIImage (RotationFunctionality)

- (BOOL)isLandscape {
    return self.size.width > self.size.height;
}

+ (UIImage *)landscapeVersionOfImage: (UIImage *)image {
    if (![image isLandscape]) {
        image = [[UIImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeft];
    }
    return image;
}

@end
