#import <UIKit/UIKit.h>

@class LoAlbumProxy;
@class LoPhotoProcessor;

@interface LoAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LoAlbumProxy *album;
@property (strong, nonatomic) LoPhotoProcessor *processor;

@end
