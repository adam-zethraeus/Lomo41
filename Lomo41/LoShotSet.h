//
//  LoShotSet.h
//  Lomo41
//
//  Created by Adam Zethraeus on 12/20/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

@interface LoShotSet : NSObject

@property (nonatomic, readonly, getter = getCount) NSUInteger count;

// Init with intended size. Default init is 4.
- (id)initForSize: (NSUInteger) size;

// Be aware, addShot will fail silently if you attempt to add more shots
// than the set was specified to be able to contain.
- (void)addShot:(UIImage *)image;

- (NSArray*)getShotsArray;

// Purge the set's memebers.
- (void)purge;

@end
