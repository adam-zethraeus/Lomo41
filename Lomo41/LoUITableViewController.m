//
//  LoUITableViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/26/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoUITableViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

@interface LoUITableViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) ALAssetsGroup *album;
@property (nonatomic) NSMutableArray *pictures;
@property (nonatomic) ALAssetsLibrary *library;
@end

@implementation LoUITableViewController

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.pictures) {
        self.pictures = [[NSMutableArray alloc] init];
    } else {
        [self.pictures removeAllObjects];
    }
    if (!self.library) {
        self.library = [[ALAssetsLibrary alloc] init];
    }
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([@"Lomo41" compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
                                        self.album = group;
                                        ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                            if (result) {
                                                [self.pictures addObject:result];
                                            }
                                        };
                                        
                                        ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
                                        [self.album setAssetsFilter:onlyPhotosFilter];
                                        [self.album enumerateAssetsUsingBlock:assetsEnumerationBlock];
                                    }
                                }
                              failureBlock:^(NSError* er){
                                  self.album = nil;
                              }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    self.album = nil;
    [self.pictures removeAllObjects];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.pictures.count;
}

#define kImageViewTag 2
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    ALAsset *asset = self.pictures[self.pictures.count - 1 - indexPath.row];
    CGImageRef thumbnailImageRef = [[asset defaultRepresentation] fullScreenImage];
    UIImage *thumbnail = [UIImage imageWithCGImage:thumbnailImageRef];
    cell.backgroundView = [[UIImageView alloc] initWithImage:thumbnail];
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:thumbnail];
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
