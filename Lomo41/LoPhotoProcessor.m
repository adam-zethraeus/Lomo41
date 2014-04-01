#import "LoPhotoProcessor.h"

#import "GPUImage.h"
#import "LoDefaultFilter.h"

@implementation LoPhotoProcessor {
    NSMutableArray *_shotDataArray;
}

- (id)init {
    self = [super init];
    if (self) {
        _shotDataArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSUInteger)getCount {
    return [_shotDataArray count];
}

- (LoShotData *)newShotHandle {
    LoShotData *data = [[LoShotData alloc] initWithDelegate:self];
    data.paddingToClipRatio = 1.0f/45.0f;
    GPUVector3 color = {0.1,0.1,0.1};
    data.backgroundColor = color;
    data.vignetteStart = 0.4f;
    data.vignetteEnd = 1.4f;
    data.blurExcludeRadius = 0.6f;
    data.blurSize = 0.3f;
    data.clipSpan = 0.4f;
    return data;
}

- (void)processImage:(UIImage *)image
          atLocation:(PaneLocation)location
            withData:(LoShotData *)data {
    if (data.count == 0) {
        CGFloat longEdge = (image.size.width > image.size.height) ? image.size.width : image.size.height;
        CGFloat shortEdge = (image.size.width < image.size.height) ? image.size.width : image.size.height;
        CGPoint inputSize;
        inputSize.x = longEdge;
        inputSize.y = shortEdge;
        data.inputSize = inputSize;

        CGFloat length4 = shortEdge;
        CGFloat length6 = length4 * 1.5;
        CGPoint outputSize;
        outputSize.x = length6;
        outputSize.y = length4;
        data.outputSize = outputSize;

        CGFloat shortClipEdgeLength = data.outputSize.x / (4.0 + (3.0 * data.paddingToClipRatio));
        CGFloat padding = data.paddingToClipRatio * shortClipEdgeLength;
        data.padding = padding;

        CGFloat longClipEdgeLength = length4;
        CGPoint clipSize;
        clipSize.x = shortClipEdgeLength;
        clipSize.y = longClipEdgeLength;
        data.clipSize = clipSize;

        data.clipRatio = shortClipEdgeLength / longEdge;

        CGFloat clipStartPoint = (1.0 - data.clipSpan)/2;
        data.clipStartPoint = clipStartPoint;

        CGFloat clipEndPoint = 1.0 - clipStartPoint - data.clipRatio;
        CGFloat clipPointSpan = clipEndPoint - clipStartPoint;
        CGFloat clipPointIncrements = clipPointSpan / 3.0;
        data.clipPointIncrements = clipPointIncrements;
    }
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:image];

    int i = (int)location;
    CGRect cropRect;
    cropRect.origin.x = data.clipStartPoint + (data.clipPointIncrements * (float) i);
    cropRect.origin.y = 0;
    cropRect.size.width = data.clipRatio;
    cropRect.size.height = 1.0;
    GPUImageCropFilter *cropFilter = [[GPUImageCropFilter alloc] initWithCropRegion:cropRect];
    GPUImageVignetteFilter *vignetteFilter = [[GPUImageVignetteFilter alloc] init];
    vignetteFilter.vignetteColor = data.backgroundColor;
    vignetteFilter.vignetteStart = data.vignetteStart;
    vignetteFilter.vignetteEnd = data.vignetteEnd;
    LoDefaultFilter *lomoFilter = [[LoDefaultFilter alloc] init];

    GPUImageGaussianSelectiveBlurFilter *gaussianFilter = [[GPUImageGaussianSelectiveBlurFilter alloc] init];
    gaussianFilter.excludeCircleRadius = data.blurExcludeRadius;
    gaussianFilter.excludeCirclePoint = CGPointMake(0.5, 0.5);
    gaussianFilter.excludeBlurSize = data.blurSize;

    [stillImageSource addTarget:cropFilter];
    [cropFilter addTarget:lomoFilter];
    [lomoFilter addTarget:gaussianFilter];
    [gaussianFilter addTarget:vignetteFilter];
    [stillImageSource processImage];

    UIImage *processedImage = [vignetteFilter imageFromCurrentlyProcessedOutputWithOrientation:UIImageOrientationUp];
    [data addImage:processedImage toLocation:location];
}

- (void)saveImageFromData:(LoShotData *)data {
    NSLog(@"saveImageFromData");
}

- (void)invalidateData:(LoShotData *)data {
    [_shotDataArray removeObject:data];
}

- (void)dataComplete: (LoShotData *) sender {
    [self saveImageFromData:sender];
}

@end
