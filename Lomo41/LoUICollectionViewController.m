//
//  LoUICollectionViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/26/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoUICollectionViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

#import "ALAssetsLibrary+PhotoAlbumFunctionality.h"
#import "LoImagePreviewCell.h"
#import "LoImageViewController.h"
#import "LoAlbumProxy.h"
#import "LoAppDelegate.h"

static void * AlbumAssetsRefreshContext = &AlbumAssetsRefreshContext;

typedef enum AlbumState {
    DEFAULT,
    FLIPPED_CELL,
    SELECTION_ENABLED,
    DELETION_IN_PROGRESS
} AlbumState;

@interface LoUICollectionViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>
- (IBAction)doDelete:(id)sender;
- (IBAction)doDeleteSelection:(id)sender;
- (IBAction)doShare:(id)sender;
- (IBAction)doCellAction:(id)sender;
- (IBAction)doToggleSelect:(UIBarButtonItem *)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic) NSUInteger deleteIndex;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (strong, nonatomic) LoAppDelegate *appDelegate;
@property (strong, nonatomic) NSMutableSet *selectedAssets;
@property (nonatomic) AlbumState state;
@end

@implementation LoUICollectionViewController

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.sessionQueue = dispatch_queue_create("collection view proxy queue", DISPATCH_QUEUE_SERIAL);
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    NSAssert(self.appDelegate.album != nil, @"album should have been set on AppDelegate");
}

- (void)viewWillAppear: (BOOL)animated {
    [super viewWillAppear:animated];
    self.deleteIndex = -1;
    [self.collectionView reloadData];
    self.state = DEFAULT;
    dispatch_async(self.sessionQueue, ^{
        [self.appDelegate.album addObserver:self forKeyPath:@"assets" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:AlbumAssetsRefreshContext];
    });
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dispatch_async(self.sessionQueue, ^{
        [self.appDelegate.album updateAssets];
    });
}

- (void)viewWillDisappear: (BOOL)animated {
    [super viewWillDisappear:animated];
    [self resetState];
    dispatch_async(self.sessionQueue, ^{
        [self.appDelegate.album removeObserver:self forKeyPath:@"assets" context:AlbumAssetsRefreshContext];
    });
}

- (void)resetState {
    if (self.state == FLIPPED_CELL) {
        [self flipAllCellsToFrontInDirection:UIViewAnimationOptionTransitionFlipFromLeft];
    } else if (self.state == SELECTION_ENABLED) {
        self.deleteButton.enabled = false;
        self.selectButton.title = @"Select";
        self.selectedAssets = nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
    self.state = DEFAULT;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.appDelegate.album.assets.count;
}

- (LoImagePreviewCell *)collectionView: (UICollectionView *)collectionView cellForItemAtIndexPath: (NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"photoCell";
    ALAsset *asset = self.appDelegate.album.assets[self.appDelegate.album.assets.count - 1 - indexPath.row];
    CGImageRef thumbnailImageRef = [asset aspectRatioThumbnail];
    static BOOL nibMyCellLoaded = NO;
    if(!nibMyCellLoaded) {
        UINib *nib = [UINib nibWithNibName:@"photoCell" bundle: nil];
        [collectionView registerNib:nib forCellWithReuseIdentifier:CellIdentifier];
        nibMyCellLoaded = YES;
    }
    LoImagePreviewCell *cell = (LoImagePreviewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];

    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    cell.imageView.image = thumbnail;
    cell.frontView.hidden = NO;
    cell.backView.hidden = YES;

    if (self.state == SELECTION_ENABLED) {
        NSAssert(self.selectedAssets != nil, @"selectedAssets list must be available when state is SELECTION_ENABLED");
        if ([self.selectedAssets containsObject:asset]){
            cell.layer.borderColor = [self.navigationController.view.window.tintColor CGColor];
            cell.layer.borderWidth = 5.0;
        } else {
            cell.layer.borderWidth = 0;
        }
    } else {
        cell.layer.borderWidth = 0;
    }

    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    swipeRight.delegate = self;
    swipeRight.numberOfTouchesRequired = 1;
    [swipeRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [cell addGestureRecognizer:swipeRight];

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    swipeLeft.delegate = self;
    swipeLeft.numberOfTouchesRequired = 1;
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [cell addGestureRecognizer:swipeLeft];

    return cell;
}

- (void)didSwipe: (UISwipeGestureRecognizer *)recognizer {
    if (self.state != DEFAULT && self.state != FLIPPED_CELL) {
        return;
    }
    LoImagePreviewCell *cell = (LoImagePreviewCell *)recognizer.view;
    UIViewAnimationOptions direction = UIViewAnimationOptionTransitionFlipFromLeft;
    if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        direction = UIViewAnimationOptionTransitionFlipFromRight;
    }
    self.state = FLIPPED_CELL;
    if (!cell.frontView.isHidden) {
        [self flipAllCellsToFrontInDirection: direction];
        dispatch_async(dispatch_get_main_queue(), ^{
            [LoUICollectionViewController flipToBackOfCell:cell inDirection:direction];
        });
    } else {
        [self flipAllCellsToFrontInDirection: direction];
    }
}

- (void)flipAllCellsToFrontInDirection: (UIViewAnimationOptions) direction {
    dispatch_async(dispatch_get_main_queue(), ^{
        for (LoImagePreviewCell *cell in self.collectionView.visibleCells) {
            [LoUICollectionViewController flipToFrontOfCell:cell inDirection:direction];
        }
    });
}

+ (void)flipToFrontOfCell: (LoImagePreviewCell *)cell inDirection: (UIViewAnimationOptions) direction {
    if (cell.frontView.isHidden) {
        [UIView transitionWithView:cell
                          duration:0.2f
                           options:direction
                        animations:^{
                            cell.frontView.hidden = NO;
                            cell.backView.hidden = YES;
                        } completion:nil];
    }
}

+ (void)flipToBackOfCell: (LoImagePreviewCell *)cell inDirection: (UIViewAnimationOptions) direction {
    if (!cell.frontView.isHidden) {
        [UIView transitionWithView:cell
                          duration:0.2f
                           options:direction
                        animations:^{
                            cell.frontView.hidden = YES;
                            cell.backView.hidden = NO;
                        } completion:nil];
    }
}

- (IBAction)doDelete:(id)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)((UIView *)sender).superview.superview.superview];
    self.deleteIndex = self.appDelegate.album.assets.count - 1 - indexPath.row;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Picture"
                                                    message:@"Would you like to delete the picture?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil];
    [alert addButtonWithTitle:@"Delete"];
    [alert show];
}

