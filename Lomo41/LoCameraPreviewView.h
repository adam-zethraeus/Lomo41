//
//  LoCameraPreviewView.h
//  Lomo41
//
//  Created by Adam Zethraeus on 1/5/14.
//  Copyright (c) 2014 Very Nice Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;

@interface LoCameraPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@end
