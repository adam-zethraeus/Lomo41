//
//  UIImage+RotationFunctionality.h
//  Lomo41
//
//  Created by Adam Zethraeus on 3/9/14.
//  Copyright (c) 2014 Very Nice Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (RotationFunctionality)

- (BOOL)isLandscape;
+ (UIImage *)landscapeVersionOfImage: (UIImage *)image;

@end
