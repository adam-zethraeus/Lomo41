#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface LoCameraPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
