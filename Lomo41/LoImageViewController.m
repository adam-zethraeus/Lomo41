//
//  LoImageViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/28/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoImageViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "LoAppDelegate.h"
#import "LoAlbumProxy.h"
#import "PhotoViewController.h"

@interface LoImageViewController()<UIPageViewControllerDataSource, UIPageViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIView *container;
@property (nonatomic) NSInteger currentIndex;
@property (nonatomic) NSInteger potentialNextIndex;
@property (nonatomic) NSInteger deleteIndex;
- (IBAction)doBack:(id)sender;
- (IBAction)doTrash:(id)sender;
- (IBAction)doShare:(id)sender;
@property (strong, nonatomic) UIPageViewController *pagerController;
@property (weak, nonatomic) LoAppDelegate *appDelegate;
@property (nonatomic) dispatch_queue_t sessionQueue;
@end

static void * AlbumAssetsRefreshContext = &AlbumAssetsRefreshContext;

@implementation LoImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSAssert(self.pagerController != nil, @"pagerController should have been set in prepareForSegue");
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    self.sessionQueue = dispatch_queue_create("collection view proxy queue", DISPATCH_QUEUE_SERIAL);
    self.deleteIndex = -1;
    self.currentIndex = self.initialIndex;
    self.potentialNextIndex = self.initialIndex;
    UIImage *initialImage = [self imageForIndex:self.initialIndex];
    self.pagerController.dataSource = self;
    self.pagerController.delegate = self;
    PhotoViewController *initialPage = [PhotoViewController photoViewControllerForIndex:self.initialIndex andImage:initialImage];
    if (initialPage != nil) {
        [self.pagerController setViewControllers:@[initialPage]
                                       direction:UIPageViewControllerNavigationDirectionForward
                                        animated:NO
                                      completion:NULL];
    }
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleToolbarVisibility)];
    tapGesture.numberOfTapsRequired = 1;
    [self.container addGestureRecognizer:tapGesture];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	if (context == AlbumAssetsRefreshContext) {
	}
}

-(void)refreshToIndex: (NSInteger)index {
    self.currentIndex = index;
    PhotoViewController *currentPage = [PhotoViewController photoViewControllerForIndex:index andImage:[self imageForIndex:index]];
    if (currentPage != nil) {
        [self.pagerController setViewControllers:@[currentPage]
                                       direction:UIPageViewControllerNavigationDirectionForward
                                        animated:NO
                                      completion:NULL];
    }
}

- (UIImage *)imageForIndex:(NSInteger)index {
    if (index < 0 || index >= self.appDelegate.album.assets.count) {
        return nil;
    }
    CGImageRef imageRef = [[self.appDelegate.album.assets[index] defaultRepresentation] fullResolutionImage];
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

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    self.potentialNextIndex = ((PhotoViewController *)pendingViewControllers.lastObject).index;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (!completed) {
        return;
    }
    self.currentIndex = self.potentialNextIndex;
}

- (IBAction)doBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doTrash:(id)sender {
    self.deleteIndex = self.currentIndex;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Picture"
                                                    message:@"Would you like to delete the picture?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil];
    [alert addButtonWithTitle:@"Delete"];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Deletion accepted.
    if (buttonIndex == 1) {
        NSAssert(self.deleteIndex >= 0, @"index for deletion was not set");
        if (self.appDelegate.album.assets.count > 1) {
            NSInteger newIndex = self.currentIndex < self.appDelegate.album.assets.count - 1 ? self.currentIndex : self.currentIndex - 1;
            __weak LoImageViewController *weakSelf = self;
            [self.appDelegate.album deleteAssetAtIndex:self.deleteIndex withCompletionBlock:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf refreshToIndex: newIndex];
                });
            }];
        } else {
            // We're about to empty the album. Exit after.
            __weak LoImageViewController *weakSelf = self;
            [self.appDelegate.album deleteAssetAtIndex:self.deleteIndex withCompletionBlock:^{
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }];
        }
    }
}

- (IBAction)doShare:(id)sender {
    ALAsset* assetToShare = self.appDelegate.album.assets[self.currentIndex];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[assetToShare] applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

-(void)toggleToolbarVisibility {
    if (self.toolbar.hidden) {
        [self animateToolbarVisibility: true];
    } else {
        [self animateToolbarVisibility: false];
    }

}

-(void)animateToolbarVisibility: (bool)visible {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            if (!visible) {
                self.toolbar.hidden = true;
            }
            self.container.backgroundColor = visible ? [UIColor whiteColor] : [UIColor blackColor];
		} completion:^(BOOL finished) {
            if (visible) {
                self.toolbar.hidden = false;
            }
        }];
	});
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"containedPager"]) {
        self.pagerController = (UIPageViewController *)segue.destinationViewController;
    }
}
@end
