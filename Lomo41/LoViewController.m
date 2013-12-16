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

static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningCameraPermissionContext = &SessionRunningCameraPermissionContext;
static void * CaptureArraySize = &CaptureArraySize;

@interface LoViewController ()
@property (weak, nonatomic) IBOutlet UIView *shootView;
@property (weak, nonatomic) IBOutlet UIButton *shootButton;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) NSMutableArray *captures;
@property (nonatomic) id runtimeErrorHandlingObserver;
@property (nonatomic, readonly, getter = isSessionRunningAndHasCameraPermission) BOOL sessionRunningAndHasCameraPermission;
@property (nonatomic) BOOL hasCameraPermission;
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

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized {
	return [NSSet setWithObjects:@"session.running", @"hasCameraPermission", nil];
}

- (BOOL)isSessionRunningAndHasCameraPermission {
	return [[self session] isRunning] && [self hasCameraPermission];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.session = [[AVCaptureSession alloc] init];
    self.captures = [NSMutableArray arrayWithCapacity:4];
	[self checkCameraPermissions];
	self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
	dispatch_async(self.sessionQueue, ^{
		//[self setBackgroundRecordingID:UIBackgroundTaskInvalid];
		NSError *error = nil;
		AVCaptureDevice *videoDevice = [LoViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
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
        [self addObserver:self forKeyPath:@"captures" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CaptureArraySize];
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

- (void)viewDidDisappear:(BOOL)animated {
	dispatch_async(self.sessionQueue, ^{
		[self.session stopRunning];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
		[[NSNotificationCenter defaultCenter] removeObserver:self.runtimeErrorHandlingObserver];
		[self removeObserver:self forKeyPath:@"sessionRunningAndHasCameraPermission" context:SessionRunningCameraPermissionContext];
		[self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
		[self removeObserver:self forKeyPath:@"captures" context:CaptureArraySize];
	});
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (BOOL)hasRunningSessionAndCameraPermission {
	return self.session.isRunning && self.hasCameraPermission;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == CaptureArraySize) {
        if (self.captures.count >=4) {
            [self outputToLibrary];
        }
    }
}

- (IBAction)doShoot:(id)sender {
    [self runCaptureAnimation];
    [self shootOnce];
}

- (void)shootOnce {
	dispatch_async(self.sessionQueue, ^{
		[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            [self willChangeValueForKey:@"captures"];
            CFRetain(imageDataSampleBuffer);
            [self.captures addObject: (__bridge_transfer id)imageDataSampleBuffer];
            [self didChangeValueForKey:@"captures"];
		}];
	});
}

- (void)outputToLibrary {
    dispatch_async(self.sessionQueue, ^{
        for (id object in self.captures) {
            CMSampleBufferRef imageDataSampleBuffer = (__bridge_retained CMSampleBufferRef) object;
            if (imageDataSampleBuffer) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [[UIImage alloc] initWithData:imageData];
                [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
            }
            CFRelease(imageDataSampleBuffer);
        }
        [self.captures removeAllObjects];
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
