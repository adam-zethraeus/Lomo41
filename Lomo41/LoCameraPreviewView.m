#import "LoCameraPreviewView.h"

#import <AVFoundation/AVFoundation.h>

@implementation LoCameraPreviewView

+ (Class)layerClass {
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session {
	return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session {
	[(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

@end
