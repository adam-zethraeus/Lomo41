#import <Foundation/Foundation.h>

#import "GPUImage.h"

@class LoShotData;

@protocol LoShotDataDelegate <NSObject>
- (void) dataComplete: (LoShotData *) sender;
@end

@interface LoShotData : NSObject

typedef enum {
    BACK_FACING,
    FRONT_FACING
} CameraType;

typedef enum {
    LEFTMOST = 0,
    MIDDLE_LEFT = 1,
    MIDDLE_RIGHT = 2,
    RIGHTMOST = 3
} PaneLocation;

@property (nonatomic) UIDeviceOrientation orientation;
@property (nonatomic) CameraType cameraType;
@property (nonatomic) CGPoint inputSize;

@property (nonatomic) float paddingToClipRatio;
@property (nonatomic) GPUVector3 backgroundColor;
@property (nonatomic) float vignetteStart;
@property (nonatomic) float vignetteEnd;
@property (nonatomic) float blurExcludeRadius;
@property (nonatomic) float blurSize;
@property (nonatomic) float clipSpan;

- (id)initWithDelegate:(id<LoShotDataDelegate>)delegate;
- (void)addImage:(UIImage *)shot toLocation:(PaneLocation)location;
- (void)invalidate;

@end