- (IBAction)doDeleteSelection:(id)sender {
    if (self.selectedAssets.count < 1) {
        return;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Pictures"
                                                    message:@"Would you like to delete the selected pictures?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil];
    [alert addButtonWithTitle:@"Delete"];
    [alert show];
}

- (IBAction)doShare:(id)sender {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)((UIView *)sender).superview.superview.superview];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[self.appDelegate.album.assets[self.appDelegate.album.assets.count - 1 - indexPath.row]] applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (IBAction)doCellAction:(id)sender {
    if (self.state == FLIPPED_CELL) {
        [self resetState];
    } else if (self.state == SELECTION_ENABLED){
        NSIndexPath *indexPath = [self.collectionView indexPathForCell: (UICollectionViewCell *)((UIView *)sender).superview.superview.superview];
        NSInteger index = self.appDelegate.album.assets.count - 1 - indexPath.row;
        ALAsset *asset = self.appDelegate.album.assets[index];
        if ([self.selectedAssets containsObject:asset]) {
            [self.selectedAssets removeObject:asset];
        } else {
            [self.selectedAssets addObject:asset];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    } else {
        [self performSegueWithIdentifier: @"viewImage" sender: ((UIView *)sender).superview.superview.superview];
    }
}

- (IBAction)doToggleSelect:(UIBarButtonItem *)sender {
    NSAssert(sender == self.selectButton, @"select toggle sender was not known select button");
    if (self.state == SELECTION_ENABLED) {
        [self resetState];
    } else {
        self.state = SELECTION_ENABLED;
        [self flipAllCellsToFrontInDirection:UIViewAnimationOptionTransitionFlipFromLeft];
        self.deleteButton.enabled = true;
        self.selectButton.title = @"Cancel";
        self.selectedAssets = [[NSMutableSet alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewImage"]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:(UICollectionViewCell *)sender];
        LoImageViewController *destViewController = segue.destinationViewController;
        destViewController.initialIndex = self.appDelegate.album.assets.count - 1 - indexPath.row;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (self.state == FLIPPED_CELL) {
            NSAssert(self.deleteIndex >= 0, @"index for delete action most be set for deletion in FLIPPED_CELL state.");
            [self.appDelegate.album deleteAssetAtIndex:self.deleteIndex];
        } else if (self.state == SELECTION_ENABLED) {
            NSAssert(self.selectedAssets != nil, @"selectedAssets set must exist for deletion in SELECTION_ENABLED state.");
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Deletion in progress"
                                                                message:@"brb"
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];
                [alert show];
                dispatch_async(self.sessionQueue, ^(){
                    [self.appDelegate.album deleteAssetList: [NSMutableArray arrayWithArray:[self.selectedAssets allObjects]]
                                        withCompletionBlock:^(){
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [alert dismissWithClickedButtonIndex:0 animated:YES];
                                            });
                                        }];
                });
            });
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	if (context == AlbumAssetsRefreshContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self resetState];
        });
	}
}


@end
