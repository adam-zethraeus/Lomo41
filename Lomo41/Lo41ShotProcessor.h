//
//  LoShotProcessor.h
//  Lomo41
//
//  Created by Adam Zethraeus on 12/20/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LoShotSet.h"

@interface Lo41ShotProcessor : NSObject

- (id)initWithShotSet: (LoShotSet*) set;

- (void)processIndividualShots;

- (void)groupShots;

- (UIImage*)getProcessedGroupImage;

@end
