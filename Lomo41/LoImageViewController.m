//
//  LoImageViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/28/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoImageViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

@interface LoImageViewController()<UIScrollViewDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation LoImageViewController

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    CGImageRef imageRef = [[self.asset defaultRepresentation] fullResolutionImage];
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationRight];
    self.imageView.image = image;
}

-(UIView *) viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

@end
