//
//  LoImageViewController.h
//  Lomo41
//
//  Created by Adam Zethraeus on 12/28/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ALAsset;

@interface LoImageViewController : UIPageViewController
@property (nonatomic, strong) NSArray *assetList;
@property (nonatomic) NSInteger initialIndex;
@end
