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

//Inputs
@property (nonatomic) UIDeviceOrientation orientation;
@property (nonatomic) CameraType cameraType;

//Settings
@property (nonatomic) float paddingToClipRatio;
@property (nonatomic) GPUVector3 backgroundColor;
@property (nonatomic) float vignetteStart;
@property (nonatomic) float vignetteEnd;
@property (nonatomic) float blurExcludeRadius;
@property (nonatomic) float blurSize;
@property (nonatomic) float clipSpan;

//State
@property (nonatomic) CGPoint inputSize;
@property (nonatomic) CGPoint outputSize;
@property (nonatomic) CGPoint clipSize;
@property (nonatomic) CGFloat clipRatio;
@property (nonatomic) CGFloat clipStartPoint;
@property (nonatomic) CGFloat clipPointIncrements;
@property (nonatomic) CGFloat padding;
@property (getter = getCount, readonly) NSInteger count;


- (id)initWithDelegate:(id<LoShotDataDelegate>)delegate;
- (void)addImage:(UIImage *)shot toLocation:(PaneLocation)location;
- (void)invalidate;

@end
