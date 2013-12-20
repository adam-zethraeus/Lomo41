//
//  LoShotSet.h
//  Lomo41
//
//  Created by Adam Zethraeus on 12/20/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoShotSet : NSObject
@property (nonatomic) NSMutableArray *shots; //TODO: make private
@property (nonatomic, readonly, getter = getCount) NSUInteger count;
- (void)addShot:(UIImage *)image;
- (void)purge;
@end
