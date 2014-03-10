//
//  UIImage+RotationFunctionality.m
//  Lomo41
//
//  Created by Adam Zethraeus on 3/9/14.
//  Copyright (c) 2014 Very Nice Co. All rights reserved.
//

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
