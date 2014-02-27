//
//  LoAlbumProxy.h
//  Lomo41
//
//  Created by Adam Zethraeus on 1/11/14.
//  Copyright (c) 2014 Very Nice Co. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoAlbumProxy : NSObject

@property (nonatomic) NSMutableArray *assets;

- (id)initForAlbum: (NSString *)albumName;
- (void)addImage: (UIImage *)image;
- (void)deleteAssetAtIndex: (NSUInteger)index;
- (void)updateAssets;

@end
