#import <UIKit/UIKit.h>

@class LoAlbumProxy;

@interface LoAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LoAlbumProxy *album;
@property (nonatomic) dispatch_queue_t serialQueue;

@end
