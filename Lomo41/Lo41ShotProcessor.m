//
//  LoShotProcessor.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/20/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "Lo41ShotProcessor.h"

#import "GPUImage.h"

const static float paddingToClipRatio = 1.0/70.0;
const static GPUVector3 backgroundColor =  {0.1, 0.1, 0.1};
const static float vignetteStart = 0.4;
const static float vignetteEnd = 0.8;
// Distance across the center than clips can be taken from. Max 1.0.
const static float clipSpan = 0.5;

@interface Lo41ShotProcessor ()

@property (nonatomic) LoShotSet *shotSet;
@property (nonatomic) NSMutableArray *postProcessedIndividualShots;
@property (nonatomic) UIImage *groupedImage;
@property (nonatomic) CGPoint inputSize;
@property (nonatomic) CGPoint outputSize;
@property (nonatomic) CGPoint clipSize;
@property (nonatomic) CGFloat clipRatio;
@property (nonatomic) CGFloat clipStartPoint;
@property (nonatomic) CGFloat clipPointIncrements;
@property (nonatomic) CGFloat padding;
@end

@implementation Lo41ShotProcessor
- (id)initWithShotSet: (LoShotSet*) set {
    self = [super init];
    if (self) {
        if (set.count != 4) {
            NSLog(@"shot set size was: %lu", (unsigned long)set.count);
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

- (void)calculateOutputSizesFromImage: (UIImage *)image {
    CGFloat longEdge = (image.size.width > image.size.height) ? image.size.width : image.size.height;
    CGFloat shortEdge = (image.size.width < image.size.height) ? image.size.width : image.size.height;
    CGPoint inputSize;
    inputSize.x = longEdge;
    inputSize.y = shortEdge;
    self.inputSize = inputSize;

    CGFloat length4 = shortEdge;
    CGFloat length6 = length4 * 1.5;
    CGPoint outputSize;
    outputSize.x = length6;
    outputSize.y = length4;
    self.outputSize = outputSize;

    CGFloat shortClipEdgeLength = self.outputSize.x / (4.0 + (3.0 * paddingToClipRatio));
    CGFloat padding = paddingToClipRatio * shortClipEdgeLength;
    self.padding = padding;
    
    CGFloat longClipEdgeLength = length4;
    CGPoint clipSize;
    clipSize.x = shortClipEdgeLength;
    clipSize.y = longClipEdgeLength;
    self.clipSize = clipSize;
    
    self.clipRatio = shortClipEdgeLength / longEdge;
    
    CGFloat clipStartPoint = (1.0 - clipSpan)/2;
    self.clipStartPoint = clipStartPoint;

    CGFloat clipEndPoint = 1.0 - clipStartPoint - self.clipRatio;
    CGFloat clipPointSpan = clipEndPoint - clipStartPoint;
    CGFloat clipPointIncrements = clipPointSpan / 3.0;
    self.clipPointIncrements = clipPointIncrements;
    
}

- (void)processIndividualShots {
    if (!self.shotSet) {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Shots must be availabele to process." userInfo:nil];
    }
    [self calculateOutputSizesFromImage:[self.shotSet.getShotsArray objectAtIndex:0]];
    self.postProcessedIndividualShots = [NSMutableArray arrayWithCapacity:4];
    for (int i = 0; i < 4; i++){
        GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:[self.shotSet.getShotsArray objectAtIndex:i]];

        CGRect cropRect;
        cropRect.origin.x = self.clipStartPoint + (self.clipPointIncrements * (float) i);
        cropRect.origin.y = 0;
        cropRect.size.width = self.clipRatio;
        cropRect.size.height = 1.0;
        GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:cropRect];;

        GPUImageMissEtikateFilter *missEtikateFilter = [[GPUImageMissEtikateFilter alloc] init];

        GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
        vignetteFilter.vignetteColor = backgroundColor;
        vignetteFilter.vignetteStart = vignetteStart;
        vignetteFilter.vignetteEnd = vignetteEnd;

        [stillImageSource addTarget:cropFilter];
        [cropFilter addTarget:missEtikateFilter];
        [missEtikateFilter addTarget:vignetteFilter];
        [stillImageSource processImage];
        UIImage *processedImage = [vignetteFilter imageFromCurrentlyProcessedOutputWithOrientation:UIImageOrientationUp];
        [self.postProcessedIndividualShots addObject:processedImage];
    }
}

- (void)groupShots {
    if (!self.postProcessedIndividualShots) {
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:@"Shots must processed individually before grouping." userInfo:nil];
    }
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.outputSize.x, self.outputSize.y), YES, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(context, backgroundColor.one, backgroundColor.two, backgroundColor.three, 1.0);
    for (int i = 0; i < 4; i++) {
        CGContextSaveGState(context);
        UIImage *image = [self.postProcessedIndividualShots objectAtIndex:i];
        NSAssert(image.size.height > image.size.width, @"Assumption height > width failed.");
        CGRect drawRect = CGRectMake((self.clipSize.x + self.padding) * i, 0, self.clipSize.x, self.clipSize.y);
        CGContextTranslateCTM(context, 0, self.clipSize.y);
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
