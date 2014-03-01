//
//  LoAppDelegate.h
//  Lomo41
//
//  Created by Adam Zethraeus on 12/10/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoAlbumProxy;

@interface LoAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LoAlbumProxy *album;

@end
