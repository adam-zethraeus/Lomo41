//
//  LoCameraPreviewView.m
//  Lomo41
//
//  Created by Adam Zethraeus on 1/5/14.
//  Copyright (c) 2014 Very Nice Co. All rights reserved.
//

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
