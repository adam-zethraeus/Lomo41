//
//  LoShotProcessor.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/20/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "Lo41ShotProcessor.h"

#import "GPUImage.h"

const static float paddingRatio = 1.0/250.0;
const static GPUVector3 backgroundColor =  {0.1, 0.1, 0.1};
const static float vignetteStart = 0.4;
const static float vignetteEnd = 0.8;
const static float saturationLevel = 0.85;

@interface Lo41ShotProcessor ()

@property (nonatomic) LoShotSet *shotSet;
@property (nonatomic) NSMutableArray *postProcessedIndividualShots;
@property (nonatomic) UIImage *groupedImage;

@end

@implementation Lo41ShotProcessor
- (id)initWithShotSet: (LoShotSet*) set {
    self = [super init];
    if (self) {
        if (set.count != 4) {
            @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Lo41ShotProcessor needs a LoShotSet of size 4." userInfo:nil];
        }
        self.shotSet = set;
    }
    return self;
}

- (id)init {
    @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Please init Lo41ShotProcessor with initWithShotSet." userInfo:nil];
    return nil;
}

- (void)processIndividualShots {
    if (!self.shotSet) {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Shots must be availabele to process." userInfo:nil];
    }
    self.postProcessedIndividualShots = [NSMutableArray arrayWithCapacity:4];
    for (int i = 0; i < 4; i++){
        UIImage *image = [UIImage imageWithCGImage:[[self.shotSet.getShotsArray objectAtIndex:i] CGImage]
                                             scale:1.0
                                       orientation:UIImageOrientationUp];
        CGRect cropRect = CGRectMake((image.size.width/4.0) + ((image.size.width/8.0) * i), 0, image.size.width/4.0, image.size.height);
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
        NSAssert(imageRef != NULL, @"image crop failed");
        UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
        GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:croppedImage];
        GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
        vignetteFilter.vignetteColor = backgroundColor;
        vignetteFilter.vignetteStart = vignetteStart;
        vignetteFilter.vignetteEnd = vignetteEnd;
        GPUImageSaturationFilter *saturationFilter = [[GPUImageSaturationFilter alloc] init];
        saturationFilter.saturation = saturationLevel;
        [stillImageSource addTarget:saturationFilter];
        [saturationFilter addTarget:vignetteFilter];
        [stillImageSource processImage];
        
        UIImage *processedImage = [vignetteFilter imageFromCurrentlyProcessedOutput];
        [self.postProcessedIndividualShots addObject:processedImage];
        CGImageRelease(imageRef);
    }
}

- (void)groupShots {
    if (!self.postProcessedIndividualShots) {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Shots must processed individually before grouping." userInfo:nil];
    }
    CGSize shotSize = [[self.shotSet.getShotsArray objectAtIndex:0] size];
    NSAssert(shotSize.height > shotSize.width, @"Assumption height > width failed.");
    CGFloat padding = shotSize.height * paddingRatio;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(shotSize.height + (padding * 3.0), shotSize.width), YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context, backgroundColor.one, backgroundColor.two, backgroundColor.three, 1.0);
    for (int i = 0; i < 4; i++) {
        CGContextSaveGState(context);
        UIImage *image = [self.postProcessedIndividualShots objectAtIndex:i];
        CGRect drawRect = CGRectMake((image.size.width + padding) * i, 0, image.size.width, image.size.height);
        CGContextTranslateCTM(context, 0, image.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextDrawImage(context, drawRect, image.CGImage);
        CGContextRestoreGState(context);
    }
    self.groupedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (UIImage*)getProcessedGroupImage {
    if (!self.groupedImage) {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Shots must be grouped before final processing." userInfo:nil];
    }
    return self.groupedImage;
}
@end
