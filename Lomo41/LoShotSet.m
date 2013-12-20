//
//  LoShotSet.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/20/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoShotSet.h"

@interface LoShotSet ()
@end

@implementation LoShotSet

- (id)init {
    self.shots = [NSMutableArray arrayWithCapacity:4];
    return [super init];
}

- (void)addShot:(UIImage *)image {
    [self.shots addObject:image];
}

- (NSUInteger)getCount {
    return self.shots.count;
}

- (void)purge {
    [self.shots removeAllObjects];
}

@end
