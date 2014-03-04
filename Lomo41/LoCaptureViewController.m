//
//  LoViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/10/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoCaptureViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

#import "ALAssetsLibrary+PhotoAlbumFunctionality.h"
#import "LoCameraPreviewView.h"
#import "Lo41ShotProcessor.h"
#import "LoShotSet.h"
#import "LoAlbumProxy.h"
#import "LoUICollectionViewController.h"
#import "LoAppDelegate.h"

static void * SessionRunningCameraPermissionContext = &SessionRunningCameraPermissionContext;

@interface LoCaptureViewController ()
@property (weak, nonatomic) IBOutlet UIView *shootView;
@property (weak, nonatomic) IBOutlet UIButton *shootButton;
@property (weak, nonatomic) IBOutlet LoCameraPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIView *paneOne;
@property (weak, nonatomic) IBOutlet UIView *paneTwo;
@property (weak, nonatomic) IBOutlet UIView *paneThree;
@property (weak, nonatomic) IBOutlet UIView *paneFour;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) LoShotSet *currentShots;
@property (nonatomic) id runtimeErrorHandlingObserver;
@property (nonatomic, readonly, getter = isSessionRunningAndHasCameraPermission) BOOL sessionRunningAndHasCameraPermission;
@property (nonatomic) BOOL hasCameraPermission;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSInteger shotCount;
@property (nonatomic, readonly, getter = isCurrentlyShooting) BOOL isShooting;
@property (weak, nonatomic) LoAppDelegate *appDelegate;
- (IBAction)doShoot:(id)sender;
@end

@implementation LoCaptureViewController

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
	return [NSSet setWithObjects:@"captureSession.running", @"hasCameraPermission", nil];
}

- (BOOL)isCurrentlyShooting {
    NSAssert(self.shotCount <= 4, @"Shot count was > 4");
    return (self.shotCount > 0);
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)isSessionRunningAndHasCameraPermission {
	return self.captureSession.isRunning && self.hasCameraPermission;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    NSAssert(self.appDelegate.album != nil, @"album should have been set on AppDelegate");
    self.captureSession = [[AVCaptureSession alloc] init];
    self.currentShots = [[LoShotSet alloc] initForSize:4];
	[self checkCameraPermissions];
	self.sessionQueue = dispatch_queue_create("capture session queue", DISPATCH_QUEUE_SERIAL);
	dispatch_async(self.sessionQueue, ^{
		NSError *error = nil;
		AVCaptureDevice *videoDevice = [LoCaptureViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
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
        [LoCaptureViewController setFlashMode:AVCaptureFlashModeOff forDevice:videoDevice];
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		if (error) {
			NSLog(@"%@", error);
		}
		if ([self.captureSession canAddInput:videoDeviceInput]) {
			[self.captureSession addInput:videoDeviceInput];
			self.videoDeviceInput = videoDeviceInput;
		}
		AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
		if ([self.captureSession canAddOutput:stillImageOutput]) {
			[stillImageOutput setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
			[self.captureSession addOutput:stillImageOutput];
			self.stillImageOutput = stillImageOutput;
		}
        self.previewView.session = self.captureSession;
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	dispatch_async(self.sessionQueue, ^{
		[self addObserver:self forKeyPath:@"sessionRunningAndHasCameraPermission" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningCameraPermissionContext];
		__weak LoCaptureViewController *weakSelf = self;
		self.runtimeErrorHandlingObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self captureSession] queue:nil usingBlock:^(NSNotification *note) {
			LoCaptureViewController *strongSelf = weakSelf;
			dispatch_async(strongSelf.sessionQueue, ^{
				// Manually restarting the session since it must have been stopped due to an error.
				[strongSelf.captureSession startRunning];
			});
		}];
		[self.captureSession startRunning];
	});
    self.shotCount = 0;
    [self.paneOne.layer setOpacity: 1.0];
    [self.paneTwo.layer setOpacity: 1.0];
    [self.paneThree.layer setOpacity: 1.0];
    [self.paneFour.layer setOpacity: 1.0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    dispatch_async(self.sessionQueue, ^{
        [self.currentShots purge];
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
	dispatch_async(self.sessionQueue, ^{
		[self.captureSession stopRunning];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		[[NSNotificationCenter defaultCenter] removeObserver:self.runtimeErrorHandlingObserver];
		[self removeObserver:self forKeyPath:@"sessionRunningAndHasCameraPermission" context:SessionRunningCameraPermissionContext];
	});
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)hasRunningSessionAndCameraPermission {
	return self.captureSession.isRunning && self.hasCameraPermission;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
	if (context == SessionRunningCameraPermissionContext) {
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
    __block bool failed = NO;
    if (self.shotCount >= 4) {
        [self.timer invalidate];
        self.timer = nil;
        final = true;
    }
    [self runCaptureAnimation];
    switch (self.shotCount) {
        case 1:
            [self.paneOne.layer setOpacity: 0.2];
            break;
        case 2:
            [self.paneTwo.layer setOpacity: 0.2];
            break;
        case 3:
            [self.paneThree.layer setOpacity: 0.2];
            break;
        case 4:
            [self.paneFour.layer setOpacity: 0.2];
            break;
        default:
            break;
    }
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (failed) return;
        if (imageDataSampleBuffer) {
            CFRetain(imageDataSampleBuffer);
        } else {
            // The view may have swapped.
            failed = YES;
            return;
        }
        dispatch_async(self.sessionQueue, ^{
            if (imageDataSampleBuffer) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [self.currentShots addShot:[[UIImage alloc] initWithData:imageData]];
            }
            CFRelease(imageDataSampleBuffer);
            if (final) {
                [self processShotSet];
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
            [self.appDelegate.album addImage:finalGroupedImage];
        }
        [self.currentShots purge];
        self.shotCount = 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.paneOne.layer setOpacity: 1.0];
            [self.paneTwo.layer setOpacity: 1.0];
            [self.paneThree.layer setOpacity: 1.0];
            [self.paneFour.layer setOpacity: 1.0];
        });
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
