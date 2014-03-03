//
//  LoImageViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/28/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoImageViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "PhotoViewController.h"

@interface LoImageViewController()<UIPageViewControllerDataSource>
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIView *container;
- (IBAction)doBack:(id)sender;
- (IBAction)doTrash:(id)sender;
- (IBAction)doShare:(id)sender;
@end

@implementation LoImageViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
//    make UIPageViewController
    NSLog(@"%@", self.container);

}

- (UIImage *)imageForIndex:(NSInteger)index {
    if (index < 0 || index >= self.assetList.count) {
        return nil;
    }
    CGImageRef imageRef = [[self.assetList[index] defaultRepresentation] fullResolutionImage];
    return [UIImage imageWithCGImage:imageRef scale:1.0f orientation:UIImageOrientationRight];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc
      viewControllerBeforeViewController:(PhotoViewController *)vc {
    NSUInteger index = vc.index + 1;
    return [PhotoViewController photoViewControllerForIndex:index andImage:[self imageForIndex:index]];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pvc
       viewControllerAfterViewController:(PhotoViewController *)vc {
    NSUInteger index = vc.index - 1;
    return [PhotoViewController photoViewControllerForIndex:index andImage:[self imageForIndex:index]];
}
- (IBAction)doBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doTrash:(id)sender {
    NSLog(@"trash");
}

- (IBAction)doShare:(id)sender {
    NSLog(@"share");
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"containedPager"]) {
        UIPageViewController *pagerController = (UIPageViewController *)segue.destinationViewController;
        UIImage *initialImage = [self imageForIndex:self.initialIndex];
        pagerController.dataSource = self;
        PhotoViewController *initialPage = [PhotoViewController photoViewControllerForIndex:self.initialIndex andImage:initialImage];
        if (initialPage != nil) {
            [pagerController setViewControllers:@[initialPage]
                           direction:UIPageViewControllerNavigationDirectionForward
                            animated:NO
                          completion:NULL];
        }
    }
}
@end
