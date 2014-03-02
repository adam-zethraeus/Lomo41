#import <UIKit/UIKit.h>

@interface PhotoViewController : UIViewController

+ (PhotoViewController *)photoViewControllerForIndex: (NSInteger) index andImage:(UIImage *)image;

@property (nonatomic, readonly) NSInteger index;

@end
