//
//  LoUICollectionViewController.h
//  Lomo41
//
//  Created by Adam Zethraeus on 12/26/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoAlbumProxy;

@interface LoUICollectionViewController : UICollectionViewController
@property (nonatomic) LoAlbumProxy *albumProxy;
@end
