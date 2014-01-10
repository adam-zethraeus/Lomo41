//
//  LoViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/10/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "LoCameraPreviewView.h"
#import "Lo41ShotProcessor.h"
#import "LoShotSet.h"

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningCameraPermissionContext = &SessionRunningCameraPermissionContext;

@interface LoViewController ()
@property (weak, nonatomic) IBOutlet UIView *shootView;
@property (weak, nonatomic) IBOutlet UIButton *shootButton;
@property (weak, nonatomic) IBOutlet LoCameraPreviewView *previewView;
@property (nonatomic) dispatch_queue_t sessionQueue; // todo: make global?
@property (nonatomic) ALAssetsLibrary *library;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) LoShotSet *currentShots;
@property (nonatomic) id runtimeErrorHandlingObserver;
@property (nonatomic, readonly, getter = isSessionRunningAndHasCameraPermission) BOOL sessionRunningAndHasCameraPermission;
@property (nonatomic) BOOL hasCameraPermission;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSInteger shotCount;
@property (nonatomic, readonly, getter = isCurrentlyShooting) BOOL isShooting;
- (IBAction)doShoot:(id)sender;
@end

@implementation LoViewController

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType
                      preferringPosition:(AVCaptureDevicePosition)position {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	AVCaptureDevice *captureDevice = [devices firstObject];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == position) {
			captureDevice = device;
			break;
		}
	}
	return captureDevice;
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device {
	if ([device hasFlash] && [device isFlashModeSupported:flashMode]) {
		NSError *error = nil;
		if ([device lockForConfiguration:&error]) {
			[device setFlashMode:flashMode];
			[device unlockForConfiguration];
		} else {
			NSLog(@"%@", error);
		}
	}
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndHasCameraPermission {
	return [NSSet setWithObjects:@"session.running", @"hasCameraPermission", nil];
}

- (BOOL)isCurrentlyShooting {
    NSAssert(self.shotCount <= 4, @"Shot count was > 4");
    return (self.shotCount > 0);
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)isSessionRunningAndHasCameraPermission {
	return self.session.isRunning && self.hasCameraPermission;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.session = [[AVCaptureSession alloc] init];
    self.library = [[ALAssetsLibrary alloc] init];
    self.previewView.session = self.session;
    self.currentShots = [[LoShotSet alloc] initForSize:4];
	[self checkCameraPermissions];
	self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	dispatch_async(self.sessionQueue, ^{
		//[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		NSError *error = nil;
		AVCaptureDevice *videoDevice = [LoViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        //TODO: lock these for sequential pictures
        if ([videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            if ([videoDevice lockForConfiguration:&error]) {
                CGPoint autofocusPoint = CGPointMake(0.5f, 0.5f);
                [videoDevice setFocusPointOfInterest:autofocusPoint];
                [videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                [videoDevice unlockForConfiguration];
            } else {
                NSLog(@"%@", error);
            }
        }
        if ([videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            if ([videoDevice lockForConfiguration:&error]) {
                CGPoint exposurePoint = CGPointMake(0.5f, 0.5f);
                [videoDevice setExposurePointOfInterest:exposurePoint];
                [videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            } else {
                NSLog(@"%@", error);
            }
        }
        [LoViewController setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		if (error) {
			NSLog(@"%@", error);
		}
		if ([self.session canAddInput:videoDeviceInput]) {
			[self.session addInput:videoDeviceInput];
			self.videoDeviceInput = videoDeviceInput;
		}
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([self.session canAddOutput:stillImageOutput]) {
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
			[self.session addOutput:stillImageOutput];
			self.stillImageOutput = stillImageOutput;
		}
    });
}

- (void)viewWillAppear:(BOOL)animated {
	dispatch_async(self.sessionQueue, ^{
		[self addObserver:self forKeyPath:@"sessionRunningAndHasCameraPermission" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningCameraPermissionContext];
		[self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
		__weak LoViewController *weakSelf = self;
		self.runtimeErrorHandlingObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
			LoViewController *strongSelf = weakSelf;
			dispatch_async(strongSelf.sessionQueue, ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[strongSelf.session startRunning];
			});
		}];
		[self.session startRunning];
	});
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.currentShots purge];
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    self.shotCount = 0;
}

- (void)viewDidDisappear:(BOOL)animated {
	dispatch_async(self.sessionQueue, ^{
		[self.session stopRunning];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		[[NSNotificationCenter defaultCenter] removeObserver:self.runtimeErrorHandlingObserver];
		[self removeObserver:self forKeyPath:@"sessionRunningAndHasCameraPermission" context:SessionRunningCameraPermissionContext];
        [self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
	});
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)hasRunningSessionAndCameraPermission {
	return self.session.isRunning && self.hasCameraPermission;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	if (context == CapturingStillImageContext) {
		BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
		if (isCapturingStillImage) {
			[self runCaptureAnimation];
		}
	} else if (context == SessionRunningCameraPermissionContext) {
        BOOL hasPermission = [change[NSKeyValueChangeNewKey] boolValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (hasPermission) {
                [self.shootButton setEnabled:YES];
            } else {
                [self.shootButton setEnabled:NO];
            }
        });
    }
}

- (IBAction)doShoot:(id)sender {
    if (!self.isShooting) {
        [self shootOnce];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(shootOnce) userInfo:nil repeats:YES];
    }
}

- (void)shootOnce {
    self.shotCount++;
    bool final = false;
    if (self.shotCount >= 4) {
        [self.timer invalidate];
        self.timer = nil;
        final = true;
    }
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        CFRetain(imageDataSampleBuffer);
        dispatch_async(self.sessionQueue, ^{
            if (imageDataSampleBuffer) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [self.currentShots addShot:[[UIImage alloc] initWithData:imageData]];
            }
            CFRelease(imageDataSampleBuffer);
            if (final) {
                [self processShotSet];
                self.shotCount = 0;
            }
        });
    }];
}

- (void)processShotSet {
    dispatch_async(self.sessionQueue, ^{
        Lo41ShotProcessor* processor = [[Lo41ShotProcessor alloc] initWithShotSet:self.currentShots];
        [processor processIndividualShots];
        [processor groupShots];
        UIImage *finalGroupedImage = [processor getProcessedGroupImage];
        if (finalGroupedImage) {
            [self.library saveImage:finalGroupedImage toAlbum:@"Lomo41" withCompletionBlock:nil];
        }
        [self.currentShots purge];
    });
}

- (void)runCaptureAnimation {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.shootView.layer setOpacity:0.0];
		[UIView animateWithDuration:.25 animations:^{
            [self.shootView.layer setOpacity:1.0];
		}];
	});
}

- (void)checkCameraPermissions {
	NSString *mediaType = AVMediaTypeVideo;
	[AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
		self.hasCameraPermission = granted;
		if (!granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
				[[[UIAlertView alloc] initWithTitle:@"Permission Issue"
											message:@"Lomo41 needs permission to access your camera. Please grant it in settings."
										   delegate:self
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
			});
        }
	}];
}
@end
