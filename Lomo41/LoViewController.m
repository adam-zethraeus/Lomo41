//
//  LoViewController.m
//  Lomo41
//
//  Created by Adam Zethraeus on 12/10/13.
//  Copyright (c) 2013 Very Nice Co. All rights reserved.
//

#import "LoViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface LoViewController ()
@property (weak, nonatomic) IBOutlet UIView *shootView;
@property (weak, nonatomic) IBOutlet UIButton *shootButton;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic) BOOL hasCameraPermission;
- (IBAction)doShoot:(id)sender;
@end

@implementation LoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.session = [[AVCaptureSession alloc] init];
	[self checkCameraPermissions];
	self.sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
}

- (IBAction)doShoot:(id)sender {
    NSLog(@"This is where the action happens.");
    [self runCaptureAnimation];
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
