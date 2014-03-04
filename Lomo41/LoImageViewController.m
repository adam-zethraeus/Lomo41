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
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleToolbarVisibility)];
    tapGesture.numberOfTapsRequired = 1;
    [self.container addGestureRecognizer:tapGesture];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    dispatch_async(self.sessionQueue, ^{
        [self.appDelegate.album addObserver:self forKeyPath:@"assets" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:AlbumAssetsRefreshContext];
    });
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    dispatch_async(self.sessionQueue, ^{
        [self.appDelegate.album removeObserver:self forKeyPath:@"assets" context:AlbumAssetsRefreshContext];
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
            // Do a full refresh
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
    NSLog(@"trash");
}

- (IBAction)doShare:(id)sender {
    NSLog(@"share");
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
