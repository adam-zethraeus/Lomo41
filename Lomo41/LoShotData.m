#import "LoShotData.h"

#include <libkern/OSAtomic.h>

@interface LoShotData()
@property (nonatomic, weak) id <LoShotDataDelegate> delegate;
@end

@implementation LoShotData {
    int32_t _count;
    UIImage *_leftmost;
    UIImage *_middle_left;
    UIImage *_middle_right;
    UIImage *_rightmost;
}

- (id)initWithDelegate:(id<LoShotDataDelegate>)delegate{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        _count = 0;
    }
    return self;
}

- (void)addImage:(UIImage *)image toLocation:(PaneLocation)location {
    
    int32_t newCount = OSAtomicIncrement32Barrier(&_count);
    if (newCount == 4) {
//        NSLog(@"######called four times");
//        NSAssert(_leftmost != nil, @"lacking image");
//        NSAssert(_middle_left != nil, @"lacking image");
//        NSAssert(_middle_right != nil, @"lacking image");
//        NSAssert(_rightmost != nil, @"lacking image");
        [self.delegate dataComplete:self];
    }
}

- (void)invalidate {
    _leftmost = nil;
    _middle_left = nil;
    _middle_right = nil;
    _rightmost = nil;
}

@end
