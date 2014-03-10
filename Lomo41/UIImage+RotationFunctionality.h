#import <UIKit/UIKit.h>

@interface UIImage (RotationFunctionality)

- (BOOL)isLandscape;
+ (UIImage *)landscapeVersionOfImage: (UIImage *)image;

@end
