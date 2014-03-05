#import "PhotoViewController.h"
#import "ImageScrollView.h"

@interface PhotoViewController ()

@property (nonatomic, strong) UIImage *image;
@property (nonatomic) NSInteger index;
@end

@implementation PhotoViewController

+ (PhotoViewController *)photoViewControllerForIndex: (NSInteger) index andImage:(UIImage *)image {
    if (image == nil) {
        return nil;
    }
    return [[self alloc] initWithIndex:index andImage:image];
}

- (id)initWithIndex: (NSInteger)index andImage:(UIImage *)image {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.image = image;
        self.index = index;
    }
    return self;
}


- (void)loadView {
    ImageScrollView *scrollView = [[ImageScrollView alloc] init];
    [scrollView displayImage: self.image];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = scrollView;
}

@end
