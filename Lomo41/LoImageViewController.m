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
@property BOOL registeredForKVO;
@end

static void * AlbumAssetsRefreshContext = &AlbumAssetsRefreshContext;

@implementation LoImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSAssert(self.pagerController != nil, @"pagerController should have been set in prepareForSegue");
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    self.sessionQueue = dispatch_queue_create("collection view proxy queue", DISPATCH_QUEUE_SERIAL);
    self.deleteIndex = -1;
    self.registeredForKVO = NO;
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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_async(self.sessionQueue, ^{
        // This hack is present because when activating doShare UIActivityViewController
        // viewWillDisappear is not called. But viewWillAppear is called when exiting it.
        if (!self.registeredForKVO) {
            [self.appDelegate.album addObserver:self forKeyPath:@"assets" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:AlbumAssetsRefreshContext];
            self.registeredForKVO = YES;
        }
    });
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    dispatch_async(self.sessionQueue, ^{
        // See note in viewWillAppear.
        if(self.registeredForKVO) {
            [self.appDelegate.album removeObserver:self forKeyPath:@"assets" context:AlbumAssetsRefreshContext];
            self.registeredForKVO = NO;
        }
    });
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	if (context == AlbumAssetsRefreshContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"refresh?");
        });
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
    NSLog(@"current index: %lu", self.currentIndex);
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
    if (buttonIndex == 1) {
        NSAssert(self.deleteIndex >= 0, @"index for action was not set");
        [self.appDelegate.album deleteAssetAtIndex:self.deleteIndex];
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
